//
//  TLGroup+CreateAvatar.m
//  TLChat
//
//  Created by 李伯坤 on 2017/9/19.
//  Copyright © 2017年 李伯坤. All rights reserved.
//

#import "TLGroup+CreateAvatar.h"
#import <UIImageView+WebCache.h>
#import "NSFileManager+TLChat.h"
#import "TLMacros.h"

@implementation TLGroup (CreateAvatar)

- (void)createGroupAvatarWithCompleteAction:(void (^)(NSString *groupID))completeAction
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSInteger usersCount = self.users.count > 9 ? 9 : self.users.count;
        CGFloat viewWidth = 200;
        CGFloat width = viewWidth / 3 * 0.85;
        CGFloat space3 = (viewWidth - width * 3) / 4;               // 三张图时的边距（图与图之间的边距）
        CGFloat space2 = (viewWidth - width * 2 + space3) / 2;      // 两张图时的边距
        CGFloat space1 = (viewWidth - width) / 2;                   // 一张图时的边距
        CGFloat y = usersCount > 6 ? space3 : (usersCount > 3 ? space2 : space1);
        CGFloat x = usersCount % 3 == 0 ? space3 : (usersCount % 3 == 2 ? space2 : space1);
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, viewWidth)];
        [view setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:0.6]];
        __block NSInteger count = 0;        // 下载完成图片计数器
        for (NSInteger i = usersCount - 1; i >= 0; i--) {
            TLUser *user = [self.users objectAtIndex:i];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, width, width)];
            [view addSubview:imageView];
            [imageView sd_setImageWithURL:TLURL(user.avatarURL) placeholderImage:[UIImage imageNamed:DEFAULT_AVATAR_PATH] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                count ++;
                if (count == usersCount) {     // 图片全部下载完成
                    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 2.0);
                    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
                    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    CGImageRef imageRef = image.CGImage;
                    CGImageRef imageRefRect =CGImageCreateWithImageInRect(imageRef, CGRectMake(0, 0, view.width * 2, view.height * 2));
                    UIImage *ansImage = [[UIImage alloc] initWithCGImage:imageRefRect];
                    NSData *imageViewData = UIImagePNGRepresentation(ansImage);
                    NSString *savedImagePath = [NSFileManager pathUserAvatar:self.groupAvatarPath];
                    [imageViewData writeToFile:savedImagePath atomically:YES];
                    CGImageRelease(imageRefRect);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completeAction) {
                            completeAction(self.groupID);
                        }
                    });
                }
            }];
            if (i % 3 == 0) {   // 换行
                y += (width + space3);
                x = space3;
            }
            else if (i == 2 && usersCount == 3) {  // 换行，只有三个时
                y += (width + space3);
                x = space2;
            }
            else {
                x += (width + space3);
            }
        }
    });
}


@end

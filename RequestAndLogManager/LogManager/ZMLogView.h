//
//  ZMLogView.h
//  Demo
//
//  Created by chenzm on 2018/9/10.
//  Copyright © 2018年 chenzm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZMLogView : UIView

///初始化
+(instancetype)initLogView;

///打印日志信息
-(void)logInfo:(NSString *)str;
@end

//
//  ZMWKWebViewVC.h
//  DDTL
//
//  Created by lx on 2017/10/26.
//  Copyright © 2017年 chenzm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@interface ZMWKWebViewVC : UIViewController
@property (nonatomic, strong) WKWebView *wkWebView;
-(void)zm_WKLoadUrl:(NSString *)url;

@end

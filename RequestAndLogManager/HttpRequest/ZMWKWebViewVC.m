//
//  ZMWKWebViewVC.m
//  DDTL
//
//  Created by lx on 2017/10/26.
//  Copyright © 2017年 chenzm. All rights reserved.
//

#import "ZMWKWebViewVC.h"

@interface ZMWKWebViewVC ()<WKUIDelegate,WKNavigationDelegate>


@property (nonatomic, strong) UIProgressView *progressView;


///错误标题
@property(nonatomic,strong)UILabel *titleLbl;

///退出按钮
@property(nonatomic,strong)UIButton *dismissBtn;


@end

@implementation ZMWKWebViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    //进度条初始化
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 20, [[UIScreen mainScreen] bounds].size.width, 2)];
    _progressView.backgroundColor = [UIColor blueColor];
    //设置进度条的高度，下面这句代码表示进度条的宽度变为原来的1倍，高度变为原来的1.5倍.
    _progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
    [self.view addSubview:_progressView];
    [self dismissBtn];
}

-(void)zm_WKLoadUrl:(NSString *)url{
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        _progressView.progress = self.wkWebView.estimatedProgress;
        if (_progressView.progress == 1) {
            /*
             *添加一个简单的动画，将progressView的Height变为1.4倍，在开始加载网页的代理中会恢复为1.5倍
             *动画时长0.25s，延时0.3s后开始动画
             *动画结束后将progressView隐藏
             */
            [UIView animateWithDuration:0.25f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                _progressView.transform = CGAffineTransformMakeScale(1.0f, 1.4f);
            } completion:^(BOOL finished) {
                _progressView.hidden = YES;
                
            }];
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


//开始加载
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    //开始加载网页时展示出progressView
    _progressView.hidden = NO;
    //开始加载网页的时候将progressView的Height恢复为1.5倍
    _progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
    //防止progressView被网页挡住
    [self.view bringSubviewToFront:_progressView];
}

//加载完成
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    //加载完成后隐藏progressView
    _progressView.hidden = YES;
}

//加载失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    //加载失败同样需要隐藏progressView
    //_progressView.hidden = YES;
}





static NSString *static_url = @"";

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSLog(@"%@",webView.URL.absoluteString);
    
    decisionHandler(WKNavigationActionPolicyAllow);
}



- (void)dealloc {
    [self.wkWebView removeObserver:self forKeyPath:@"estimatedProgress"];
}



//设备宽高
#define kWebIphone_W [UIScreen mainScreen].bounds.size.width
#define kWebIphone_H [UIScreen mainScreen].bounds.size.height

#pragma mark - lazyload

- (WKWebView *)wkWebView{
    if (_wkWebView == nil){
        //创建网页配置对象
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        // 创建设置对象
        WKPreferences *preference = [[WKPreferences alloc]init];
        // 设置字体大小(最小的字体大小)
        preference.minimumFontSize = 40;
        // 设置偏好设置对象
        config.preferences = preference;
        // 创建WKWebView
        _wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0,CGRectGetMaxY(self.titleLbl.frame), kWebIphone_W, kWebIphone_H - CGRectGetMaxY(self.titleLbl.frame) - 10) configuration:config];
        _wkWebView.scrollView.bounces = NO;
        _wkWebView.UIDelegate = self;
        _wkWebView.navigationDelegate = self;
        [self.view addSubview:_wkWebView];
        [self.wkWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    }
    return  _wkWebView;
}


-(UILabel *)titleLbl{
    if (!_titleLbl) {
        _titleLbl = [UILabel new];
        _titleLbl.frame = CGRectMake(0, 20, kWebIphone_W, 30);
        _titleLbl.textColor = [UIColor purpleColor];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.text = @"错误信息";
        if (@available(iOS 8.2, *)) {
            _titleLbl.font = [UIFont systemFontOfSize:18 weight:1.0];
        } else {
            _titleLbl.font = [UIFont systemFontOfSize:18];
        }
        [self.view addSubview:_titleLbl];
        
        UILabel *lineLbl = [UILabel new];
        lineLbl.frame = CGRectMake(_titleLbl.bounds.origin.x,CGRectGetMaxY(_titleLbl.bounds) - 0.5, _titleLbl.bounds.size.width, 0.5);
        lineLbl.backgroundColor = [UIColor lightGrayColor];
        [_titleLbl addSubview:lineLbl];
        
    }
    return _titleLbl;
}

-(UIButton *)dismissBtn{
    if (!_dismissBtn) {
        _dismissBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _dismissBtn.frame = CGRectMake(10, CGRectGetMinY(self.titleLbl.frame), 50, 20);
        
        _dismissBtn.layer.masksToBounds = YES;
        _dismissBtn.layer.cornerRadius = 5;
        _dismissBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_dismissBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [_dismissBtn setTitle:@"返回" forState:UIControlStateNormal];
        [_dismissBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];

        [self.view addSubview:_dismissBtn];
    }
    return _dismissBtn;
}


-(void)btnAction:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

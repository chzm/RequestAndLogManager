//
//  ViewController.m
//  RequestAndLogManager
//
//  Created by chenzm on 2018/9/11.
//  Copyright © 2018年 chenzm. All rights reserved.
//

#import "ViewController.h"
#import "LogManager.h"
#import "ZMLogView.h"
#import "ZMEngine.h"


@interface ViewController ()

///显示日志
@property(nonatomic,strong)ZMLogView *logView;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self testForLocalLog];
    
    //    [self testForH5ErrorShow];
    //
    //    [self testForRequest];
}

///写入数据到本地文件并显示
-(void)testForLocalLog{
    //写入数据到本地文件
    LLog(@"错误信息",@"五哦粗");
    //获取日志信息并显示
    NSString *str = [[LogManager sharedInstance] readFile:@"2018-09-11"];
    NSLog(@"%@",str);
    //渲染
    [self.logView logInfo:str];
}

//请求接口返回错误H5显示   [不存在的接口]
-(void)testForH5ErrorShow{
    NSString *path = [[LogManager sharedInstance] getLogPathWithDate:@"2018-09-11"];
    [kZMEngine updateFileWithfileName:@"2018-09-11" filePath:path response:^(id response) {
        
    }];
}

///接口请求
-(void)testForRequest{
    [kZMEngine getGWDocumentWithResponse:^(id response) {
        if ([kZMEngine getResultCode:response] == 1) {
            NSLog(@"%@",[kZMEngine getResultData:response]);
        }else{
            NSLog(@"%@",[kZMEngine getResultMsg:response]);
        }
    }];
}



#pragma mark - lazyload

-(ZMLogView *)logView{
    if (!_logView) {
        _logView = [ZMLogView initLogView];
        [self.view addSubview:_logView];
    }
    return _logView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

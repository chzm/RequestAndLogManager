/**
 MEMBERID:19644
 X-MUYAN-MECHINE:1
 X-MUYAN-SIGN:151c2875d04c2ebb890b8709d7722af8
 X-MUYAN-VERSION:43
 */

//
//  ZMBaseEngine.m
//  GuaWaProject
//
//  Created by chenzm on 2018/1/18.
//  Copyright © 2018年 木炎. All rights reserved.
//

#import "ZMBaseEngine.h"
#import <AFNetworking.h>
#import "ZMWKWebViewVC.h"
@implementation ZMBaseEngine

+(void)setHttpHeaderWithManager:(AFHTTPSessionManager *)manager{
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
#pragma mark --- 请求头的设置自Header
    //app应用相关信息的获取
    NSDictionary *dicInfo = [[NSBundle mainBundle] infoDictionary];
    //App版本
    NSString *strAppVersion = [dicInfo objectForKey:@"CFBundleShortVersionString"];
    //系统名称
    NSString *strSysName =[[UIDevice currentDevice]systemName];
    //系统版本
    NSString *strSysVersion = [[UIDevice currentDevice]systemVersion];
    //设备模式
    NSString *strModel=[[UIDevice currentDevice]model];
    //设备本地模式
    NSString *strLocModel =[[UIDevice currentDevice]localizedModel];
    
    //设备的平台
    [manager.requestSerializer setValue:strSysName forHTTPHeaderField:@"platform"];
    //设备的型号(模式)
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"model:%@\t locModel:%@",strModel,strLocModel] forHTTPHeaderField:@"type"];
    //系统版本
    [manager.requestSerializer setValue:strSysVersion forHTTPHeaderField:@"sysVersion"];
    //App的版本
    [manager.requestSerializer setValue:strAppVersion forHTTPHeaderField:@"appVersion"];

    //         ---------  other test   -----------
    [manager.requestSerializer setValue:@"19644" forHTTPHeaderField:@"MEMBERID"];
    [manager.requestSerializer setValue:@"1" forHTTPHeaderField:@"X-MUYAN-MECHINE"];
    [manager.requestSerializer setValue:@"151c2875d04c2ebb890b8709d7722af8" forHTTPHeaderField:@"X-MUYAN-SIGN"];
    [manager.requestSerializer setValue:@"43" forHTTPHeaderField:@"X-MUYAN-VERSION"];

}

/**
 *  get请求
 */
- (void)base_GetWithUrl:(NSString *)url parameters:(NSDictionary *)params success:(void(^)(id success))success failure:(void(^)(id failure))failure{
    
    url = [NSString stringWithFormat:@"%@%@",kURLMain,url];
    
    // 创建请求对象
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];  //设置请求数据
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];//设置返回数据
    //请求头设置
    [ZMBaseEngine setHttpHeaderWithManager:manager];
    // 设置超时时长
    manager.requestSerializer.timeoutInterval = 10.0f;
    //NSString *strUrl = [NSString stringWithFormat:@"%@%@",kURLMain,url];
    
    [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //json解析
        NSDictionary *dic = [self jsonToDic:responseObject];
        success(dic);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self  handlingError:error failure:failure];
    }];
}


- (void)base_PostWithUrl:(NSString *)url parameters:(id)params success:(void(^)(id success))success failure:(void(^)(id failure))failure{
    
    url = [NSString stringWithFormat:@"%@%@",kURLMain,url];
    
    // 创建请求对象
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];  //设置请求数据
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];//设置返回数据
    //请求头设置
    [ZMBaseEngine setHttpHeaderWithManager:manager];
    // 设置超时时长
    manager.requestSerializer.timeoutInterval = 10.0f;
    [manager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
    
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //json解析
        NSDictionary *dic = [self jsonToDic:responseObject];
        success(dic);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handlingError:error failure:failure];
    }];
    
}

- (void)base_UpLoadImage:(NSData *)imgData fileName:(NSString *)fileName imgType:(NSString *)type PostWithURL:(NSString *)url parameters:(id)params progress:(void(^)(id progress))progress success:(void(^)(id success))success failure:(void(^)(id failure))failure{
    
    url = [NSString stringWithFormat:@"%@%@",kURLMain,url];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    // 设置超时时长
    manager.requestSerializer.timeoutInterval = 30.0f;
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    manager.responseSerializer =[AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html",@"image/png",@"image/jpeg",nil];
    [manager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //上传数据，域名为fileName
        [formData appendPartWithFileData:imgData name:@"imageFile"fileName:fileName mimeType:[NSString stringWithFormat:@"image/%@",type]];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progress(uploadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //json解析
        NSDictionary *dic = [self jsonToDic:responseObject];
        success(dic);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handlingError:error failure:failure];
    }];
}


/**
 上传文件
 
 @param url 链接
 @param params 参数
 @param fileName 文件名
 @param upName 上传文件名
 @param filePath 路径
 @param progress 进度代码块
 @param success 成功代码块
 @param failure 失败代码块
 */
- (void)base_UpdateFileWithUrl:(NSString*)url parameters:(NSMutableDictionary*)params fileName:(NSString*)fileName upName:(NSString *)upName filePath:(NSString *)filePath progress:(void(^)(id progress))progress success:(void(^)(id success))success failure:(void(^)(id failure))failure{
    
    url = [NSString stringWithFormat:@"%@%@",kURLMain,url];
    if (!upName) {
        upName = fileName;
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //请求头设置
    [ZMBaseEngine setHttpHeaderWithManager:manager];
    [manager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        /*
         第一个参数:文件的URL路径
         第二个参数:参数名称 file
         第三个参数:在服务器上的名称
         第四个参数:文件的类型
         */
        if (filePath&&fileName) {
            NSData*fileData = [NSData dataWithContentsOfFile:filePath];
            //        [formData appendPartWithFileURL:[NSURL fileURLWithPath:@""] name:fileName error:nil];
            [formData appendPartWithFileData:fileData name:upName fileName:fileName mimeType:@"application/zip"];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progress(uploadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //json解析
        NSDictionary *dic = [self jsonToDic:responseObject];
        success(dic);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handlingError:error failure:failure];
    }];
}

#pragma mark - other methods
///接口请求错误处理
-(void)handlingError:(NSError * _Nonnull)error failure:(void(^)(id failure))failure{
    // 取得错误信息
    NSData *data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
#if DEBUG
    NSLog(@"%@",error.userInfo);
#else
#endif
    NSString *strError = @"网络无连接:请检查!";
    NSString *errDesStr = error.userInfo[@"NSLocalizedDescription"];
    NSArray *arr = [errDesStr componentsSeparatedByString:@" "];
    NSString *lastStr = arr.lastObject;
    NSString *errCodeStr;
    if ([self engineValidateStr:lastStr belongToStr:@"()1234567890."]) {
        errCodeStr = [lastStr substringWithRange:NSMakeRange(1, lastStr.length - 2)]?:@"";
    }else{
        errCodeStr = lastStr;
    }
    
    //打印错误信息
    NSString *dataStr = nil;
    if (data.length > 0) {
        dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    }else{
        dataStr = @"错误日志为空";
    }
    NSString *errorResponse = error.userInfo[@"com.alamofire.serialization.response.error.response"];
    NSString *errorUrl = error.userInfo[@"NSErrorFailingURLKey"];
    NSString *errorStr = [NSString stringWithFormat:@"--------- 开始 --------<br><br>NSErrorFailingURLKey：<br>%@<br><br>NSLocalizedDescription：<br>%@<br><br>com.alamofire.serialization.response.error.response：<br>%@<br><br>com.alamofire.serialization.response.error.data:<br>%@<br><br>--------- 结束 --------",errorUrl,errDesStr,errorResponse,dataStr];
        data = [errorStr dataUsingEncoding:NSUTF8StringEncoding];
    [self openHtmlError:data target:[self engineGetCurrentVC]];
    
    NSDictionary *dic = @{Req_resultCode:errCodeStr,Req_errorMessage:strError,Req_errorData:data?:@""};
    // 回调失败代码块
    failure(dic);
}


- (NSDictionary *)jsonToDic:(NSData *)jsonData{
    NSError *error = nil;
    NSData *data = jsonData;
    NSDictionary *dicData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        return @{};
    } else {
        return dicData;
    }
}

/**
 判断某个字符是否属于设置字符串
 @param str 字符
 @param toStr 字符串
 */
- (BOOL)engineValidateStr:(NSString*)str belongToStr:(NSString *)toStr{
    BOOL res = YES;
    NSCharacterSet* tmpSet = [NSCharacterSet characterSetWithCharactersInString:toStr];
    int i = 0;
    while (i < str.length) {
        NSString * string = [str substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [string rangeOfCharacterFromSet:tmpSet];
        if (range.length == 0) {
            res = NO;
            break;
        }
        i++;
    }
    return res;
}

///打印错误信息
-(void)openHtmlError:(NSData *)data target:(UIViewController *)target{
    //#ifdef Debug
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (str&&str.length>0) {
        ZMWKWebViewVC *vc = [ZMWKWebViewVC new];
        [vc.wkWebView loadHTMLString:str baseURL:[NSURL URLWithString:@"www://baidu.com"]];
        [target presentViewController:vc animated:YES completion:nil];
    }else{
        
    }
    //#else
    //#endif
}

///获取当前屏幕显示的viewcontroller
- (UIViewController *)engineGetCurrentVC{
    // 定义一个变量存放当前屏幕显示的viewcontroller
    UIViewController *result = nil;
    
    // 得到当前应用程序的关键窗口（正在活跃的窗口）
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    
    // windowLevel是在 Z轴 方向上的窗口位置，默认值为UIWindowLevelNormal
    if (window.windowLevel != UIWindowLevelNormal)
    {
        // 获取应用程序所有的窗口
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            // 找到程序的默认窗口（正在显示的窗口）
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                // 将关键窗口赋值为默认窗口
                window = tmpWin;
                break;
            }
        }
    }
    // 获取窗口的当前显示视图
    UIView *frontView = [[window subviews] objectAtIndex:0];
    
    // 获取视图的下一个响应者，UIView视图调用这个方法的返回值为UIViewController或它的父视图
    id nextResponder = [frontView nextResponder];
    
    // 判断显示视图的下一个响应者是否为一个UIViewController的类对象
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        result = nextResponder;
    } else {
        result = window.rootViewController;
    }
    return result;
}

@end

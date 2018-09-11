//
//  ZMBaseEngine.h
//  GuaWaProject
//
//  Created by chenzm on 2018/1/18.
//  Copyright © 2018年 木炎. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kURLMain @"http://app.guawaapp.com/guawa/api/"

// 错误日志输出地址 ，根据自己电脑配置
#define kErrorPath  @"/Users/lx/Desktop/DDError_ios/Error.html"


/**请求接口的成功*/
static NSString * Req_resultCode = @"success";
/**请求接口的错误信息*/
static NSString * Req_errorMessage = @"message";
/**请求接口成功的字典*/
static NSString * Req_data = @"data";
/**请求接口失败错误日志*/
static NSString * Req_errorData = @"errorData";

typedef void(^ProgressBlock)(id progress);
typedef void(^SuccessBlock)(id success);
typedef void(^FailureBlock)(id failure);

typedef void(^ResponseBlock)(id response);
typedef void(^IsSuccessBlock)(BOOL isSuccess);

@interface ZMBaseEngine : NSObject


/**
 get请求
 @param url 链接
 @param params 参数
 @param success 成功代码块
 @param failure 失败代码块
 */
- (void)base_GetWithUrl:(NSString *)url parameters:(NSDictionary *)params success:(void(^)(id success))success failure:(void(^)(id failure))failure;

/**
 post请求
 @param url 链接
 @param params 参数
 @param success 成功代码块
 @param failure 失败代码块
 */
- (void)base_PostWithUrl:(NSString *)url parameters:(id)params success:(void(^)(id success))success failure:(void(^)(id failure))failure;



/**
 图片上传

 @param imgData 图片data
 @param fileName 图片名称
 @param type 类型
 @param url 链接
 @param params 参数
 @param progress 进度代码块
 @param success 成功代码块
 @param failure 失败代码块
 */
- (void)base_UpLoadImage:(NSData *)imgData fileName:(NSString *)fileName imgType:(NSString *)type PostWithURL:(NSString *)url parameters:(id)params progress:(void(^)(id progress))progress success:(void(^)(id success))success failure:(void(^)(id failure))failure;


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
- (void)base_UpdateFileWithUrl:(NSString*)url parameters:(NSMutableDictionary*)params fileName:(NSString*)fileName upName:(NSString *)upName filePath:(NSString *)filePath progress:(void(^)(id progress))progress success:(void(^)(id success))success failure:(void(^)(id failure))failure;

@end

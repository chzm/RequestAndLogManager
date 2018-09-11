//
//  LogManager.h
//  Demo
//
//  Created by chenzm on 2018/9/7.
//  Copyright © 2018年 chenzm. All rights reserved.
//

#import <Foundation/Foundation.h>

//// 记录本地日志
#define LLog(module,...) {\
[[LogManager sharedInstance] logInfo:module logStr:__VA_ARGS__,nil];\
}

// 日志保留最大天数
static const int LogMaxSaveDay = 7;
// 日志文件保存目录
static const NSString* LogFilePath = @"/Documents/ZMLog/";
// 日志压缩包文件名
static NSString* ZipFileName = @"ZMLog.zip";

@interface LogManager : NSObject

/**
 *  获取单例实例
 *
 *  @return 单例实例
 */
+ (instancetype) sharedInstance;

#pragma mark - Method

/**
 *  写入日志
 *
 *  @param module 模块名称
 *  @param logStr 日志信息,动态参数
 */
- (void)logInfo:(NSString*)module logStr:(NSString*)logStr, ...;

///清空过期的日志
- (void)clearExpiredLog;

/**
 *
 */
///检测日志是否需要上传
- (void)checkLogNeedUpload;


/**
 读取文件信息
 @param filePath 文件路径
 */
- (NSString *)readFile:(NSString *)filePath;

/**
 获取对应日期做为文件名
 @param dateStr 自定义日期【格式：yyyy-MM-dd】
 @return 返回文件路径
 */
-(NSString *)getLogPathWithDate:(NSString *)dateStr;

@end

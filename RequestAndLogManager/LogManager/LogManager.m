//
//  LogManager.m
//  LogFileDemo
//
//  Created by xgao on 17/3/9.
//  Copyright © 2017年 chenzm. All rights reserved.
//

#import "LogManager.h"
#import <ZipArchive.h>
#import "ZMEngine.h"

@interface LogManager()

// 日期格式化
@property (nonatomic,retain) NSDateFormatter* dateFormatter;
// 时间格式化
@property (nonatomic,retain) NSDateFormatter* timeFormatter;

// 日志的目录路径
@property (nonatomic,copy) NSString* basePath;

@end

@implementation LogManager

/**
 *  获取单例实例
 *
 *  @return 单例实例
 */
+ (instancetype) sharedInstance{
    
    static LogManager* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[LogManager alloc]init];
        }
    });
    
    return instance;
}

// 获取当前时间
+ (NSDate*)getCurrDate{
    
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    NSDate *localeDate = [date dateByAddingTimeInterval: interval];
    
    return localeDate;
}

#pragma mark - Init

- (instancetype)init{
    
    self = [super init];
    if (self) {
        
        // 创建日期格式化
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        // 设置时区，解决8小时
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        self.dateFormatter = dateFormatter;
        
        // 创建时间格式化
        NSDateFormatter* timeFormatter = [[NSDateFormatter alloc]init];
        [timeFormatter setDateFormat:@"HH:mm:ss"];
        [timeFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        self.timeFormatter = timeFormatter;
        
        // 日志的目录路径
        self.basePath = [NSString stringWithFormat:@"%@%@",NSHomeDirectory(),LogFilePath];
    }
    return self;
}

#pragma mark - Method

/**
 *  写入日志
 *
 *  @param module 模块名称
 *  @param logStr 日志信息,动态参数
 */
- (void)logInfo:(NSString*)module logStr:(NSString*)logStr, ...{
    
#pragma mark - 获取参数
    
    NSMutableString* parmaStr = [NSMutableString string];
    // 声明一个参数指针
    va_list paramList;
    // 获取参数地址，将paramList指向logStr
    va_start(paramList, logStr);
    id arg = logStr;
    
    @try {
        // 遍历参数列表
        while (arg) {
            [parmaStr appendString:arg];
            // 指向下一个参数，后面是参数类似
            arg = va_arg(paramList, NSString*);
        }
        
    } @catch (NSException *exception) {
        
        [parmaStr appendString:@"【记录日志异常】"];
    } @finally {
        
        // 将参数列表指针置空
        va_end(paramList);
    }
    
#pragma mark - 写入日志
    
    // 异步执行
    dispatch_async(dispatch_queue_create("writeLog", nil), ^{
        
        NSString* filePath = [self getLogPathWithDate:nil];
        // [时间]-[模块]-日志内容
        NSString* timeStr = [self.timeFormatter stringFromDate:[LogManager getCurrDate]];
        NSString* writeStr = [NSString stringWithFormat:@"[%@]-[%@]-%@\n",timeStr,module,parmaStr];
        
        // 写入数据
        [self writeFile:filePath stringData:writeStr];
        
        NSLog(@"写入日志:%@",filePath);
    });
}

/**
 读取文件信息
 @param fileName 文件路径
 */
- (NSString *)readFile:(NSString *)fileName{
    NSString *filePath = [self getLogPathWithDate:fileName];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSString *logStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    return logStr;
}

/**
 获取对应日期做为文件名
 @param dateStr 自定义日期【格式：yyyy-MM-dd】
 @return 返回文件路径
 */
-(NSString *)getLogPathWithDate:(NSString *)dateStr{
    NSString* fileName = nil;
    if(dateStr||dateStr > 0){
        fileName = dateStr;
    }else{
        fileName = [self.dateFormatter stringFromDate:[NSDate date]];
    }
    NSString* filePath = [NSString stringWithFormat:@"%@%@",self.basePath,fileName];
    return filePath;
}

///清空过期的日志
- (void)clearExpiredLog{
    
    // 获取日志目录下的所有文件
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.basePath error:nil];
    for (NSString* file in files) {
        
        NSDate* date = [self.dateFormatter dateFromString:file];
        if (date) {
            NSTimeInterval oldTime = [date timeIntervalSince1970];
            NSTimeInterval currTime = [[LogManager getCurrDate] timeIntervalSince1970];
            
            NSTimeInterval second = currTime - oldTime;
            int day = (int)second / (24 * 3600);
            if (day >= LogMaxSaveDay) {
                // 删除该文件
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",self.basePath,file] error:nil];
                NSLog(@"[%@]日志文件已被删除！",file);
            }
        }
    }
    
    
}

///检测日志是否需要上传
- (void)checkLogNeedUpload{
    // 发起请求，从服务器上获取当前应用是否需要上传日志
    [kZMEngine checkUploadLogWithResponse:^(id response) {
        if ([kZMEngine getResultCode:response] == 1) {
            NSDictionary *dic = [kZMEngine getResultData:response];
            if (dic&&[dic isKindOfClass:[NSDictionary class]]&&dic.allKeys>0) {
                [self uploadLog:dic];
            }else{
                NSLog(@"请求失败，data没有数据！");
            }
        }else{
            NSLog(@"检测日志失败！");
        }
    }];
}

#pragma mark - Private

/**
 *  处理是否需要上传日志
 *
 *  @param resultDic 包含获取日期的字典
 */
- (void)uploadLog:(NSDictionary*)resultDic{
    
    if (!resultDic) {
        return;
    }
    
    // 0不拉取，1拉取N天，2拉取全部
    int type = [resultDic[@"type"] intValue];
    // 压缩文件是否创建成功
    BOOL created = NO;
    if (type == 1) {
        // 拉取指定日期的
        
        // "dates": ["2017-03-01", "2017-03-11"]
        NSArray* dates = resultDic[@"dates"];
        
        // 压缩日志
        created = [self compressLog:dates];
    }else if(type == 2){
        // 拉取全部
        
        // 压缩日志
        created = [self compressLog:nil];
    }
    
    if (created) {
        // 上传
        [self uploadLogToServer:^(BOOL boolValue) {
            if (boolValue) {
                NSLog(@"日志上传成功---->>",nil);
                // 删除日志压缩文件
                [self deleteZipFile];
            }else{
                NSLog(@"日志上传失败！！",nil);
            }
        }];
    }
}

/**
 *  压缩日志
 *
 *  @param dates 日期时间段，空代表全部
 *
 *  @return 执行结果
 */
- (BOOL)compressLog:(NSArray*)dates{
    
    // 先清理几天前的日志
    [self clearExpiredLog];
    
    // 获取日志目录下的所有文件
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.basePath error:nil];
    // 压缩包文件路径
    NSString * zipFile = [self.basePath stringByAppendingString:ZipFileName] ;
    
    ZipArchive* zip = [[ZipArchive alloc] init];
    // 创建一个zip包
    BOOL created = [zip CreateZipFile2:zipFile];
    if (!created) {
        // 关闭文件
        [zip CloseZipFile2];
        return NO;
    }
    
    if (dates) {
        // 拉取指定日期的
        for (NSString* fileName in files) {
            if ([dates containsObject:fileName]) {
                // 将要被压缩的文件
                NSString *file = [self.basePath stringByAppendingString:fileName];
                // 判断文件是否存在
                if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
                    // 将日志添加到zip包中
                    [zip addFileToZip:file newname:fileName];
                }
            }
        }
    }else{
        // 全部
        for (NSString* fileName in files) {
            // 将要被压缩的文件
            NSString *file = [self.basePath stringByAppendingString:fileName];
            // 判断文件是否存在
            if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
                // 将日志添加到zip包中
                [zip addFileToZip:file newname:fileName];
            }
        }
    }
    
    // 关闭文件
    [zip CloseZipFile2];
    return YES;
}

/**
 *  上传日志到服务器
 *
 *  @param returnBlock 成功回调
 */
- (void)uploadLogToServer:(void(^)(BOOL boolValue))returnBlock{
    NSString *filePath = [self getLogPathWithDate:@""];
    [kZMEngine updateFileWithfileName:ZipFileName filePath:filePath response:^(id response) {
        if ([kZMEngine getResultCode:response] == 1) {
            returnBlock(YES);
        }else{
            returnBlock(NO);
        }
    }];
}

/**
 *  删除日志压缩文件
 */
- (void)deleteZipFile{
    
    NSString* zipFilePath = [self.basePath stringByAppendingString:ZipFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:zipFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
    }
}

/**
 *  写入字符串到指定文件，默认追加内容
 *
 *  @param filePath   文件路径
 *  @param stringData 待写入的字符串
 */
- (void)writeFile:(NSString*)filePath stringData:(NSString*)stringData{
    
    // 待写入的数据
    NSData* writeData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    // NSFileManager 用于处理文件
    BOOL createPathOk = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[filePath stringByDeletingLastPathComponent] isDirectory:&createPathOk]) {
        // 目录不存先创建
        [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        // 文件不存在，直接创建文件并写入
        [writeData writeToFile:filePath atomically:NO];
    }else{
        
        // NSFileHandle 用于处理文件内容
        // 读取文件到上下文，并且是更新模式
        NSFileHandle* fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        
        // 跳到文件末尾
        [fileHandler seekToEndOfFile];
        
        // 追加数据
        [fileHandler writeData:writeData];
        
        // 关闭文件
        [fileHandler closeFile];
    }
}


@end

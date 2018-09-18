
 @[TOC](目录)

# 日志记录本地文件并压缩上传

## 简介
本篇文章主要目的是为了将用户操作习惯记录到本地文件，然后定期或者根据实际需要打包压缩上传到服务器，用以处理用户在闪退的时候，或需要详细了解具体某个用户在这一段时间的操作习惯。由于要压缩上传本地日志，顺道集成了AFNetWorking了post和get的接口请求，以及请求是接口失败后，错误信息显示，这个在开发的时候特别方便，后台可以在根据这些错误日志查询对应的问题。

点击下载集成的Demo：
github：【[RequestAndLogManager](https://github.com/chzm/RequestAndLogManager) 】
gitee:【[RequestAndLogManager](https://gitee.com/chenzm_186/RequestAndLogManager)】

## 一、日志记录集成[LogManager]
在文件中，对每个方法和属性都做了注释；有写入日志方法，也有打印写入日志的方法，以便于检查日志是否成功
```oc
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

```

```oc
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

```

打印记录日志的页面：

```oc

#import <UIKit/UIKit.h>

@interface ZMLogView : UIView

///初始化
+(instancetype)initLogView;

///打印日志信息
-(void)logInfo:(NSString *)str;
@end
```

```oc
#import "ZMLogView.h"

//大小尺寸
#define kLogViewFrame CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)

@interface ZMLogView()

///标签
@property(nonatomic,strong)UITextView *textView;
///标题
@property(nonatomic,strong)UILabel *titleLbl;

@end


@implementation ZMLogView{
    CGRect _frame;
}

#pragma mark - 赋值
-(void)logInfo:(NSString *)str{
    if (str) {
        self.textView.text = str;
    }else{
        self.textView.text = @"暂无日志信息";
    }
}

#pragma mark -Methods


#pragma mark - Intial
+(instancetype)initLogView{
    return [[self alloc]initWithFrame:CGRectZero];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder: aDecoder]) {
        self.frame = kLogViewFrame;
        [self setUpBaseData];
        [self setUpUI];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    frame = kLogViewFrame;
    if (self = [super initWithFrame:frame]) {
        [self setUpBaseData];
        [self setUpUI];
    }
    return self;
}

///基本数据配置
-(void)setUpBaseData{
    
}

///控件添加
-(void)setUpUI{
    [self textView];
}

#pragma mark - 布局
-(void)layoutSubviews{
    [super layoutSubviews];
    
}

#pragma mark - lazyload
-(UILabel *)titleLbl{
    if (!_titleLbl) {
        _titleLbl = [UILabel new];
        _titleLbl.frame = CGRectMake(10, 20, [UIScreen mainScreen].bounds.size.width - 20, 20);
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.textColor = [UIColor purpleColor];
        if (@available(iOS 8.2, *)) {
            _titleLbl.font = [UIFont systemFontOfSize:18 weight:1];
        } else {
            _titleLbl.font = [UIFont systemFontOfSize:18];
        }
        _titleLbl.text = @"打印日志";
        [self addSubview:_titleLbl];
    }
    return _titleLbl;
}

-(UITextView *)textView{
    if (!_textView) {
        _textView = [UITextView new];
        _textView.font = [UIFont systemFontOfSize:14];
        _textView.textColor = [UIColor darkGrayColor];
        CGRect frame = CGRectMake(10, CGRectGetMaxY(self.titleLbl.frame),[UIScreen mainScreen].bounds.size.width - 20, [UIScreen mainScreen].bounds.size.height - 50);
        _textView.frame = frame;
        _textView.showsHorizontalScrollIndicator = NO;
        [_textView setEditable:NO];
        [self addSubview:_textView];
    }
    return _textView;
}


-(void)dealloc{
    
}
@end

```

打印日志应用实例,在还没引入上传请求接口时，【LogManager.m】文件中可以先将请求接口其注释避免报错：
```oc
#import "LogManager.h"
#import "ZMLogView.h"

///显示日志
@property(nonatomic,strong)ZMLogView *logView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self testForLocalLog];
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

#pragma mark - lazyload

-(ZMLogView *)logView{
    if (!_logView) {
        _logView = [ZMLogView initLogView];
        [self.view addSubview:_logView];
    }
    return _logView;
}

```

## 二、使用【AFNetworking】集成接口

### 1、get请求
```oc
/**
 get请求
 @param url 链接
 @param params 参数
 @param success 成功代码块
 @param failure 失败代码块
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
```

### 2、Post请求
```oc
/**
 post请求
 @param url 链接
 @param params 参数
 @param success 成功代码块
 @param failure 失败代码块
 */
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
```

### 3、图片上传

```oc
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
```

### 4、文件上传
```oc
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
```

### 5、请求头/错误处理等：
```oc
///接口请求头
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
    [manager.requestSerializer setValue:@"xx" forHTTPHeaderField:@"X-MUYAN-SIGN"];
    [manager.requestSerializer setValue:@"43" forHTTPHeaderField:@"X-MUYAN-VERSION"];

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

```

## 三、错误h5集成：
在请求接口报错时，会直接调用该类方法
```oc
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@interface ZMWKWebViewVC : UIViewController
@property (nonatomic, strong) WKWebView *wkWebView;
-(void)zm_WKLoadUrl:(NSString *)url;

@end

```

```oc
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
```

##### 参考链接

1、[本地日志记录](https://www.cnblogs.com/xgao/p/6553334.html)。
2、[关于AFNetworking3.0+的使用](https://www.jianshu.com/p/5e187c9d389b)。

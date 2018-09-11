//
//  ZMEngine.m
//  Demo
//
//  Created by chenzm on 2018/9/10.
//  Copyright © 2018年 chenzm. All rights reserved.
//

#import "ZMEngine.h"
#import "ZMWKWebViewVC.h"
@implementation ZMEngine

+(ZMEngine *)shareZMEngine{
    static ZMEngine *pay = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pay = [[ZMEngine alloc]init];
    });
    return pay;
}

///获取文案
-(void)getGWDocumentWithResponse:(ResponseBlock)response{
    NSMutableDictionary *paramsDic = [NSMutableDictionary dictionaryWithCapacity:0];
    paramsDic[@"memberId"] = @(19644);
    paramsDic[@"token"] = @"2c91808365c145cc0165c7939b7a3b03";
    NSString *urlStr = @"member/exchange/recommendCode/document";
    [self base_PostWithUrl:urlStr parameters:paramsDic success:^(id success) {
        response(success);
    } failure:^(id failure) {
        response(failure);
    }];
}


-(void)getWithShopId:(NSInteger)shopId shopApplyId:(NSInteger)shopApplyId response:(ResponseBlock)response{
    NSString *url = @"url链接";
    
    NSString *shopIdStr = [NSString stringWithFormat:@"%ld",(long)shopId];
    NSString *shopApplyIdStr = [NSString stringWithFormat:@"%ld",(long)shopApplyId];
    NSDictionary *dicData = @{@"shopId":shopIdStr?:@"0",
                              @"shopApplyId":shopApplyIdStr?:@"0"
                              };;
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dicData];
    
    [self base_GetWithUrl:url parameters:mDic success:^(id success) {
        response(success);
    } failure:^(id failure) {
        response(failure);
    }];
}

-(void)getWithParameters:(NSDictionary *)params response:(ResponseBlock)response{
    NSString *url = @"url链接";
    
    NSDictionary *dicData = params;
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dicData];
    
    [self base_GetWithUrl:url parameters:mDic success:^(id success) {
        if ([self getResultCode:success] == 1) {
            response(success);
        }else{
            response(success);
        }
    } failure:^(id failure) {
        response(failure);
    }];
}

///监测是否上传打印日志
-(void)checkUploadLogWithResponse:(ResponseBlock)response{
    
    NSString *url = @"common/phone/logs";
    NSDictionary *dicData = @{};
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dicData];
    
    [self base_GetWithUrl:url parameters:mDic success:^(id success) {
        if ([self getResultCode:success] == 1) {
            response(success);
        }else{
            response(success);
        }

    } failure:^(id failure) {
        response(failure);
    }];
}


- (void)updateFileWithfileName:(NSString*)fileName filePath:(NSString *)filePath response:(ResponseBlock)response{
    NSString *url = @"fileupload/fileupload/logs";
    NSString *upName = @"ZMLog.zip";
    NSDictionary *dicData = @{};
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:dicData];
    [self base_UpdateFileWithUrl:url parameters:mDic fileName:fileName upName:upName filePath:filePath progress:^(id progress) {
        
    } success:^(id success) {
        response(success);
    } failure:^(id failure) {
        response(failure);
    }];
}

#pragma mark - 获取请求结果

-(NSInteger)getResultCode:(id)response{
    NSInteger resultCode =
    [[NSString stringWithFormat:@"%@",response[Req_resultCode]] integerValue];
    return resultCode;
}

-(NSString *)getResultMsg:(id)response{
    NSString *resultMsg =
    [NSString stringWithFormat:@"%@",response[Req_errorMessage]]?:@"请重试";
    return resultMsg;
}

-(NSDictionary *)getResultData:(id)response{
    NSDictionary *resultMsg = response[Req_data]?:@{};
    return resultMsg;
}

@end

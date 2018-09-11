//
//  ZMEngine.h
//  Demo
//
//  Created by chenzm on 2018/9/10.
//  Copyright © 2018年 chenzm. All rights reserved.
//

#import "ZMBaseEngine.h"

#define kZMEngine [ZMEngine shareZMEngine]

@interface ZMEngine : ZMBaseEngine

///单粒
+(ZMEngine *)shareZMEngine;

///获取文案
-(void)getGWDocumentWithResponse:(ResponseBlock)response;

-(void)getWithShopId:(NSInteger)shopId shopApplyId:(NSInteger)shopApplyId response:(ResponseBlock)response;


-(void)getWithParameters:(NSDictionary *)params response:(ResponseBlock)response;

///监测是否上传打印日志
-(void)checkUploadLogWithResponse:(ResponseBlock)response;

///上传打印日志信息
- (void)updateFileWithfileName:(NSString*)fileName filePath:(NSString *)filePath response:(ResponseBlock)response;

#pragma mark - 获取请求结果
-(NSInteger)getResultCode:(id)response;

-(NSString *)getResultMsg:(id)response;

-(NSDictionary *)getResultData:(id)response;

@end

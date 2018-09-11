//
//  ZMLogView.m
//  Demo
//
//  Created by chenzm on 2018/9/10.
//  Copyright © 2018年 chenzm. All rights reserved.
//

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

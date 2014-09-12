//
//  Action.m
//  article
//
//  Created by EasyIOS on 14-4-8.
//  Copyright (c) 2014年 zhuchao. All rights reserved.
//

#import "Action.h"
#import "RACEXTScope.h"
@implementation Action

DEF_SINGLETON(Action)

+(id)Action{
    return [[[self class] alloc] init];
}

- (id)initWithCache
{
    self = [self init];
    [self useCache];
	return self;
}
-(void)useCache{

}
-(void)readFromCache{

}
-(void)notReadFromCache{

}

-(AFHTTPRequestOperation *)Send:(Request *)msg{
    if([msg.METHOD isEqualToString:@"GET"]){
         return [self GET:msg];
    }else{
         return [self POST:msg];
    }
}

-(AFHTTPRequestOperation *) GET:(Request *)msg
{
    NSString *url = @"";
    if([msg.SCHEME isEmpty] || [msg.HOST isEmpty]){
        url = [NSString stringWithFormat:@"http://%@%@",HOST_URL,msg.PATH];
    }else{
        url = [NSString stringWithFormat:@"%@://%@%@",msg.SCHEME,msg.HOST,msg.PATH];
    }
    NSDictionary *requestParams = nil;
    if([msg.appendPathInfo isEmpty]){
        requestParams = msg.requestParams;
    }else{
        url = [url stringByAppendingString:msg.appendPathInfo];
    }
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc]initWithBaseURL:[NSURL URLWithString:url]];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [self sending:msg];
    @weakify(msg,self);
    
    return [manager GET:url parameters:requestParams success:^(AFHTTPRequestOperation *operation, NSDictionary* jsonObject) {
        @strongify(msg,self);
        msg.output = jsonObject;
        [self checkCode:msg];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        @strongify(msg,self);
        msg.error = error;
        [self failed:msg];
    }];
}


-(AFHTTPRequestOperation *)POST:(Request *)msg{
    NSString *url = @"";
    if([msg.SCHEME isEmpty] || [msg.HOST isEmpty]){
        url = [NSString stringWithFormat:@"http://%@%@",HOST_URL,msg.PATH];
    }else{
        url = [NSString stringWithFormat:@"%@://%@%@",msg.SCHEME,msg.HOST,msg.PATH];
    }
    NSDictionary *requestParams = nil;
    if([msg.appendPathInfo isEmpty]){
        requestParams = msg.requestParams;
    }else{
        url = [url stringByAppendingString:msg.appendPathInfo];
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [self sending:msg];
    @weakify(msg,self);
    
    NSDictionary *file = msg.requestFiles;
    AFHTTPRequestOperation *op = [manager POST:url parameters:requestParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if([file count]>0){
            for (NSString *key in [file allKeys]) {
                [formData appendPartWithFileURL:[file objectForKey:key] name:key error:nil];
            }
        }
    } success:^(AFHTTPRequestOperation *operation, NSDictionary* jsonObject) {
        @strongify(msg,self);
        msg.output = jsonObject;
        [self checkCode:msg];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        @strongify(msg,self);
        msg.error = error;
        [self failed:msg];
    }];
    if(file.count >0){
        [op setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            @strongify(msg,self);
            msg.totalBytesWritten = totalBytesWritten;
            msg.totalBytesExpectedToWrite = totalBytesExpectedToWrite;
            msg.progress = totalBytesExpectedToWrite/totalBytesWritten;
            [self progressing:msg];
        }];
    }
    return op;
}

-(void)checkCode:(Request *)msg{
    if([msg.output objectAtPath:CODE_KEY] && [[msg.output objectAtPath:CODE_KEY] intValue] == RIGHT_CODE){
        [self success:msg];
    }else{
        [self error:msg];
    }
}

-(void)sending:(Request *)msg{
    msg.state = SendingState;
    if([self.aDelegaete respondsToSelector:@selector(handleActionMsg:)]){
        [self.aDelegaete handleActionMsg:msg];
    }
}

- (void)success:(Request *)msg{
    msg.discription = [msg.output objectAtPath:MSG_KEY];
    if (msg.state != SuccessState) {
        msg.state = SuccessState;
        if([self.aDelegaete respondsToSelector:@selector(handleActionMsg:)]){
            [self.aDelegaete handleActionMsg:msg];
        }
    }
}

- (void)failed:(Request *)msg{
    if(msg.error.userInfo!= nil && [msg.error.userInfo objectForKey:@"NSLocalizedDescription"]){
        msg.discription = [msg.error.userInfo objectForKey:@"NSLocalizedDescription"];
    }
    msg.state = FailState;
    NSLog(@"Failed:%@",msg.error);
    if([self.aDelegaete respondsToSelector:@selector(handleActionMsg:)]){
        [self.aDelegaete handleActionMsg:msg];
    }
}

- (void)error:(Request *)msg{
    if([msg.output objectAtPath:MSG_KEY]){
        msg.discription = [msg.output objectAtPath:MSG_KEY];
        NSLog(@"Error:%@",msg.discription);
    }
    msg.state = ErrorState;
    if([self.aDelegaete respondsToSelector:@selector(handleActionMsg:)]){
        [self.aDelegaete handleActionMsg:msg];
    }
}

-(void)progressing:(Request *)msg{
    if([self.aDelegaete respondsToSelector:@selector(handleProgressMsg:)]){
        [self.aDelegaete handleProgressMsg:msg];
    }
}

@end

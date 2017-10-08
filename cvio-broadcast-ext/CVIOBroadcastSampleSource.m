//
//  CVIOBroadcastSampleSource.m
//  cvio-broadcast-ext
//
//  Created by Ales Teska on 8.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CVIOBroadcastSampleSource.h"

@implementation CVIOBroadcastSampleSource

@synthesize delegate;

-(instancetype)init:(id<CVIOSourceDelegate>)in_delegate
{
	self = [super init];
	if (self == nil) return nil;
	
	delegate = in_delegate;
	
	return self;
}

- (CGSize)getSize
{
	//TODO: Onbtain these values from somewhere
	CGSize ret = {
		.width = 640,
		.height = 1136,
	};
	return ret;
}

-(void)start
{
}

-(void)stop
{
}

@end

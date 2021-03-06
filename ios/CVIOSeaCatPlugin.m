//
//  CVIOSeaCatPlugin.m
//  ios
//
//  Created by Ales Teska on 1.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#import "CVIOSeaCatPlugin.h"

@implementation CVIOSeaCatPlugin {
	int myPort;
}

- (CVIOSeaCatPlugin *)init:(int)port
{
	self = [super init];
	if (self == nil) return nil;
	myPort = port;

	return self;
}

- (NSDictionary *)getCharacteristics
{
	return @{ @"RA" : [NSString stringWithFormat:@"vnc:%d", myPort] };
}

- (void)configureSocket:(NSString *) socketAddress
{
	[SeaCatClient configureSocket:myPort domain:AF_UNIX sock_type:SOCK_STREAM protocol:0 peerAddress:socketAddress peerPort:@""];
}

// Submit CSR
-(bool)submit:(NSError **)out_error
{
	NSString * APIKeyId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CVIOApiKeyId"];
	if (APIKeyId == nil)
	{
		NSLog(@"CatVision.io API key (CVIOApiKeyId) not provided. See https://docs.catvision.io/get-started/api-key.html");
		return nil;
	}
	
	NSBundle *bundle = [NSBundle mainBundle];
	NSDictionary *info = [bundle infoDictionary];
	
	SCCSR * csr = [[SCCSR alloc] init];
	[csr setOrganization:[info objectForKey:(NSString*)kCFBundleIdentifierKey]];
	[csr setOrganizationUnit:APIKeyId];
	return [csr submit:out_error];
}


@end

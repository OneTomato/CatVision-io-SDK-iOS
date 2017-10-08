//
//  CatVision.m
//  CatVision.io SDK for iOS
//
//  Created by Ales Teska on 1.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SeaCatClient/SeaCatClient.h>

#import "CVIOSeaCatPlugin.h"
#import "CatVisionIO.h"
#import "VNCServer.h"
#import "ReplayKitSource/CVIOReplayKitSource.h"

@implementation CatVision {
	NSString * socketAddress;
	VNCServer * mVNCServer;
	BOOL mSeaCatCofigured;
	BOOL mStarted;
	CVIOSeaCatPlugin * plugin;	
	id<CVIOSource> source;

	CVImageBufferRef capturedImage;
}

+ (instancetype)sharedInstance
{
	static CatVision *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[CatVision alloc] initPrivate];
	});
	return sharedInstance;
}

- (instancetype)initPrivate
{
	self = [super init];
	if (self == nil) return nil;

	mVNCServer = nil;
	mSeaCatCofigured = NO;
	mStarted = NO;

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSMutableString *addr = [[paths objectAtIndex:0] mutableCopy];
	
	NSError *error;
	if (![[NSFileManager defaultManager] createDirectoryAtPath:addr withIntermediateDirectories:YES attributes:nil error:&error])
	{
		NSLog(@"Create directory error: %@", error);
	}

	[addr appendString:@"/vnc.s"]; //TODO: socket name can be more unique - it will allow to start more than one VNC server if needed
	socketAddress = [addr copy];
	
	[SeaCatClient setApplicationId:@"com.teskalabs.cvio"];
	//This is to enable SeaCat debug logging [SeaCatClient setLogMask:SC_LOG_FLAG_DEBUG_GENERIC];
	plugin = [[CVIOSeaCatPlugin alloc] init:5900];
	
	source = nil;
	capturedImage = nil;

	return self;
}

- (void)setSource:(id<CVIOSource>)in_source
{
	if (mStarted != NO)
	{
		NSLog(@"CVIO Source can be changed only if CatVision.io is not started");
		return;
	}

	source = in_source;
}

- (BOOL)start
{
	mStarted = YES;

	// ReplayKit is a default source
	if (source == nil)
	{
		source = [[CVIOReplayKitSource alloc] init:self];
	}
	
	if (mVNCServer == nil)
	{
		CGSize size = [source getSize];
		mVNCServer = [[VNCServer new] init:self address:socketAddress size:size downScaleFactor:1];
		if (mVNCServer == nil) return NO;
	}
	[mVNCServer start];
	
	// VNC Server started
	if (mSeaCatCofigured == NO) //TODO: if (![SeaCatClient isConfigured])
	{
		[SeaCatClient configureWithCSRDelegate:self];
		[plugin configureSocket:socketAddress];
		mSeaCatCofigured = YES;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		[source start];
	});
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// Wait till SeaCat is ready
		//TODO: This can be implemented in much more 'Grand Central Dispatch friendly' way, avoid sleep(1)
		while (![SeaCatClient isReady])
		{
			NSLog(@"SeaCat is not ready (%@) ... waiting", [SeaCatClient getState]);
			sleep(1);
		}
		NSLog(@"SeaCat is READY");
		[SeaCatClient connect];
	});

	return YES;
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

-(void)handleSourceBuffer:(CMSampleBufferRef)sampleBuffer sampleType:(RPSampleBufferType)sampleType
{
	CVImageBufferRef c = CMSampleBufferGetImageBuffer(sampleBuffer);
	if (c == NULL)
	{
		NSLog(@"CVIO CMSampleBufferGetImageBuffer() failed");
		return;
	}

	// This is maybe a critical section b/c of manipulation with capturedImage
	{
		if (capturedImage != nil)
		{
			CVPixelBufferRelease(capturedImage);
			capturedImage = nil;
		}

		capturedImage = c;
		CVPixelBufferRetain(capturedImage);
	}
	
	[mVNCServer imageReady];
}

-(int)takeImage
{
	if (capturedImage == nil) return 0;

	// This is maybe a critical section b/c of manipulation with capturedImage
	CVImageBufferRef image = capturedImage;
	capturedImage = nil;

	OSType capturedImagePixelFormat = CVPixelBufferGetPixelFormatType(image);
	switch (capturedImagePixelFormat) {
		case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
			[mVNCServer pushPixels_420YpCbCr8BiPlanarFullRange:image];
			break;

		default:
			NSLog(@"CVIO Captured image is in an unknown format: %08X", capturedImagePixelFormat);
			break;
	};

	CVPixelBufferRelease(image);
	return 0;
}

@end


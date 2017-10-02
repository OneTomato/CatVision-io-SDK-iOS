//
//  ios.h
//  CatVision.io SDK for iOS
//
//  Created by Ales Teska on 28.9.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReplayKit/ReplayKit.h>
#import <SeaCatClient/SeaCatClient.h>
#import <VNCServer/VNCServer.h>

#include "CVIOInterfaces.h"

//! Project version number for ios.
FOUNDATION_EXPORT double CatVisionVersionNumber;

//! Project version string for ios.
FOUNDATION_EXPORT const unsigned char CatVisionVersionString[];

@interface CatVision : NSObject <SeaCatCSRDelegate, VNCServerDelegate, CVIOSourceDelegate>

+ (instancetype)sharedInstance;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)start;

@end


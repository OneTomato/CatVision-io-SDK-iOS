//
//  VNCServer.h
//  VNCServer
//
//  Created by Ales Teska on 28.9.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for VNCServer.
FOUNDATION_EXPORT double VNCServerVersionNumber;

//! Project version string for VNCServer.
FOUNDATION_EXPORT const unsigned char VNCServerVersionString[];

@interface VNCServer : NSObject

- (id)init:(int)width height:(int)height;
- (void)run;
- (int)shutdown;

@end

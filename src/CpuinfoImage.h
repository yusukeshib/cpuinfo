//
//  CpuinfoImage.h
//  cpuinfo
//
//  Created by shibata on 10/14/19.
//  Copyright © 2019 Yusuke Shibata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Cpuinfo.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface CpuinfoImage : NSImage

- (void)update;
- (void)setCpuinfo:(Cpuinfo *)cpuinfo;

@property BOOL darkMode;
@property BOOL textEnabled;
@property BOOL imageEnabled;
@property BOOL multiCoreEnabled;

@end

NS_ASSUME_NONNULL_END

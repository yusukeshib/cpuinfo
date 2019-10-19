//
//  CpuinfoImage.h
//  cpuinfo
//
//  Created by shibata on 10/14/19.
//  Copyright © 2019 Yusuke Shibata. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CpuinfoImage : NSImage

- (void) updateUsage:(int)usage;

@end

NS_ASSUME_NONNULL_END

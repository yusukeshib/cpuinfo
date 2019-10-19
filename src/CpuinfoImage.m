//
//  CpuinfoImage.m
//  cpuinfo
//
//  Created by shibata on 10/14/19.
//  Copyright © 2019 Yusuke Shibata. All rights reserved.
//

#import "CpuinfoImage.h"

@implementation CpuinfoImage

- (void) updateUsage:(int)usage
{
  float w = self.size.width; 
  float h = self.size.height;
  
  // lock
  [self lockFocus];
  [NSGraphicsContext saveGraphicsState];
  
  NSRect rect = NSMakeRect(0, 0, w, h);

  // clear all
  [self drawInRect:rect fromRect:rect operation:NSCompositeClear fraction:1.0];
  
  // clip rounded
  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:h/2 yRadius:h/2];
  [path addClip];

  // background
  [[NSColor windowBackgroundColor] set];
  NSRectFill(rect);
  
  // usage
  [[NSColor greenColor] set];
  NSRectFill(NSMakeRect(0, 0, w*usage/100.0f, h));
  
  // unlock
  [NSGraphicsContext restoreGraphicsState];
  [self unlockFocus];
  
}

@end

//
//  CpuinfoImage.m
//  cpuinfo
//
//  Created by shibata on 10/14/19.
//  Copyright © 2019 Yusuke Shibata. All rights reserved.
//

#import "CpuinfoImage.h"

#define HEIGHT 24.0f
#define HOSTIMAGEWIDTH 32.0f
#define COREIMAGEWIDTH 24.0f
#define COREMARGIN 4.0f
#define IMAGEHEIGHT 8.0f
#define TEXTWIDTH 32.0f
#define TEXTHEIGHT 12.0f

@implementation CpuinfoImage {
  Cpuinfo *cpuinfo;
}

@synthesize imageEnabled = _imageEnabled;
@synthesize textEnabled = _textEnabled;
@synthesize multiCoreEnabled = _multiCoreEnabled;

- (void)setCpuinfo:(Cpuinfo *)_cpuinfo
{
  cpuinfo = _cpuinfo;
}

- (BOOL)appearanceIsDark
{
  if (@available(macOS 10.14, *)) {
    NSAppearance *appearance = NSAppearance.currentAppearance;
    NSAppearanceName basicAppearance = [appearance bestMatchFromAppearancesWithNames:@[
      NSAppearanceNameAqua,
      NSAppearanceNameDarkAqua
    ]];
    return [basicAppearance isEqualToString:NSAppearanceNameDarkAqua];
  } else {
    return NO;
  }
}

- (NSColor *)textColorForUsage:(float)usage
{
  // usage
  if(usage < 0.75) {
    if (@available(macOS 10.13, *)) {
      return [NSColor colorNamed:@"GreenText"];
    } else if([self appearanceIsDark]) {
      return [NSColor systemGreenColor];
    } else {
      return [NSColor blackColor];
    }
  }
  else if(usage < 0.9) {
    return [NSColor systemOrangeColor];
  }
  else {
    return [NSColor systemRedColor];
  }
}

- (NSColor *)imageColorForUsage:(float)usage
{
  // usage
  if(usage < 0.75) {
    return [NSColor systemGreenColor];
  }
  else if(usage < 0.9) {
    return [NSColor systemOrangeColor];
  }
  else {
    return [NSColor systemRedColor];
  }
}

-(BOOL)multiCoreEnabled
{
  return _multiCoreEnabled;
}

-(void)setMultiCoreEnabled:(BOOL)multiCoreEnabled
{
  _multiCoreEnabled = multiCoreEnabled;
  [self updateSize];
}

-(BOOL)imageEnabled
{
  return _imageEnabled;
}

-(void)setImageEnabled:(BOOL)imageEnabled
{
  _imageEnabled = imageEnabled;
  [self updateSize];
}

-(BOOL)textEnabled
{
  return _textEnabled;
}

-(void)setTextEnabled:(BOOL)textEnabled
{
  _textEnabled = textEnabled;
  [self updateSize];
}

- (void)updateSize
{
  CGFloat width = 0;
  int iteration = _multiCoreEnabled ? cpuinfo->getCoreCount() : 1;
  for(int i = 0; i< iteration; i++) {
    if(_textEnabled) width += TEXTWIDTH;
    if(_imageEnabled) width += _multiCoreEnabled ? COREIMAGEWIDTH : HOSTIMAGEWIDTH;
    if(_multiCoreEnabled) width += COREMARGIN;
  }
  self.size = NSMakeSize(width, HEIGHT);
  [self update];
}

- (void)update
{
  float w = self.size.width; 
  float h = self.size.height;
  
  if(w == 0 || h == 0) return;
  
  // lock
  [self lockFocus];
  
  // clear all
  {
    NSRect rect = NSMakeRect(0, 0, w, h);
    [self drawInRect:rect fromRect:rect operation:NSCompositeClear fraction:1.0];
  }
  
  float offset = 0;
  
  if(_multiCoreEnabled) {
    for(int i = 0; i < cpuinfo->getCoreCount(); i++) {
      double coreUsage = cpuinfo->getCoreUsageAt(i);
    
      if(_imageEnabled) {
        NSRect rect = NSMakeRect(offset, (HEIGHT - IMAGEHEIGHT)/2, COREIMAGEWIDTH, IMAGEHEIGHT);
        
        [NSGraphicsContext saveGraphicsState];
        
        // clip rounded
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:IMAGEHEIGHT/2 yRadius:IMAGEHEIGHT/2];
        [path addClip];
        
        // background
        [[NSColor windowBackgroundColor] set];
        NSRectFill(rect);
        
        // usage
        [[self imageColorForUsage:coreUsage] set];
        NSRectFill(NSMakeRect(offset, (HEIGHT - IMAGEHEIGHT)/2, COREIMAGEWIDTH*coreUsage, IMAGEHEIGHT));
        
        [NSGraphicsContext restoreGraphicsState];
        
        offset += COREIMAGEWIDTH;
      }
      
      //
      if(_textEnabled) {  
        NSRect rect = NSMakeRect(offset, (HEIGHT - TEXTHEIGHT)/2, TEXTWIDTH, TEXTHEIGHT);
        
        [NSGraphicsContext saveGraphicsState];
        
        // clear all
        [self drawInRect:rect fromRect:rect operation:NSCompositeClear fraction:1.0];
        
        NSFont *font = [NSFont monospacedDigitSystemFontOfSize:[NSFont smallSystemFontSize] weight:NSFontWeightRegular];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.alignment = NSTextAlignmentCenter;
        NSDictionary *attributes = @{
          NSFontAttributeName: font,
          NSParagraphStyleAttributeName: style,
          NSForegroundColorAttributeName: [self textColorForUsage:coreUsage]
        };
        NSString *str = [NSString stringWithFormat:@"%d%%", (int)round(coreUsage * 100.0f)];
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:str attributes:attributes];
        [text drawInRect:rect];
        
        [NSGraphicsContext restoreGraphicsState];
        
        offset += TEXTWIDTH;
      }
      
      offset += COREMARGIN;

    }
    
  }
  else {
    double hostUsage = cpuinfo->getHostUsage();
    
    if(_imageEnabled) {
      NSRect rect = NSMakeRect(0, (HEIGHT - IMAGEHEIGHT)/2, HOSTIMAGEWIDTH, IMAGEHEIGHT);
      
      [NSGraphicsContext saveGraphicsState];

      // clip rounded
      NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:IMAGEHEIGHT/2 yRadius:IMAGEHEIGHT/2];
      [path addClip];

      // background
      [[NSColor windowBackgroundColor] set];
      NSRectFill(rect);
      
      // usage
      [[self imageColorForUsage:hostUsage] set];
      NSRectFill(NSMakeRect(0, (HEIGHT - IMAGEHEIGHT)/2, HOSTIMAGEWIDTH*hostUsage, IMAGEHEIGHT));

      [NSGraphicsContext restoreGraphicsState];
      
      offset += HOSTIMAGEWIDTH;
    }

    //
    if(_textEnabled) {  
      NSRect rect = NSMakeRect(offset, (HEIGHT - TEXTHEIGHT)/2, TEXTWIDTH, TEXTHEIGHT);
      
      [NSGraphicsContext saveGraphicsState];

      // clear all
      [self drawInRect:rect fromRect:rect operation:NSCompositeClear fraction:1.0];
      
      NSFont *font = [NSFont monospacedDigitSystemFontOfSize:[NSFont smallSystemFontSize] weight:NSFontWeightRegular];
      NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
      style.alignment = NSTextAlignmentCenter;
      NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSParagraphStyleAttributeName: style,
        NSForegroundColorAttributeName: [self textColorForUsage:hostUsage]
      };
      NSString *str = [NSString stringWithFormat:@"%d%%", (int)round(hostUsage * 100.0f)];
      NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:str attributes:attributes];
      [text drawInRect:rect];

      [NSGraphicsContext restoreGraphicsState];
    }
  }
  
  // unlock
  [self unlockFocus];
  
}

@end

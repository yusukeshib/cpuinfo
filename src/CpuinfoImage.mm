//
//  CpuinfoImage.m
//  cpuinfo
//
//  Created by shibata on 10/14/19.
//  Copyright © 2019 Yusuke Shibata. All rights reserved.
//

#import "CpuinfoImage.h"

#define HEIGHT 24.0f
#define TEXTWIDTH 36.0f
#define TEXTHEIGHT 20.0f

@implementation CpuinfoImage {
  Cpuinfo *cpuinfo;
}

@synthesize imageEnabled = _imageEnabled;
@synthesize textEnabled = _textEnabled;
@synthesize darkMode = _darkMode;
@synthesize multiCoreEnabled = _multiCoreEnabled;
@synthesize theme = _theme;

// https://stackoverflow.com/questions/8697205/convert-hex-color-code-to-nscolor/8697241
- (NSColor*)colorWithHexColorString:(NSString*)inColorString
{
  unsigned colorCode = 0;
  if (nil != inColorString)
  {
    NSScanner* scanner = [NSScanner scannerWithString:inColorString];
    (void) [scanner scanHexInt:&colorCode]; // ignore error
  }
  unsigned int red = (unsigned char)(colorCode >> 24);
  unsigned int green = (unsigned char)(colorCode >> 16);
  unsigned int blue = (unsigned char)(colorCode >> 8);
  unsigned int alpha = (unsigned char)(colorCode); // masks off high bits

  NSColor* result = [NSColor
            colorWithCalibratedRed:(CGFloat)red / 0xff
            green:(CGFloat)green / 0xff
            blue:(CGFloat)blue / 0xff
            alpha:(CGFloat)alpha / 0xff];
  return result;
}

- (NSDictionary *)currentTheme
{
  NSArray *themes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"theme"];
  id currentTheme = [themes objectAtIndex:0];
  for(id themeItem in themes) {
    NSString *name = [themeItem objectForKey:@"name"];
    if([name isEqual: _theme]) {
      currentTheme = themeItem;
      break;
    }
  }
  return [currentTheme objectForKey: _darkMode ? @"dark" : @"light"];
}

- (NSColor *)colorForKey: (NSString *)key
{
  NSDictionary *theme = [self currentTheme];
  NSString *colorHex = [theme objectForKey:key];
  return [self colorWithHexColorString: colorHex];
}

- (int)intForKey: (NSString *)key
{
  NSDictionary *theme = [self currentTheme];
  NSNumber *value = [theme objectForKey:key];
  return [value intValue];
}

- (double)doubleForKey: (NSString *)key
{
  NSDictionary *theme = [self currentTheme];
  NSNumber *value = [theme objectForKey:key];
  return [value doubleValue];
}

- (void)setCpuinfo:(Cpuinfo *)_cpuinfo
{
  cpuinfo = _cpuinfo;
}

- (NSColor *)textColorForUsage:(double)usage
{
  // usage
  if(usage < 0.75) {
    return [self colorForKey:@"TEXT_NORMALCOLOR"];
  }
  else if(usage < 0.9) {
    return [self colorForKey:@"TEXT_MEDIUMCOLOR"];
  }
  else {
    return [self colorForKey:@"TEXT_HIGHCOLOR"];
  }
}

- (NSColor *)imageColorForUsage:(double)usage
{
  // usage
  if(usage < 0.75) {
    return [self colorForKey:@"BAR_NORMALCOLOR"];
  }
  else if(usage < 0.9) {
    return [self colorForKey:@"BAR_MEDIUMCOLOR"];
  }
  else {
    return [self colorForKey:@"BAR_HIGHCOLOR"];
  }
}

-(void)setTheme:(NSString *)theme
{
  _theme = theme;
}

-(NSString *)theme
{
  return _theme;
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

-(BOOL)darkMode
{
  return _darkMode;
}

-(void)setDarkMode:(BOOL)darkMode
{
  _darkMode = darkMode;
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
  double barWidth = [self doubleForKey: @"BAR_WIDTH"];
  double barCoreWidth = [self doubleForKey: @"BAR_COREWIDTH"];
  double barCoreMargin = [self doubleForKey: @"BAR_COREMARGIN"];
  for(int i = 0; i< iteration; i++) {
    if(_textEnabled) {
      width += TEXTWIDTH;
    }
    if(_imageEnabled) {
      width += _multiCoreEnabled ? barCoreWidth : barWidth;
    }
    if(_multiCoreEnabled) {
      width += barCoreMargin;
    }
  }
  self.size = NSMakeSize(width, HEIGHT);
  [self update];
}

- (double)drawImageAt: (double)usage offset:(double)offset
{
  double barTotalWidth = [self doubleForKey: @"BAR_WIDTH"];
  double barCoreWidth = [self doubleForKey: @"BAR_COREWIDTH"];
  double barWidth = _multiCoreEnabled ? barCoreWidth : barTotalWidth;
  double barHeight = [self doubleForKey: @"BAR_HEIGHT"];
  double barRadius = [self doubleForKey: @"BAR_RADIUS"];
  NSColor *bgColor = [self colorForKey:@"BAR_BACKGROUNDCOLOR"];
  NSColor *borderColor = [self colorForKey:@"BORDER_COLOR"];
  double borderRadius = [self doubleForKey: @"BORDER_RADIUS"];
  double borderWidth = [self doubleForKey: @"BORDER_WIDTH"];

  [NSGraphicsContext saveGraphicsState];

  // clip rounded
  NSRect bgRect = NSMakeRect(offset, (HEIGHT - barHeight)/2, barWidth, barHeight);
  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:bgRect xRadius:borderRadius yRadius:borderRadius];
  [path addClip];
  
  // background
  [bgColor set];
  NSBezierPath *bg = [NSBezierPath bezierPath];
  [bg appendBezierPathWithRoundedRect:bgRect xRadius:borderRadius yRadius:borderRadius];
  [bg fill];
  
  // border
  if(borderWidth > 0) {
    [borderColor set];
    NSBezierPath *border = [NSBezierPath bezierPath];
    NSRect borderRect = NSMakeRect(offset, (HEIGHT - barHeight)/2, barWidth, barHeight);
    [border appendBezierPathWithRoundedRect:borderRect xRadius:borderRadius yRadius:borderRadius];
    [border setLineWidth:borderWidth];
    [border stroke];
  }

  // usage
  [[self imageColorForUsage:usage] set];
  NSBezierPath *bar = [NSBezierPath bezierPath];
  NSRect barRect = NSMakeRect(offset + borderWidth * 2,
                              (HEIGHT - barHeight)/2 + borderWidth * 2,
                              (barWidth - borderWidth * 4) * usage,
                              barHeight - borderWidth * 4);
  [bar appendBezierPathWithRoundedRect:barRect xRadius:barRadius yRadius:barRadius];
  [bar fill];

  [NSGraphicsContext restoreGraphicsState];
  
  return offset + barWidth;
}

- (double)drawTextAt: (double)usage offset:(double)offset
{
  
  [NSGraphicsContext saveGraphicsState];

  NSFont *font = [NSFont menuBarFontOfSize:[NSFont systemFontSize]];
  NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
  style.alignment = NSTextAlignmentCenter;
  NSDictionary *attributes = @{
    NSFontAttributeName: font,
    NSParagraphStyleAttributeName: style,
    NSForegroundColorAttributeName: [self textColorForUsage:usage]
  };
  NSString *str = [NSString stringWithFormat:@"%d%%", (int)round(usage * 100.0f)];
  NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:str attributes:attributes];
  NSRect rect = NSMakeRect(offset, (HEIGHT - TEXTHEIGHT)/2, TEXTWIDTH, TEXTHEIGHT);
  [text drawInRect:rect];
  
  [NSGraphicsContext restoreGraphicsState];
  
  return offset + TEXTWIDTH;
}

- (void)update
{
  double w = self.size.width;
  double h = self.size.height;
  
  if(w == 0 || h == 0) return;
  
  // lock
  [self lockFocus];
  
  // clear all
  NSRect rect = NSMakeRect(0, 0, w, h);
  [self drawInRect:rect fromRect:rect operation:NSCompositeClear fraction:1.0];
  
  double offset = 0;
  
  if(_multiCoreEnabled) {
    int barCoreMargin = [self intForKey: @"BAR_COREMARGIN"];
    for(int i = 0; i < cpuinfo->getCoreCount(); i++) {
      double coreUsage = cpuinfo->getCoreUsageAt(i);
      if(_imageEnabled) {
        offset = [self drawImageAt:coreUsage offset: offset];
      }
      if(_textEnabled) {
        offset = [self drawTextAt:coreUsage offset: offset];
      }
      offset += barCoreMargin;
    }
  }
  else {
    double hostUsage = cpuinfo->getHostUsage();
    
    if(_imageEnabled) {
      offset = [self drawImageAt:hostUsage offset: offset];
    }
    if(_textEnabled) {  
      offset = [self drawTextAt:hostUsage offset: offset];
    }
  }
  
  // unlock
  [self unlockFocus];
}

@end

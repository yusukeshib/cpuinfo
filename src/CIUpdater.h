#import <Cocoa/Cocoa.h>

//#define IMAGESIZE_NORMAL 8
//#define IMAGESIZE_BIG    11
//#define IMAGESIZE_SMALL  4

@interface CIUpdater : NSObject {
  BOOL termination_flg;
  NSLock *proc_lock;
  NSStatusItem *statusItem;
  long updateInterval;
  long imageSize;
  NSImage *barimage;
  NSMutableAttributedString *title;
}

- (void)setUpdateInterval:(long)val;
- (long)updateInterval;
- (void)setImageSize:(long)size;
- (long)imageSize;

-(id)initWithStatusItem:(NSStatusItem *)statusItem;
+(CIUpdater *)runWithStatusItem:(NSStatusItem *)statusItem;
-(void)begin;
-(void)terminate;
-(void)update:(id)param;

@end

#import <Foundation/Foundation.h>

@interface CpumeterUpdater : NSObject {
  BOOL termination_flg;
  NSLock *proc_lock;
  NSStatusItem *statusItem;
  double updateInterval;
  BOOL textmode_flg;
  //
  NSImage *barimage;
  NSMutableAttributedString *title;
}

- (void)setUpdateInterval:(double)val;
- (double)updateInterval;
- (void)setTextMode:(BOOL)flg;
- (BOOL)textMode;

-(id)initWithStatusItem:(NSStatusItem *)statusItem;
+(CpumeterUpdater *)runWithStatusItem:(NSStatusItem *)statusItem;
-(void)begin;
-(void)terminate;
-(void)update:(id)param;

@end

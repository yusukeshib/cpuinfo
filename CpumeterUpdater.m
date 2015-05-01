#import "CpumeterUpdater.h"
#import <mach/host_info.h>
#import <mach/processor_info.h>

@implementation CpumeterUpdater

-(id)initWithStatusItem:(NSStatusItem *)si {
  self = [super init];
  if(self != nil) {
    termination_flg = NO;
    proc_lock = [[NSLock alloc] init];
    statusItem = si;
    updateInterval = 0.5;
    textmode_flg = YES;
  }
  return self;
}
-(void)dealloc {
  [self terminate];
  [proc_lock release];
  [super dealloc];
}
- (void)setUpdateInterval:(double)val {
  updateInterval = val;
}
- (double)updateInterval {
  return updateInterval;
}
- (void)setTextMode:(BOOL)flg {
  textmode_flg = flg;
}
- (BOOL)textMode {
  return textmode_flg;
}
+(CpumeterUpdater *)runWithStatusItem:(NSStatusItem *)statusItem {
  CpumeterUpdater *updater = [[CpumeterUpdater alloc] initWithStatusItem:statusItem];
  [updater begin];
  return updater;
}
-(void)begin {
  [proc_lock lock];
  [NSThread detachNewThreadSelector:@selector(update:)
	    toTarget:self
	    withObject:nil];
}
-(void)terminate {
  termination_flg = YES;
  [proc_lock lock]; // wait for terminate.
  [proc_lock unlock];
}
-(void)update:(id)param {
  mach_port_t host_port;
  host_cpu_load_info_data_t prev_cpu_load, cpu_load;
  mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
  natural_t user, system, idle;
  int usage;
    
  NSAutoreleasePool* pool;
  pool = [[NSAutoreleasePool alloc]init];
  
  host_port = mach_host_self();
  host_statistics(host_port, HOST_CPU_LOAD_INFO, (host_info_t)&prev_cpu_load, &count);
  
  while(termination_flg == NO) {
    [NSThread sleepForTimeInterval:updateInterval];
    host_statistics(host_port, HOST_CPU_LOAD_INFO, (host_info_t)&cpu_load, &count);
    user = cpu_load.cpu_ticks[CPU_STATE_USER] - prev_cpu_load.cpu_ticks[CPU_STATE_USER];
    system = cpu_load.cpu_ticks[CPU_STATE_SYSTEM] - prev_cpu_load.cpu_ticks[CPU_STATE_SYSTEM];
    idle = cpu_load.cpu_ticks[CPU_STATE_IDLE] - prev_cpu_load.cpu_ticks[CPU_STATE_IDLE];
    usage = round((double)(user + system) / (system + user + idle) * 100.0);
    prev_cpu_load = cpu_load;
      
    [self performSelectorOnMainThread:@selector(updateView:) withObject:[NSNumber numberWithInt:usage] waitUntilDone:NO];
  }
  //
  [proc_lock unlock];
  [pool release];
  [NSThread exit];
}
-(void) updateView:(NSNumber *)usageNum {
    int usage = [usageNum intValue];
    NSImage *image = [NSImage imageNamed:@"base.png"];
    //
    if(textmode_flg == NO) {
        [image lockFocus];
        [[NSColor blackColor] set];
        NSRectFill(NSMakeRect(1,7,20,4));
        [[NSColor greenColor] set];
        NSRectFill(NSMakeRect(1,7,20*usage/100,4));
        [image unlockFocus];
        [statusItem setImage:image];
        [statusItem setTitle:nil];
    } else {
        [statusItem setImage:nil];
        [statusItem setTitle:[NSString stringWithFormat:@"%d%%",usage]];
    }
   
}

@end

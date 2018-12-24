#import "CpuinfoDelegate.h"
#import <mach/host_info.h>
#import <mach/processor_info.h>

#define BORDERWIDTH 0.5f
#define BARWIDTH 36.0f
#define IMAGESIZE 8

@implementation CpuinfoDelegate {
  NSStatusItem *statusItem;
  StartAtLoginController *loginController;
  BOOL running;
  NSImage *image;
  NSMutableAttributedString *title;
  dispatch_group_t group;
}

@synthesize window;
@synthesize statusMenu;
@synthesize mi_updateInterval;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self begin];
}

-(void)awakeFromNib{
  statusItem = [[NSStatusBar systemStatusBar]
                statusItemWithLength:NSVariableStatusItemLength];
  [statusItem setMenu:self.statusMenu];
  [statusItem setTitle:@""];
  [statusItem setHighlightMode:YES];
  //
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults registerDefaults:
   @{
     @"updateInterval": @500,
     @"showImage": @YES,
     @"showText": @NO
     }];
  self.updateInterval = [defaults integerForKey:@"updateInterval"];
  self.showImage = [defaults boolForKey:@"showImage"];
  self.showText = [defaults boolForKey:@"showText"];

  // updateInterval
  for(int i=0;i<mi_updateInterval.submenu.itemArray.count;i++) {
    NSMenuItem *mi = mi_updateInterval.submenu.itemArray[i];
    mi.state = mi.tag == self.updateInterval ? NSOnState : NSOffState;
  }
  //
  NSString * identifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".helper"];
  loginController = [[StartAtLoginController alloc] initWithIdentifier:identifier];
  self.startAtLogin = [loginController startAtLogin];
  
  //
  image = [[NSImage alloc] initWithSize:NSMakeSize(BARWIDTH, IMAGESIZE)];
  NSFont *font = [NSFont monospacedDigitSystemFontOfSize:[NSFont smallSystemFontSize]
                                                  weight:NSFontWeightRegular];
  NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                         forKey:NSFontAttributeName];
  title = [[NSMutableAttributedString alloc] initWithString:@"---"
                                                 attributes:attributes];
}

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  [self terminate];
  return NSTerminateNow;
}

- (IBAction)updateUpdateInterval:(id)sender {
  NSMenuItem *mi_selected = sender;
  mi_selected.state = NSOnState;
  for(int i=0;i<mi_selected.menu.itemArray.count;i++) {
    NSMenuItem *mi = mi_selected.menu.itemArray[i];
    if(mi != mi_selected) mi.state = NSOffState;
  }
  self.updateInterval = mi_selected.tag;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithInteger:self.updateInterval]
               forKey:@"updateInterval"];
}

- (IBAction)updateShowImage:(id)sender {
  BOOL showImage = !self.showImage;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:showImage forKey:@"showImage"];
}

- (IBAction)updateShowText:(id)sender {
  BOOL showText = !self.showText;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:showText forKey:@"showText"];
}

- (IBAction)updateStartAtLogin:(id)sender {
  BOOL startAtLogin = !self.startAtLogin;
  loginController.startAtLogin = startAtLogin;
}

- (IBAction)launchActivityMonitor:(id)sender {
  [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.ActivityMonitor"
                                                       options:NSWorkspaceLaunchDefault
                                additionalEventParamDescriptor:nil
                                              launchIdentifier:nil];
}

-(void)begin {
  running = YES;
  group = dispatch_group_create();
  dispatch_group_enter(group);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self updateLoop];
    dispatch_group_leave(group);
  });
}

-(void)terminate {
  running = NO;
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  // dispatch_release(group);
}

-(void)updateLoop {
  mach_port_t host_port;
  host_cpu_load_info_data_t prev_cpu_load, cpu_load;
  mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
  natural_t user, system, idle;
  int usage;
  
  @autoreleasepool {
    host_port = mach_host_self();
    host_statistics(host_port, HOST_CPU_LOAD_INFO, (host_info_t)&prev_cpu_load, &count);
    
    while(running) {
      double interval = MAX((double)self.updateInterval/1000.0, 0.1);
      [NSThread sleepForTimeInterval:interval];
      host_statistics(host_port, HOST_CPU_LOAD_INFO, (host_info_t)&cpu_load, &count);
      user = cpu_load.cpu_ticks[CPU_STATE_USER] - prev_cpu_load.cpu_ticks[CPU_STATE_USER];
      system = cpu_load.cpu_ticks[CPU_STATE_SYSTEM] - prev_cpu_load.cpu_ticks[CPU_STATE_SYSTEM];
      idle = cpu_load.cpu_ticks[CPU_STATE_IDLE] - prev_cpu_load.cpu_ticks[CPU_STATE_IDLE];
      double total = system + user + idle;
      if(total == 0) continue;
      usage = round((double)(user + system) / total * 100.0);
      prev_cpu_load = cpu_load;
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [self updateView:usage];
      });
    }
  }
}

-(void) updateView:(int)usage {
  if(self.showImage) {
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];

    // clear all
    NSRect rect = NSMakeRect(0, 0, BARWIDTH, IMAGESIZE);
    [image drawInRect:rect
             fromRect:rect
            operation:NSCompositeClear
             fraction:1.0];
    
    NSRect barrect = NSMakeRect(
                                BORDERWIDTH,
                                BORDERWIDTH,
                                BARWIDTH-BORDERWIDTH*2,
                                IMAGESIZE-BORDERWIDTH*2
                                );
    
    // border radius
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:barrect
                                                         xRadius:3
                                                         yRadius:3];
    [path addClip];
    // background
    [[NSColor windowBackgroundColor] set];
    NSRectFill(barrect);
    
    // green bar
    [[NSColor greenColor] set];
    NSRectFill(NSMakeRect(
                          BORDERWIDTH,
                          BORDERWIDTH,
                          (BARWIDTH-BORDERWIDTH*2)*usage/100.0f,
                          IMAGESIZE-BORDERWIDTH*2
                          ));
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    statusItem.image = image;
  } else {
    statusItem.image = nil;
  }
  if(self.showText) {
    title.mutableString.string = [NSString stringWithFormat:@"%d%%",usage];
    statusItem.attributedTitle = title;
  } else {
    statusItem.attributedTitle = nil;
  }
}

@end

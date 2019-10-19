#import "CpuinfoDelegate.h"
#import "CpuinfoImage.h"
#import "Cpuinfo.hpp"

#define BARWIDTH 36.0f
#define IMAGESIZE 6.0f

@implementation CpuinfoDelegate {
  NSStatusItem *statusItem;
  StartAtLoginController *loginController;
  BOOL running;
  CpuinfoImage *image;
  Cpuinfo cpuinfo;
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
  image = [[CpuinfoImage alloc] initWithSize:NSMakeSize(BARWIDTH, IMAGESIZE)];
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
  int usage;
  
  @autoreleasepool {
    while(running) {
      double interval = MAX((double)self.updateInterval/1000.0, 0.1);
      [NSThread sleepForTimeInterval:interval];
      
      cpuinfo.update();
      usage = round(cpuinfo.getUsage() * 100.0);
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [self updateView:usage];
      });
    }
  }
}

-(void) updateView:(int)usage {
  if(self.showImage) {
    [image updateUsage:usage];
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


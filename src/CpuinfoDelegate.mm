#import "CpuinfoDelegate.h"
#import "Cpuinfo.hpp"

@implementation CpuinfoDelegate {
  NSStatusItem *statusItem;
  StartAtLoginController *loginController;
  BOOL running;
  long updateInterval;
  Cpuinfo cpuinfo;
  dispatch_group_t group;
  CpuinfoImage *image;
}

@synthesize window;
@synthesize statusMenu;
@synthesize mi_updateInterval;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self begin];
}

-(void)awakeFromNib{
  //
  image = [[CpuinfoImage alloc] init];
  [image setCpuinfo:&cpuinfo];

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
  updateInterval = [defaults integerForKey:@"updateInterval"];
  self.showImage = [defaults boolForKey:@"showImage"];
  self.showText = [defaults boolForKey:@"showText"];
  self.showCoresIndividually = [defaults boolForKey:@"showCoresIndividually"];
  image.imageEnabled = self.showImage;
  image.textEnabled = self.showText;
  image.multiCoreEnabled = self.showCoresIndividually;
  cpuinfo.setMultiCoreEnabled(self.showCoresIndividually);
  
  // updateInterval
  for(int i=0;i<mi_updateInterval.submenu.itemArray.count;i++) {
    NSMenuItem *mi = mi_updateInterval.submenu.itemArray[i];
    mi.state = mi.tag == updateInterval ? NSOnState : NSOffState;
  }
  //
  NSString * identifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".helper"];
  loginController = [[StartAtLoginController alloc] initWithIdentifier:identifier];
  self.startAtLogin = [loginController startAtLogin];
  //
  [self updateView];
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
  updateInterval = mi_selected.tag;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithInteger:updateInterval]
               forKey:@"updateInterval"];
}

- (IBAction)updateShowImage:(id)sender {
  BOOL showImage = !self.showImage;
  image.imageEnabled = showImage;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:showImage forKey:@"showImage"];
  //
  [self updateView];
}

- (IBAction)updateShowText:(id)sender {
  BOOL showText = !self.showText;
  image.textEnabled = showText;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:showText forKey:@"showText"];
  //
  [self updateView];
}

- (IBAction)updateCoresIndividually:(id)sender {
  BOOL showCoresIndividually = !self.showCoresIndividually;
  image.multiCoreEnabled = showCoresIndividually;
  cpuinfo.setMultiCoreEnabled(showCoresIndividually);
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:showCoresIndividually forKey:@"showCoresIndividually"];
  //
  [self updateView];
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
  @autoreleasepool {
    while(running) {
      double interval = MAX((double)updateInterval/1000.0, 0.1);
      [NSThread sleepForTimeInterval:interval];
      
      cpuinfo.update();
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [self updateView];
      });
    }
  }
}

-(void) updateView {
  [image update];
  statusItem.image = image;
}

@end


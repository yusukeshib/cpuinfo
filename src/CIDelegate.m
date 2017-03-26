#import "CIDelegate.h"

@implementation CIDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

-(void)awakeFromNib{
  statusItem = [[NSStatusBar systemStatusBar]
                 statusItemWithLength:NSVariableStatusItemLength];
  [statusItem setMenu:statusMenu];
  [statusItem setTitle:@""];
  [statusItem setHighlightMode:YES];
  //
  updater = [CIUpdater runWithStatusItem:statusItem];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  long updateInterval = [defaults integerForKey:@"updateInterval"];
  if(updateInterval < 100) updateInterval = 500;
  updater.updateInterval = updateInterval;
  for(int i=0;i<mi_updateInterval.submenu.itemArray.count;i++) {
    NSMenuItem *mi = mi_updateInterval.submenu.itemArray[i];
    mi.state = mi.tag == updateInterval ? NSOnState : NSOffState;
  }
  //
  long imageSize = [defaults integerForKey:@"imageSize"];
  if(imageSize <= 0) imageSize = 8;
  updater.imageSize = imageSize;
  for(int i=0;i<mi_imageSize.submenu.itemArray.count;i++) {
    NSMenuItem *mi = mi_imageSize.submenu.itemArray[i];
    mi.state = mi.tag == imageSize ? NSOnState : NSOffState;
  }
  //
  [statusItem setLength:(updater.imageSize==0 ? NSSquareStatusItemLength : NSVariableStatusItemLength)];
	//
	NSString * identifier = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".helper"];
	loginController = [[StartAtLoginController alloc] initWithIdentifier:identifier];
	mi_startAtLogin.state = [loginController startAtLogin] ? NSOnState : NSOffState;
}

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  return NSTerminateNow;
}

- (IBAction)setUpdateInterval:(id)sender {
  NSMenuItem *mi_selected = sender;
  mi_selected.state = NSOnState;
  for(int i=0;i<mi_selected.menu.itemArray.count;i++) {
    NSMenuItem *mi = mi_selected.menu.itemArray[i];
    if(mi != mi_selected) mi.state = NSOffState;
  }
  updater.updateInterval = mi_selected.tag;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithInteger:updater.updateInterval] forKey:@"updateInterval"];
  [defaults synchronize];
}

- (IBAction)setImageMode:(id)sender {
  NSMenuItem *mi_selected = sender;
  mi_selected.state = NSOnState;
  for(int i=0;i<mi_selected.menu.itemArray.count;i++) {
    NSMenuItem *mi = mi_selected.menu.itemArray[i];
    if(mi != mi_selected) mi.state = NSOffState;
  }
  updater.imageSize = mi_selected.tag;
  //
  [statusItem setLength:(updater.imageSize==0 ? NSSquareStatusItemLength : NSVariableStatusItemLength)];
  //
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithInteger:updater.imageSize] forKey:@"imageSize"];
  [defaults synchronize];
}

- (IBAction)setStartAtLogin:(id)sender {
  NSMenuItem *mi = sender;
  loginController.startAtLogin = (mi.state == NSOffState);
	mi_startAtLogin.state = [loginController startAtLogin] ? NSOnState : NSOffState;
}

- (IBAction)launchActivityMonitoy:(id)sender {
  [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.ActivityMonitor"
                                                       options:NSWorkspaceLaunchDefault 
                                additionalEventParamDescriptor:nil 
                                              launchIdentifier:nil];
}

@end

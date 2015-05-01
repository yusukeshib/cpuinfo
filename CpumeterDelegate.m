#import "CpumeterDelegate.h"

@implementation CpumeterDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Insert code here to initialize your application 
}
-(void)awakeFromNib{
  statusItem = [[[NSStatusBar systemStatusBar]
                 statusItemWithLength:NSVariableStatusItemLength] retain];
  [statusItem setMenu:statusMenu];
  [statusItem setTitle:@"-%"];
  [statusItem setHighlightMode:YES];
  //
  updater = [CpumeterUpdater runWithStatusItem:statusItem];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  double updateInterval = [defaults doubleForKey:@"updateInterval"];
  if(updateInterval > 0) [self _setUpdateInterval:updateInterval];
  [self _setTextMode:[defaults boolForKey:@"textMode"]];
  NSString * appPath = [[NSBundle mainBundle] bundlePath];
  LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
  [self _setStartAtLogin:[self loginItemExistsWithLoginItemReference:loginItems ForPath:appPath]];
  CFRelease(loginItems);
}
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  [updater release];
  return NSTerminateNow;
}
- (IBAction)setUpdateInterval100:(id)sender {
  [self _setUpdateInterval:0.1];
}
- (IBAction)setUpdateInterval200:(id)sender {
  [self _setUpdateInterval:0.2];
}
- (IBAction)setUpdateInterval500:(id)sender {
  [self _setUpdateInterval:0.5];
}
- (IBAction)setUpdateInterval1000:(id)sender {
  [self _setUpdateInterval:1.0];
}

- (void)_setUpdateInterval:(double)val {
  mi_ui100.state = NSOffState;
  mi_ui200.state = NSOffState;
  mi_ui500.state = NSOffState;
  mi_ui1000.state = NSOffState;
  updater.updateInterval = val;
  if(val == 0.1) mi_ui100.state = NSOnState;
  else if(val == 0.2) mi_ui200.state = NSOnState;
  else if(val == 0.5) mi_ui500.state = NSOnState;
  else if(val == 1.0) mi_ui1000.state = NSOnState;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithDouble:updater.updateInterval] forKey:@"updateInterval"];
}
- (IBAction)setImageMode:(id)sender {
  [self _setTextMode:NO];
}
- (IBAction)setTextMode:(id)sender {
  [self _setTextMode:YES];
}
- (void)_setTextMode:(BOOL)val {
  mi_mText.state = NSOffState;
  mi_mImage.state = NSOffState;
  updater.textMode = val;
  if(val == NO) mi_mImage.state = NSOnState;
  else mi_mText.state = NSOnState;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithBool:updater.textMode] forKey:@"textMode"];
}
- (IBAction)setStartAtLogin:(id)sender {
  NSMenuItem *mi = sender;
  [self _setStartAtLogin:(mi.state == NSOffState)];
}
- (void)_setStartAtLogin:(BOOL)val {
  NSString * appPath = [[NSBundle mainBundle] bundlePath];
  LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
  if(val) {
    mi_startAtLogin.state = NSOnState;
    [self enableLoginItemWithLoginItemsReference:loginItems ForPath:appPath];
  } else {
    mi_startAtLogin.state = NSOffState;
    [self disableLoginItemWithLoginItemsReference:loginItems ForPath:appPath];
  }
  CFRelease(loginItems);
}
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath {
  // We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
  CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath];
  LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
  if (item)
    CFRelease(item);
}

- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath {
  UInt32 seedValue;
  CFURLRef thePath = NULL;
  // We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
  // and pop it in an array so we can iterate through it to find our item.
  CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
  for (id item in (NSArray *)loginItemsArray) {
    LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
    if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
      if ([[(NSURL *)thePath path] hasPrefix:appPath]) {
        LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
      }
      // Docs for LSSharedFileListItemResolve say we're responsible
      // for releasing the CFURLRef that is returned
      if (thePath != NULL) CFRelease(thePath);
    }
  }
  if (loginItemsArray != NULL) CFRelease(loginItemsArray);
}

- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(NSString *)appPath {
  BOOL found = NO;  
  UInt32 seedValue;
  CFURLRef thePath = NULL;
  
  // We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
  // and pop it in an array so we can iterate through it to find our item.
  CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
  for (id item in (NSArray *)loginItemsArray) {    
    LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
    if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
      if ([[(NSURL *)thePath path] hasPrefix:appPath]) {
        found = YES;
        break;
      }
      // Docs for LSSharedFileListItemResolve say we're responsible
      // for releasing the CFURLRef that is returned
      if (thePath != NULL) CFRelease(thePath);
    }
  }
  if (loginItemsArray != NULL) CFRelease(loginItemsArray);
  
  return found;
}

- (IBAction)launchActivityMonitoy:(id)sender {
  [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.ActivityMonitor"
                                                       options:NSWorkspaceLaunchDefault 
                                additionalEventParamDescriptor:nil 
                                              launchIdentifier:nil];
}

@end

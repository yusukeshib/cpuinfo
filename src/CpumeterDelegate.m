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
  [statusItem setTitle:@""];
  [statusItem setHighlightMode:YES];
  //
  updater = [CpumeterUpdater runWithStatusItem:statusItem];
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

  NSString * appPath = [[NSBundle mainBundle] bundlePath];
  LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
  [self _setStartAtLogin:[self loginItemExistsWithLoginItemReference:loginItems ForPath:appPath]];
  CFRelease(loginItems);
}
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  [updater release];
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

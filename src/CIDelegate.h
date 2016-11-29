#import <Cocoa/Cocoa.h>
#import "CIUpdater.h"

@interface CIDelegate : NSObject <NSApplicationDelegate> {
  NSWindow *window;
  IBOutlet NSMenu *statusMenu;
  IBOutlet NSMenuItem *mi_startAtLogin, *mi_updateInterval, *mi_imageSize;
  NSStatusItem *statusItem;
  CIUpdater *updater;
}
- (IBAction)setUpdateInterval:(id)sender;
- (IBAction)setImageMode:(id)sender;
- (IBAction)setStartAtLogin:(id)sender;
- (void)_setStartAtLogin:(BOOL)val;

- (IBAction)launchActivityMonitoy:(id)sender;

- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(NSString *)appPath;
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;

@property IBOutlet NSWindow *window;

@end

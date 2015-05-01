#import <Cocoa/Cocoa.h>
#import "CpumeterUpdater.h"

@interface CpumeterDelegate : NSObject <NSApplicationDelegate> {
  NSWindow *window;
  IBOutlet NSMenu *statusMenu;
  IBOutlet NSMenuItem *mi_ui100, *mi_ui200, *mi_ui500, *mi_ui1000, *mi_mImage, *mi_mText, *mi_startAtLogin;
  NSStatusItem *statusItem;
  CpumeterUpdater *updater;
}
- (IBAction)setUpdateInterval100:(id)sender;
- (IBAction)setUpdateInterval200:(id)sender;
- (IBAction)setUpdateInterval500:(id)sender;
- (IBAction)setUpdateInterval1000:(id)sender;
- (void)_setUpdateInterval:(double)val;
- (IBAction)setImageMode:(id)sender;
- (IBAction)setTextMode:(id)sender;
- (void)_setTextMode:(BOOL)val;
- (IBAction)setStartAtLogin:(id)sender;
- (void)_setStartAtLogin:(BOOL)val;

- (IBAction)launchActivityMonitoy:(id)sender;

- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(NSString *)appPath;
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;

@property (assign) IBOutlet NSWindow *window;

@end

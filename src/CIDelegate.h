#import <Cocoa/Cocoa.h>
#import "CIUpdater.h"
#import "StartAtLoginController.h"

@interface CIDelegate : NSObject <NSApplicationDelegate> {
  NSWindow *window;
  IBOutlet NSMenu *statusMenu;
  IBOutlet NSMenuItem *mi_startAtLogin, *mi_updateInterval, *mi_imageSize;
  NSStatusItem *statusItem;
  CIUpdater *updater;
	StartAtLoginController *loginController;
}
- (IBAction)setUpdateInterval:(id)sender;
- (IBAction)setImageMode:(id)sender;
- (IBAction)setStartAtLogin:(id)sender;

- (IBAction)launchActivityMonitoy:(id)sender;

@property IBOutlet NSWindow *window;

@end

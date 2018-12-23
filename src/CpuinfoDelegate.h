#import <Cocoa/Cocoa.h>
#import "StartAtLoginController.h"

@interface CpuinfoDelegate : NSObject <NSApplicationDelegate> {
}

- (IBAction)updateUpdateInterval:(id)sender;
- (IBAction)updateShowImage:(id)sender;
- (IBAction)updateShowText:(id)sender;
- (IBAction)updateStartAtLogin:(id)sender;
- (IBAction)launchActivityMonitor:(id)sender;

@property IBOutlet NSWindow *window;
@property IBOutlet NSMenu *statusMenu;
@property IBOutlet NSMenuItem *mi_updateInterval;
@property BOOL startAtLogin;
@property BOOL showImage;
@property BOOL showText;
@property long updateInterval;

@end

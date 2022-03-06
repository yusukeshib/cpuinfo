#import <Cocoa/Cocoa.h>
#import "CpuinfoImage.h"
#import "StartAtLoginController.h"

@interface CpuinfoDelegate : NSObject <NSApplicationDelegate> {
}

- (IBAction)updateUpdateInterval:(id)sender;
- (IBAction)updateTheme:(id)sender;
- (IBAction)updateShowImage:(id)sender;
- (IBAction)updateShowText:(id)sender;
- (IBAction)updateStartAtLogin:(id)sender;
- (IBAction)launchActivityMonitor:(id)sender;

@property IBOutlet NSWindow *window;
@property IBOutlet NSMenu *statusMenu;
@property IBOutlet NSMenuItem *mi_updateInterval;
@property IBOutlet NSMenuItem *mi_theme;
@property IBOutlet NSMenuItem *mi_viewMode;
@property BOOL startAtLogin;
@property BOOL showCoresIndividually;
@property BOOL showImage;
@property BOOL showText;

@end

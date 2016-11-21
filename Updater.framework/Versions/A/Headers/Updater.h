#import <Cocoa/Cocoa.h>

FOUNDATION_EXPORT double updaterVersionNumber;
FOUNDATION_EXPORT const unsigned char updaterVersionString[];

@interface Updater : NSObject

+ (void)Initialize;

@end

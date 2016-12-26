// Copyright (c) 2011 Alex Zielenski
// Copyright (c) 2012 Travis Tilley
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense,  and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "StartAtLoginController.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation StartAtLoginController

@synthesize identifier = _identifier;

#if !__has_feature(objc_arc)
- (void)dealloc {
  self.identifier = nil;
  [super dealloc];
}
#endif

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
  BOOL automatic = NO;

  if ([theKey isEqualToString:@"startAtLogin"]) {
    automatic = NO;
  } else if ([theKey isEqualToString:@"enabled"]) {
    automatic = NO;
  } else {
    automatic=[super automaticallyNotifiesObserversForKey:theKey];
  }

  return automatic;
}

-(id)initWithIdentifier:(NSString*)identifier {
  self = [self init];
  if(self) {
    self.identifier = identifier;
  }
  NSDictionary* environ = [[NSProcessInfo processInfo] environment];
  _sandboxed = (nil != [environ objectForKey:@"APP_SANDBOX_CONTAINER_ID"]);
	NSLog(@"sandboxed: %i", _sandboxed);
  return self;
}

-(void)setIdentifier:(NSString *)identifier {
  _identifier = identifier;
  [self startAtLogin];
#if !defined(NDEBUG)
  NSLog(@"Launcher '%@' %@ configured to start at login",
      self.identifier, (_enabled ? @"is" : @"is not"));
#endif
}

- (BOOL)startAtLogin {
  if (!_identifier)
    return NO;

	BOOL isEnabled  = NO;

  if(!_sandboxed) {
    UInt32 seedValue;
    CFURLRef thePath = NULL;

    NSString * appPath = [[NSBundle mainBundle] bundlePath];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    // We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
    // and pop it in an array so we can iterate through it to find our item.
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
    for(id item in (__bridge NSArray *)loginItemsArray) {
      LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
      if(LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
        if([[(__bridge NSURL *)thePath path] hasPrefix:appPath]) {
          isEnabled = YES;
          break;
        }
        // Docs for LSSharedFileListItemResolve say we're responsible
        // for releasing the CFURLRef that is returned
        if(thePath != NULL) CFRelease(thePath);
      }
    }
    if(loginItemsArray != NULL) CFRelease(loginItemsArray);

 } else {
		// the easy and sane method (SMJobCopyDictionary) can pose problems when sandboxed. -_-
		CFArrayRef cfJobDicts = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
		NSArray* jobDicts = CFBridgingRelease(cfJobDicts);

		if (jobDicts && [jobDicts count] > 0) {
			for (NSDictionary* job in jobDicts) {
				NSString *label = [job objectForKey:@"Label"];
				if ([_identifier isEqualToString:label]) {
					isEnabled = [[job objectForKey:@"OnDemand"] boolValue];
					NSLog(@"%@:%i", label, isEnabled);
					break;
				}
			}
		}
 }

	if (isEnabled != _enabled) {
		[self willChangeValueForKey:@"enabled"];
		_enabled = isEnabled;
		[self didChangeValueForKey:@"enabled"];
	}

  return isEnabled;
}

- (void)setStartAtLogin:(BOOL)flag {
  if (!_identifier)
    return;

  [self willChangeValueForKey:@"startAtLogin"];

	if(!_sandboxed) {

		NSString * appPath = [[NSBundle mainBundle] bundlePath];
		LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
		UInt32 seedValue;

		// enable
		if(flag) {

			// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
			CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
			LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
			if (item) CFRelease(item);

		// disable
		} else {

			CFURLRef thePath = NULL;
			// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
			// and pop it in an array so we can iterate through it to find our item.
			CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
			for (id item in (__bridge NSArray *)loginItemsArray) {
				LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
				if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
					if ([[(__bridge NSURL *)thePath path] hasPrefix:appPath]) {
						LSSharedFileListItemRemove(loginItems, itemRef); // Deleting the item
					}
					// Docs for LSSharedFileListItemResolve say we're responsible
					// for releasing the CFURLRef that is returned
					if (thePath != NULL) CFRelease(thePath);
				}
			}
			if (loginItemsArray != NULL) CFRelease(loginItemsArray);
		}
		[self willChangeValueForKey:@"enabled"];
		_enabled = YES;
		[self didChangeValueForKey:@"enabled"];

		return;
	}


  if (!SMLoginItemSetEnabled((__bridge CFStringRef)_identifier, (flag) ? true : false)) {
    NSLog(@"SMLoginItemSetEnabled failed!");

    [self willChangeValueForKey:@"enabled"];
    _enabled = NO;
    [self didChangeValueForKey:@"enabled"];
  } else {
    [self willChangeValueForKey:@"enabled"];
    _enabled = YES;
    [self didChangeValueForKey:@"enabled"];
  }

  [self didChangeValueForKey:@"startAtLogin"];
}

- (BOOL)enabled
{
  return _enabled;
}

- (void)setEnabled:(BOOL)enabled
{
  [self setStartAtLogin:enabled];
}

@end

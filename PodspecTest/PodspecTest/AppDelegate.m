#import "AppDelegate.h"

@import ZDCSyncableObjC;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	ZDCDictionary<NSString*, NSString*> *dict = [[ZDCDictionary alloc] init];
	dict[@"foo"] = @"bar";
	
	NSLog(@"dict: %@", dict.rawDictionary);
}

@end

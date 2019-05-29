/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "AppDelegate.h"

// You can use a module-style import:
@import ZDCSyncableObjC;

// Or you can use a classic-style import:
//#import <ZDCSyncableObjC/ZDCSyncableObjC.h>

/**
 * How to use ZDCSyncable project in your app:
 */
@interface FooBar: ZDCRecord // < Just extend ZDCRecord

@property (nonatomic, copy, readwrite) NSString *someString; // add your properties as usual
@property (nonatomic, readwrite) NSUInteger someInt;         // and that's it !

@end

@implementation FooBar
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * How to use ZDCSyncable project in your app:
 */
@interface FooBuzz: ZDCRecord // < Just extend ZDCRecord
	
@property (nonatomic, readwrite) NSUInteger someInt; // add your properties as usual
@property (nonatomic, readonly) ZDCDictionary *dict; // or use smart containers

@end

@implementation FooBuzz

@synthesize someInt = someInt;
@synthesize dict = dict;
- (instancetype)init
{
	if ((self = [super init])) {
		dict = [[ZDCDictionary alloc] init];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	FooBuzz *copy = [[FooBuzz alloc] init];
	copy->someInt = someInt;
	copy->dict = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	
	return copy;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[self demo1];
	NSLog(@"-----------------------------------");
	[self demo2];
	NSLog(@"-----------------------------------");
	[self demo3];
}

- (void)demo1
{
	FooBar *foobar = [[FooBar alloc] init];
	foobar.someString = @"init";
	foobar.someInt = 1;
	[foobar clearChangeTracking]; // starting point
	
	foobar.someString = @"modified";
	foobar.someInt = 2;
	
	NSDictionary *undo = [foobar changeset]; // changes since starting point
	
	NSDictionary *redo = [foobar undo:undo error:nil]; // revert to starting point
	
	// Current state:
	// foobar.someString == "init"
	// foobar.someInt == 1
	
	NSLog(@"Post undo:");
	NSLog(@"foobar.someString: %@", foobar.someString);
	NSLog(@"foobar.someInt: %d", (int)foobar.someInt);
	
	[foobar undo:redo error:nil]; // redo == (undo an undo)
	
	// Current state:
	// foobar.someString == "modified"
	// foobar.someInt == 2
	
	NSLog(@"Post redo:");
	NSLog(@"foobar.someString: %@", foobar.someString);
	NSLog(@"foobar.someInt: %d", (int)foobar.someInt);
}

- (void)demo2
{
	FooBuzz *foobuzz = [[FooBuzz alloc] init];
	foobuzz.someInt = 1;
	foobuzz.dict[@"foo"] = @"buzz";
	[foobuzz clearChangeTracking]; // starting point
	
	foobuzz.someInt = 2;
	foobuzz.dict[@"foo"] = @"modified";
	
	NSDictionary *undo = [foobuzz changeset]; // changes since starting point
	
	NSDictionary *redo = [foobuzz undo:undo error:nil]; // revert to starting point
		
	// Current state:
	// foobuzz.someInt == 1
	// foobuzz.dict["foo"] == "buzz"
	
	NSLog(@"Post undo:");
	NSLog(@"foobuzz.someInt: %d", (int)foobuzz.someInt);
	NSLog(@"foobuzz.dict['foo']: %@", foobuzz.dict[@"foo"]);
		
	[foobuzz undo:redo error:nil]; // redo == (undo an undo)
		
	// Current state:
	// foobuzz.someInt == 2
	// foobuzz.dict["foo"] == "modified"
	
	NSLog(@"Post redo:");
	NSLog(@"foobuzz.someInt: %d", (int)foobuzz.someInt);
	NSLog(@"foobuzz.dict['foo']: %@", foobuzz.dict[@"foo"]);
}

- (void)demo3
{
	FooBuzz *local = [[FooBuzz alloc] init];
	local.someInt = 1;
	local.dict[@"foo"] = @"buzz";
	[local clearChangeTracking]; // starting point
	
	FooBuzz *cloud = [local copy];
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	
	// local modifications
	
	local.someInt = 2;
	local.dict[@"foo"] = @"modified";
	
	[changesets addObject:[local changeset]]; // pending local changes
	
	// cloud modifications
	
	cloud.dict[@"duck"]  = @"quack";
	
	// Now merge cloud version into local.
	// Automatically take into account our pending local changes.
	
	[local mergeCloudVersion:cloud withPendingChangesets:changesets error:nil];
		
	// Merged state:
	// local.someInt == 2
	// local.dict["foo"] == "modifed"
	// local.dict["duck"] == "quack"
	
	NSLog(@"Post redo:");
	NSLog(@"local.someInt: %d", (int)local.someInt);
	NSLog(@"local.dict['foo']: %@", local.dict[@"foo"]);
	NSLog(@"local.dict['duck']: %@", local.dict[@"duck"]);
}

@end

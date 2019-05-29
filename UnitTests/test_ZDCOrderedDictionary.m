/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <XCTest/XCTest.h>
#import "ZDCOrderedDictionary.h"

@interface test_ZDCOrderedDictionary : XCTestCase
@end

@implementation test_ZDCOrderedDictionary

- (NSString *)randomLetters:(NSUInteger)length
{
	NSString *alphabet = @"abcdefghijklmnopqrstuvwxyz";
	NSUInteger alphabetLength = [alphabet length];
	
	NSMutableString *result = [NSMutableString stringWithCapacity:length];
	
	NSUInteger i;
	for (i = 0; i < length; i++)
	{
		unichar c = [alphabet characterAtIndex:(NSUInteger)arc4random_uniform((uint32_t)alphabetLength)];
		
		[result appendFormat:@"%C", c];
	}
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Subclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_subclass
{
	// Basic YES/NO change tracking.
	//
	// If we make changes to the dict, does [dict hasChanges] reflect those changes ?
	// i.e. make sure we didn't screw up the subclass functionality.
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	XCTAssert([dict hasChanges] == YES);
	[dict clearChangeTracking];
	XCTAssert([dict hasChanges] == NO);
	
	dict[@"cow"] = @"mooooooooo";
	
	XCTAssert([dict hasChanges] == YES);
	[dict clearChangeTracking];
	XCTAssert([dict hasChanges] == NO);
	
	[dict insertObject:@"bark" forKey:@"dog" atIndex:1];
	
	XCTAssert([dict hasChanges] == YES);
	[dict clearChangeTracking];
	XCTAssert([dict hasChanges] == NO);
	
	[dict moveObjectAtIndex:0 toIndex:2];
	
	XCTAssert([dict hasChanges] == YES);
	[dict clearChangeTracking];
	XCTAssert([dict hasChanges] == NO);
	
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"dog"], @"[dict keyAtIndex:0] = %@", [dict keyAtIndex:0]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"duck"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"cow"]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Undo: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_basic_1
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Can we undo/redo basic `setObject:forKey:` functionality (for newly inserted items) ?
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	// Empty dictionary will be starting state
	//
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	XCTAssert(dict.count == 2);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil];
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil];
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_basic_2
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Can we undo/redo basic `setObject:forKey:` functionality (for updated items) ?
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = @"mooooooo";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil];
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil];
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_basic_3
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Can we undo/redo basic `removeObjectForKey:` functionality ?
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = nil;
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil];
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil];
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_basic_4
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Can we undo/redo basic `moveObjectAtIndex:toIndex:` functionality ?
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:0 toIndex:1];
	
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"duck"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"cow"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil];
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil];
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Combo: add + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_add_add
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Add + Add
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"dog"] = @"bark";
	dict[@"cat"] = @"meow";
	
	XCTAssert(dict.count == 4);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_add_remove
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Add + Remove
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"dog"] = @"bark";
	dict[@"cow"] = nil;
	
	XCTAssert(dict.count == 2);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_add_insert
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Add + Insert
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"dog"] = @"bark";
	[dict insertObject:@"meow" forKey:@"cat" atIndex:0];
	
	XCTAssert(dict.count == 4);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"cat"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"cow"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"duck"]);
	XCTAssert([[dict keyAtIndex:3] isEqualToString:@"dog"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_add_move
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Add + Move
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"dog"] = @"bark";
	[dict moveObjectAtIndex:0 toIndex:1];
	
	XCTAssert(dict.count == 3);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Combo: remove + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_remove_add
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Remove + Add
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = nil;
	dict[@"dog"] = @"bark";
	
	XCTAssert(dict.count == 2);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_remove_remove
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Remove + Remove
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = nil;
	dict[@"duck"] = nil;
	
	XCTAssert(dict.count == 0);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_remove_insert
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Remove + Insert
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = nil;
	[dict insertObject:@"bark" forKey:@"dog" atIndex:0];
	
	XCTAssert(dict.count == 2);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"dog"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_remove_move
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Remove + Move
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	dict[@"dog"] = @"bark";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = nil;
	[dict moveObjectAtIndex:0 toIndex:1];
	
	XCTAssert(dict.count == 2);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"dog"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Combo: insert + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_insert_add
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Add
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict insertObject:@"bark" forKey:@"dog" atIndex:1];
	dict[@"cat"] = @"meow";
	
	XCTAssert(dict.count == 4);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"cow"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"dog"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"duck"]);
	XCTAssert([[dict keyAtIndex:3] isEqualToString:@"cat"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_insert_remove
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Remove
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict insertObject:@"bark" forKey:@"dog" atIndex:1];
	dict[@"cow"] = nil;
	
	XCTAssert(dict.count == 2);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"dog"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_insert_insert
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Insert
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict insertObject:@"bark" forKey:@"dog" atIndex:1];
	[dict insertObject:@"meow" forKey:@"cat" atIndex:1];
	
	XCTAssert(dict.count == 4);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"cow"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"cat"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"dog"]);
	XCTAssert([[dict keyAtIndex:3] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_insert_move_a
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Move
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict insertObject:@"bark" forKey:@"dog" atIndex:1];
	[dict moveObjectAtIndex:2 toIndex:0];
	
	XCTAssert(dict.count == 3);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"duck"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"cow"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"dog"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_insert_move_b
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Move
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict insertObject:@"bark" forKey:@"dog" atIndex:1];
	[dict moveObjectAtIndex:0 toIndex:2];
	
	XCTAssert(dict.count == 3);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"dog"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"duck"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"cow"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Combo: move + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_move_add
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Add
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:0 toIndex:1];
	dict[@"dog"] = @"bark";
	
	XCTAssert(dict.count == 3);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"duck"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"cow"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"dog"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_move_remove
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Remove
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:0 toIndex:1];
	dict[@"cow"] = nil;
	
	XCTAssert(dict.count == 1);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_move_insert
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Insert
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:0 toIndex:1];
	[dict insertObject:@"bark" forKey:@"dog" atIndex:1];
	
	XCTAssert(dict.count == 3);
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"duck"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"dog"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"cow"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_move_move_a
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Move
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:0 toIndex:1];
	[dict moveObjectAtIndex:0 toIndex:1];
	
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"cow"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_move_move_b
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Move
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	dict[@"dog"] = @"bark";
	dict[@"cat"] = @"meow";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:1 toIndex:3];
	[dict moveObjectAtIndex:2 toIndex:0];
	
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"cat"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"cow"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"dog"]);
	XCTAssert([[dict keyAtIndex:3] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_move_move_c
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Move
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	dict[@"dog"] = @"bark";
	dict[@"cat"] = @"meow";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:0 toIndex:3];
	[dict moveObjectAtIndex:2 toIndex:1];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_move_move_d
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Move
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	dict[@"dog"] = @"bark";
	dict[@"cat"] = @"meow";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:0 toIndex:3];
	[dict moveObjectAtIndex:1 toIndex:2];
	
	XCTAssert([[dict keyAtIndex:0] isEqualToString:@"duck"]);
	XCTAssert([[dict keyAtIndex:1] isEqualToString:@"cat"]);
	XCTAssert([[dict keyAtIndex:2] isEqualToString:@"dog"]);
	XCTAssert([[dict keyAtIndex:3] isEqualToString:@"cow"]);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Previous Failures
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_failure_1
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"rkij"] = @"";
	dict[@"ihns"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"jtyi"] = @"";
	[dict moveObjectAtIndex:1 toIndex:0];
	[dict moveObjectAtIndex:2 toIndex:0];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_failure_2
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"tjwi"] = @"";
	dict[@"nwgk"] = @"";
	dict[@"igaz"] = @"";
	dict[@"gmmv"] = @"";
	dict[@"lefk"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"leyp"] = @"";
	[dict moveObjectAtIndex:3 toIndex:5];
	dict[@"uwka"] = @"";
	[dict moveObjectAtIndex:1 toIndex:6];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_failure_3
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"tnjb"] = @"";
	dict[@"xcyu"] = @"";
	dict[@"gkmq"] = @"";
	dict[@"hnkg"] = @"";
	dict[@"paxy"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:2 toIndex:4];
	dict[@"xsny"] = @"";
	dict[@"kzzh"] = @"";
	[dict moveObjectAtIndex:5 toIndex:6];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_failure_4
{
/*
	setObject:withKey: ezgdvhluwufoirdxeonxcfexfkmfekuj (idx=5)
	setObject:withKey: muuavorbtsospgzencffbyclclvekftw (idx=6)
	setObject:withKey: nfjtygfdyvtgmxuaqhgqdgseffyldvtw (idx=7)
	moveObjectAtIndex:7 toIndex:6
	*** Assertion failure in -[ZDCOrderedDictionary checkeDeletedIndexes:], /.../ZDCOrderedDictionary.m:798
	(lldb) po dict_a.rawOrder
	<__NSFrozenArrayM 0x600000c65f50>(
		glsrobwptrijlmforygkdveybusvekxy,
		sefoaziptrgeqiccbuwyadohuzdmfcxb,
		vkcabihdmytgghklcbieroydbvjpyuaf,
		izlenjiqrnvhwyywxclvsgjxqshwfpxy,
		pggkmgvrsprkpzusljsrcoituodwczco
	)
*/
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"glsr"] = @"";
	dict[@"sefo"] = @"";
	dict[@"vkca"] = @"";
	dict[@"izle"] = @"";
	dict[@"pggk"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"ezgd"] = @"";
	dict[@"muua"] = @"";
	dict[@"nfjt"] = @"";
	[dict moveObjectAtIndex:7 toIndex:6];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_failure_5
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"tvma"] = @"";
	dict[@"sgkp"] = @"";
	dict[@"erum"] = @"";
	dict[@"pkzi"] = @"";
	dict[@"ytfx"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"tzrx"] = @"";
	dict[@"ujvd"] = @"";
	dict[@"pmnv"] = @"";
	[dict moveObjectAtIndex:2 toIndex:7];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_failure_6
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"ldnw"] = @"";
	dict[@"llxg"] = @"";
	dict[@"ddbx"] = @"";
	dict[@"axxj"] = @"";
	dict[@"vicl"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:2 toIndex:4];
	[dict removeObjectAtIndex:2];
	[dict moveObjectAtIndex:0 toIndex:3];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_failure_7
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"yqbe"] = @"";
	dict[@"wznq"] = @"";
	dict[@"riff"] = @"";
	dict[@"xkvu"] = @"";
	dict[@"qqlk"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"hqvm"] = @"";
	dict[@"bjqv"] = @"";
	[dict moveObjectAtIndex:5 toIndex:3];
	[dict moveObjectAtIndex:6 toIndex:2];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_failure_8
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"ihba"] = @"";
	dict[@"iduf"] = @"";
	dict[@"yzgh"] = @"";
	dict[@"bcso"] = @"";
	dict[@"hdsv"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	[dict moveObjectAtIndex:3 toIndex:2];
	dict[@"oohq"] = @"";
	[dict moveObjectAtIndex:5 toIndex:0];
	[dict moveObjectAtIndex:4 toIndex:0];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_failure_9
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"oswt"] = @"";
	dict[@"bony"] = @"";
	dict[@"pxgf"] = @"";
	dict[@"bclp"] = @"";
	dict[@"zejw"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"hrtm"] = @"";
	[dict removeObjectAtIndex:4];
	[dict moveObjectAtIndex:1 toIndex:4];
	[dict removeObjectAtIndex:4];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_undo_failure_10
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"ydlj"] = @"";
	dict[@"oruh"] = @"";
	dict[@"iaye"] = @"";
	dict[@"iunc"] = @"";
	dict[@"scvk"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"ggek"] = @"";
	[dict moveObjectAtIndex:3 toIndex:5];
	[dict moveObjectAtIndex:3 toIndex:1];
	[dict removeObjectAtIndex:4];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil]; // a -> b
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Fuzz: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_add
{
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [0 - 10)
		{
			NSUInteger startCount = (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
			
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now add a random number of object [1 - 10)
		{
			NSUInteger addCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)9);
			
			for (NSUInteger i = 0; i < addCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
	}}
}

- (void)test_undo_fuzz_remove
{
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now remove a random number of object [1 - 15)
		{
			NSUInteger removeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)14);
			
			for (NSUInteger i = 0; i < removeCount; i++)
			{
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				[dict removeObjectAtIndex:idx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
	}}
}

- (void)test_undo_fuzz_insert
{
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [0 - 10)
		{
			NSUInteger startCount = (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now insert a random number of object [1 - 10)
		{
			NSUInteger insertCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)9);
			
			for (NSUInteger i = 0; i < insertCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				[dict insertObject:@"" forKey:key atIndex:idx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
	}}
}

- (void)test_undo_fuzz_move
{
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of moves: [1 - 30)
		
		NSUInteger moveCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < moveCount; i++)
		{
			NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
			NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
			
			[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Fuzz: Combo: add + x
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_add_remove
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			if (arc4random_uniform((uint32_t)2) == 0)
			{
				// Add an item
				
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
				}
				dict[key] = @"";
			}
			else
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				[dict removeObjectAtIndex:idx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_undo_fuzz_add_insert
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			if (arc4random_uniform((uint32_t)2) == 0)
			{
				// Add an item
				
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
				}
				dict[key] = @"";
			}
			else
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[dict insertObject:@"" forKey:key atIndex:idx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_undo_fuzz_add_move
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			if (arc4random_uniform((uint32_t)2) == 0)
			{
				// Add an item
				
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
				}
				dict[key] = @"";
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Fuzz: Combo: remove + x
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_remove_insert
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			if (arc4random_uniform((uint32_t)2) == 0)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				[dict removeObjectAtIndex:idx];
			}
			else
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[dict insertObject:@"" forKey:key atIndex:idx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_undo_fuzz_remove_move
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			if (arc4random_uniform((uint32_t)2) == 0)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				[dict removeObjectAtIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Fuzz: Combo: insert + x
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_insert_move
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			if (arc4random_uniform((uint32_t)2) == 0)
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[dict insertObject:@"" forKey:key atIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Fuzz: Triplets
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_add_remove_insert
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			uint32_t random = arc4random_uniform((uint32_t)3);
			
			if (random == 0)
			{
				// Add an item
				
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
				}
				dict[key] = @"";
			}
			else if (random == 1)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				[dict removeObjectAtIndex:idx];
			}
			else
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[dict insertObject:@"" forKey:key atIndex:idx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_undo_fuzz_add_remove_move
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			uint32_t random = arc4random_uniform((uint32_t)3);
			
			if (random == 0)
			{
				// Add an item
				
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
				}
				dict[key] = @"";
			}
			else if (random == 1)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				[dict removeObjectAtIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_undo_fuzz_add_insert_move
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			uint32_t random = arc4random_uniform((uint32_t)3);
			
			if (random == 0)
			{
				// Add an item
				
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
				}
				dict[key] = @"";
			}
			else if (random == 1)
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[dict insertObject:@"" forKey:key atIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_undo_fuzz_remove_insert_move
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			uint32_t random = arc4random_uniform((uint32_t)3);
			
			if (random == 0)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				[dict removeObjectAtIndex:idx];
			}
			else if (random == 1)
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[dict insertObject:@"" forKey:key atIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Fuzz: Everything
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_everything
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				NSString *value = [self randomLetters:4];
				
				dict[key] = value;
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			uint32_t random = arc4random_uniform((uint32_t)5);
			
			if (random == 0)
			{
				// Add an item
				
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
				}
				dict[key] = @"";
			}
			else if (random == 1)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				[dict removeObjectAtIndex:idx];
			}
			else if (random == 2)
			{
				// Modify an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				NSString *key = [dict keyAtIndex:idx];
				NSString *value = [self randomLetters:4];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"modify: key:%@ = %@", key, value);
				}
				dict[key] = value;
			}
			else if (random == 3)
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[dict insertObject:@"" forKey:key atIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Import: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_import_basic_1
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	// Empty dictionary will be starting state
	dict_a = [dict immutableCopy];
	
	{ // changeset: A
	
		dict[@"cow"] = @"moo";
		dict[@"duck"] = @"quack";
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	{ // changeset: B
	
		dict[@"dog"] = @"bark";
		dict[@"cat"] = @"meow";
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	
	dict_b = [dict immutableCopy];
	
	error = [dict importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
	
	NSDictionary *changeset_merged = [dict changeset];
	
	NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_import_basic_2
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	dict[@"dog"] = @"bark";
	dict[@"cat"] = @"meow";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	{ // changeset: A
		
		[dict removeObjectAtIndex:0];
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	{ // changeset: B
		
		[dict removeObjectAtIndex:0];
		[dict removeObjectAtIndex:0];
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	
	dict_b = [dict immutableCopy];
	
	error = [dict importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
	
	NSDictionary *changeset_merged = [dict changeset];
	
	NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_import_basic_3
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	{ // changeset: A
		
		[dict insertObject:@"quack" forKey:@"duck" atIndex:0];
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	{ // changeset: B
		
		[dict insertObject:@"bark" forKey:@"dog" atIndex:1];
		[dict insertObject:@"meow" forKey:@"cat" atIndex:0];
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	
	dict_b = [dict immutableCopy];
	
	error = [dict importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
	
	NSDictionary *changeset_merged = [dict changeset];
	
	NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_import_basic_4
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	dict[@"dog"] = @"bark";
	dict[@"cat"] = @"meow";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	{ // changeset: A
		
		[dict moveObjectAtIndex:2 toIndex:3]; // dog
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	{ // changeset: B
		
		[dict moveObjectAtIndex:2 toIndex:0]; // cat
		[dict moveObjectAtIndex:3 toIndex:2]; // dog
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	
	dict_b = [dict immutableCopy];
	
	error = [dict importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
	
	NSDictionary *changeset_merged = [dict changeset];
	
	NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Import: Failures
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_import_failure_1
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"bmfx"] = @"";
	dict[@"pwtg"] = @"";
	dict[@"czuy"] = @"";
	dict[@"cubs"] = @"";
	dict[@"xcwm"] = @"";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	{ // changeset: A
		
		dict[@"tsgh"] = @"";
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	{ // changeset: B
		
		[dict moveObjectAtIndex:5 toIndex:0];
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	
	dict_b = [dict immutableCopy];
	
	error = [dict importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
	
	NSDictionary *changeset_merged = [dict changeset];
	
	NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Import: Fuzz: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_import_fuzz_add
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Make a random number of changesets: [1 - 10)
		
		NSUInteger changesetCount;
		if (DEBUG_THIS_METHOD)
			changesetCount = 2;
		else
			changesetCount = 1 +(NSUInteger)arc4random_uniform((uint32_t)9);
		
		for (NSUInteger changesetIdx = 0; changesetIdx < changesetCount; changesetIdx++)
		{
			// Make a random number of changes: [1 - 30)
		
			NSUInteger changeCount;
			if (DEBUG_THIS_METHOD)
				changeCount = 4;
			else
				changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				// Add an item
		
				NSString *key = [self randomLetters:8];
		
				if (DEBUG_THIS_METHOD) {
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
				}
				dict[key] = @"";
			}
			
			[changesets addObject:([dict changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		dict_b = [dict immutableCopy];
		
		error = [dict importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		NSDictionary *changeset_merged = [dict changeset];
		
		NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_import_fuzz_remove
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 10;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Make a random number of changesets: [1 - 10)
		
		NSUInteger changesetCount;
		if (DEBUG_THIS_METHOD)
			changesetCount = 2;
		else
			changesetCount = 1 +(NSUInteger)arc4random_uniform((uint32_t)9);
		
		for (NSUInteger changesetIdx = 0; changesetIdx < changesetCount; changesetIdx++)
		{
			// Make a random number of changes: [1 - 30)
		
			NSUInteger changeCount;
			if (DEBUG_THIS_METHOD)
				changeCount = 4;
			else
				changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				[dict removeObjectAtIndex:idx];
			}
			
			[changesets addObject:([dict changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		dict_b = [dict immutableCopy];
		
		error = [dict importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		NSDictionary *changeset_merged = [dict changeset];
		
		NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_import_fuzz_insert
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 10;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Make a random number of changesets: [1 - 10)
		
		NSUInteger changesetCount;
		if (DEBUG_THIS_METHOD)
			changesetCount = 2;
		else
			changesetCount = 1 +(NSUInteger)arc4random_uniform((uint32_t)9);
		
		for (NSUInteger changesetIdx = 0; changesetIdx < changesetCount; changesetIdx++)
		{
			// Make a random number of changes: [1 - 30)
		
			NSUInteger changeCount;
			if (DEBUG_THIS_METHOD)
				changeCount = 4;
			else
				changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[dict insertObject:@"" forKey:key atIndex:idx];
			}
			
			[changesets addObject:([dict changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		dict_b = [dict immutableCopy];
		
		error = [dict importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		NSDictionary *changeset_merged = [dict changeset];
		
		NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_import_fuzz_move
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Make a random number of changesets: [1 - 10)
		
		NSUInteger changesetCount;
		if (DEBUG_THIS_METHOD)
			changesetCount = 2;
		else
			changesetCount = 1 +(NSUInteger)arc4random_uniform((uint32_t)9);
		
		for (NSUInteger changesetIdx = 0; changesetIdx < changesetCount; changesetIdx++)
		{
			// Make a random number of changes: [1 - 30)
		
			NSUInteger changeCount;
			if (DEBUG_THIS_METHOD)
				changeCount = 1;
			else
				changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
			
			[changesets addObject:([dict changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		dict_b = [dict immutableCopy];
		
		error = [dict importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		NSDictionary *changeset_merged = [dict changeset];
		
		NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Import: Fuzz: Everything
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_import_fuzz_everything
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedDictionary *dict_a = nil;
		ZDCOrderedDictionary *dict_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				dict[key] = @"";
			}
		}
		
		[dict clearChangeTracking];
		dict_a = [dict immutableCopy];
		
		// Make a random number of changesets: [1 - 10)
		
		NSUInteger changesetCount;
		if (DEBUG_THIS_METHOD)
			changesetCount = 2;
		else
			changesetCount = 1 +(NSUInteger)arc4random_uniform((uint32_t)9);
		
		for (NSUInteger changesetIdx = 0; changesetIdx < changesetCount; changesetIdx++)
		{
			// Make a random number of changes: [1 - 30)
		
			NSUInteger changeCount;
			if (DEBUG_THIS_METHOD)
				changeCount = 2;
			else
				changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				uint32_t random = arc4random_uniform((uint32_t)4);
		
				if (random == 0)
				{
					// Add an item
		
					NSString *key = [self randomLetters:8];
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
					}
					dict[key] = @"";
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
					}
					[dict removeObjectAtIndex:idx];
				}
				else if (random == 2)
				{
					// Insert an item
			
					NSString *key = [self randomLetters:8];
			
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
			
					if (DEBUG_THIS_METHOD) {
						NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
					}
					[dict insertObject:@"" forKey:key atIndex:idx];
				}
				else
				{
					// Move an item
			
					NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
					NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
			
					if (DEBUG_THIS_METHOD) {
						NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
					}
					[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
			
			[changesets addObject:([dict changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		dict_b = [dict immutableCopy];
		
		error = [dict importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		NSDictionary *changeset_merged = [dict changeset];
		
		NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
		
		[dict undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqualToOrderedDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Merge: Failure
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_merge_failure_1
{
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	/*
	addObject:withKey: qszzujxl (idx=0)
	addObject:withKey: krytwlyk (idx=1)
	addObject:withKey: vgraihbv (idx=2)
	addObject:withKey: vwyxkfwk (idx=3)
	addObject:withKey: mcfxtodx (idx=4)
	*/
	
	dict[@"qszzujxl"] = @""; // 0
	dict[@"krytwlyk"] = @""; // 1
	dict[@"vgraihbv"] = @""; // 2
	dict[@"vwyxkfwk"] = @""; // 3
	dict[@"mcfxtodx"] = @""; // 4
	
	[dict clearChangeTracking];
	ZDCOrderedDictionary *dict_cloud = [dict immutableCopy]; // sanity check: don't allow modification (for now)
	
	{
		/*
		 removeObjectAtIndex:4
		 removeObjectAtIndex:3
		*/
		
		[dict removeObjectAtIndex:4];
		[dict removeObjectAtIndex:3];
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	{
		/*
		 setObject:withKey: vqtcntfi (idx=3)
		 removeObjectAtIndex:0
		*/
		
		dict[@"vqtcntfi"] = @"";
		[dict removeObjectAtIndex:0];
		
		[changesets addObject:([dict changeset] ?: @{})];
	}
	
	[dict makeImmutable];           // sanity check: don't allow modification (for now)
	dict_cloud = [dict_cloud copy]; // sanity check: allow modification again
	
	{
		/*
		 moveObjectAtIndex:1 toIndex:1
		 removeObjectAtIndex:1
		*/
		
		[dict_cloud moveObjectAtIndex:1 toIndex:1];
		[dict_cloud removeObjectAtIndex:1];
	}
	
	dict = [dict copy];         // sanity check: allow modification again
	[dict_cloud makeImmutable]; // sanity check: don't allow modification anymore
	
	ZDCOrderedDictionary *dict_preMerge = [dict immutableCopy];
	
	NSError *error = nil;
	NSDictionary *redo = [dict mergeCloudVersion:dict_cloud withPendingChangesets:changesets error:&error];
	
	XCTAssert(error == nil);
	
	[dict undo:redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_preMerge]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Merge: Fuzz: Everything
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_merge_fuzz_everything
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		
		ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSUInteger startCount;
			if (DEBUG_THIS_METHOD)
				startCount = 5;
			else
				startCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"addObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
				}
				dict[key] = @"";
			}
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"....................");
			}
		}
		
		[dict clearChangeTracking];
		ZDCOrderedDictionary *dict_cloud = [dict immutableCopy]; // sanity check: don't allow modification (for now)
		
		// Make a random number of changesets: [1 - 10)
		
		NSUInteger changesetCount;
		if (DEBUG_THIS_METHOD)
			changesetCount = 2;
		else
			changesetCount = 1 +(NSUInteger)arc4random_uniform((uint32_t)9);
		
		for (NSUInteger changesetIdx = 0; changesetIdx < changesetCount; changesetIdx++)
		{
			// Make a random number of changes (to dict): [1 - 30)
		
			NSUInteger changeCount;
			if (DEBUG_THIS_METHOD)
				changeCount = 2;
			else
				changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				uint32_t random = arc4random_uniform((uint32_t)4);
		
				if (random == 0)
				{
					// Add an item
		
					NSString *key = [self randomLetters:8];
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
					}
					dict[key] = @"";
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
					}
					[dict removeObjectAtIndex:idx];
				}
				else if (random == 2)
				{
					// Insert an item
			
					NSString *key = [self randomLetters:8];
			
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
			
					if (DEBUG_THIS_METHOD) {
						NSLog(@"insertObject:forKey: %@ atIndex:%llu", key, (unsigned long long)idx);
					}
					[dict insertObject:@"" forKey:key atIndex:idx];
				}
				else
				{
					// Move an item
			
					NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
					NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
			
					if (DEBUG_THIS_METHOD) {
						NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
					}
					[dict moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
			
			[changesets addObject:([dict changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		[dict makeImmutable];           // sanity check: don't allow modification (for now)
		dict_cloud = [dict_cloud copy]; // sanity check: allow modification again
		
		{
			// Make a random number of changes (to dict_cloud): [1 - 30)
		
			NSUInteger changeCount;
			if (DEBUG_THIS_METHOD)
				changeCount = 2;
			else
				changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				uint32_t random = arc4random_uniform((uint32_t)4);
		
				if (random == 0)
				{
					// Add an item
		
					NSString *key = [self randomLetters:8];
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)dict.count);
					}
					dict_cloud[key] = @"";
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict_cloud.count);
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
					}
					if (dict_cloud.count > 0) {
						[dict_cloud removeObjectAtIndex:idx];
					}
				}
				else if (random == 2)
				{
					// Insert an item
			
					NSString *key = [self randomLetters:8];
			
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict_cloud.count);
			
					if (DEBUG_THIS_METHOD) {
						NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
					}
					[dict_cloud insertObject:@"" forKey:key atIndex:idx];
				}
				else
				{
					// Move an item
			
					NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dict_cloud.count);
					NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)dict_cloud.count);
			
					if (DEBUG_THIS_METHOD) {
						NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
					}
					[dict_cloud moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
		}
		
		dict = [dict copy];         // sanity check: allow modification again
		[dict_cloud makeImmutable]; // sanity check: don't allow modification anymore
		
		ZDCOrderedDictionary *dict_preMerge = [dict immutableCopy];
		
		NSError *error = nil;
		NSDictionary *redo = [dict mergeCloudVersion:dict_cloud withPendingChangesets:changesets error:&error];
		
	//	if (DEBUG_THIS_METHOD && error) {
		if (error) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert(error == nil);
		
		[dict undo:redo error:&error];
		XCTAssert(error == nil);
		XCTAssert([dict isEqualToOrderedDictionary:dict_preMerge]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Merge: Simple
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_simpleMerge_1
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCOrderedDictionary *localDict = [[ZDCOrderedDictionary alloc] init];
	localDict[@"string"] = @"abc123";
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCOrderedDictionary *cloudDict = [localDict copy];
	
	{ // local changes
		
		localDict[@"string"] = @"def456";
		[changesets addObject:[localDict changeset]];
	}
	{ // cloud changes
		
		cloudDict[@"integer"] = @(43);
		[cloudDict makeImmutable];
	}
	
	[localDict mergeCloudVersion: cloudDict
	       withPendingChangesets: changesets
	                       error: &error];
	
	XCTAssert([localDict[@"string"] isEqualToString:@"def456"]);
	XCTAssert([localDict[@"integer"] isEqual:@(43)]);
}

- (void)test_simpleMerge_2
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCOrderedDictionary *localDict = [[ZDCOrderedDictionary alloc] init];
	localDict[@"string"] = @"abc123";
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCOrderedDictionary *cloudDict = [localDict copy];
	
	{ // local changes
		
		localDict[@"string"] = @"def456";
		[changesets addObject:[localDict changeset]];
	}
	{ // cloud changes
		
		cloudDict[@"string"] = @"xyz789";
		cloudDict[@"integer"] = @(43);
		[cloudDict makeImmutable];
	}
	
	[localDict mergeCloudVersion: cloudDict
	       withPendingChangesets: changesets
	                       error: &error];
	
	XCTAssert([localDict[@"string"] isEqualToString:@"xyz789"]);
	XCTAssert([localDict[@"integer"] isEqual:@(43)]);
}

- (void)test_simpleMerge_3
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCOrderedDictionary *localDict = [[ZDCOrderedDictionary alloc] init];
	localDict[@"string"] = nil;
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCOrderedDictionary *cloudDict = [localDict copy];
	
	{ // local changes
		
		localDict[@"string"] = @"def456";
		[changesets addObject:[localDict changeset]];
	}
	{ // cloud changes
		
		cloudDict[@"string"] = @"xyz789";
		cloudDict[@"integer"] = @(43);
		[cloudDict makeImmutable];
	}
	
	[localDict mergeCloudVersion: cloudDict
	       withPendingChangesets: changesets
	                       error: &error];
	
	XCTAssert([localDict[@"string"] isEqualToString:@"xyz789"]);
	XCTAssert([localDict[@"integer"] isEqual:@(43)]);
}

- (void)test_simpleMerge_4
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCOrderedDictionary *localDict = [[ZDCOrderedDictionary alloc] init];
	localDict[@"string"] = nil;
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCOrderedDictionary *cloudDict = [localDict copy];
	
	{ // local changes
		
		localDict[@"string"] = @"def456";
		[changesets addObject:[localDict changeset]];
	}
	{ // cloud changes
		
		cloudDict[@"integer"] = @(43);
		[cloudDict makeImmutable];
	}
	
	[localDict mergeCloudVersion: cloudDict
	       withPendingChangesets: changesets
	                       error: &error];
	
	XCTAssert([localDict[@"string"] isEqualToString:@"def456"]);
	XCTAssert([localDict[@"integer"] isEqual:@(43)]);
}

- (void)test_simpleMerge_5
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCOrderedDictionary *localDict = [[ZDCOrderedDictionary alloc] init];
	localDict[@"string"] = @"abc123";
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCOrderedDictionary *cloudDict = [localDict copy];
	
	{ // local changes
		
		localDict[@"integer"] = @(43);
		[changesets addObject:[localDict changeset]];
	}
	{ // cloud changes
		
		cloudDict[@"string"] = nil;
		[cloudDict makeImmutable];
	}
	
	[localDict mergeCloudVersion: cloudDict
	       withPendingChangesets: changesets
	                       error: &error];
	
	XCTAssert(localDict[@"string"] == nil);
	XCTAssert([localDict[@"integer"] isEqual:@(43)]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Merge - Complex
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_complexMerge_1
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCOrderedDictionary *localDict = [[ZDCOrderedDictionary alloc] init];
	localDict[@"dict"] = [[ZDCOrderedDictionary alloc] init];
	localDict[@"dict"][@"dog"] = @"bark";
	
	[localDict clearChangeTracking];
	ZDCOrderedDictionary *cloudDict =
	  [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:localDict copyItems:YES];
	
	{ // local changes
		
		localDict[@"string"] = @"abc123";
		localDict[@"dict"][@"cat"] = @"meow";
		[changesets addObject:[localDict changeset]];
	}
	{ // cloud changes
		
		cloudDict[@"integer"] = @(43);
		cloudDict[@"dict"][@"duck"] = @"quack";
		[cloudDict makeImmutable];
	}
	
	XCTAssert(localDict[@"dict"][@"duck"] == nil);
	
	[localDict mergeCloudVersion: cloudDict
	       withPendingChangesets: changesets
	                       error: &error];
	
	XCTAssert([localDict[@"string"] isEqualToString:@"abc123"]);
	XCTAssert([localDict[@"integer"] isEqual:@(43)]);
	
	XCTAssert([localDict[@"dict"][@"dog"] isEqualToString:@"bark"]);
	XCTAssert([localDict[@"dict"][@"cat"] isEqualToString:@"meow"]);
	XCTAssert([localDict[@"dict"][@"duck"] isEqualToString:@"quack"]);
}

@end

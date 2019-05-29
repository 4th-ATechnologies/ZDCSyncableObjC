/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <XCTest/XCTest.h>
#import "ZDCArray.h"

@interface test_ZDCArray : XCTestCase
@end

@implementation test_ZDCArray

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
#pragma mark Undo - Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_basic_1
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// - add
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	// Empty array will be starting state
	//
	array_a = [array immutableCopy];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	XCTAssert(array.count == 2);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil];
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil];
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_basic_2
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// - remove
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array removeObject:@"cow"];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil];
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil];
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_basic_3
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// - replace
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	array[0] = @"horse";
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil];
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil];
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_basic_4
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Can we undo/redo basic `moveObjectAtIndex:toIndex:` functionality ?
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:0 toIndex:1];
	
	XCTAssert([array[0] isEqualToString:@"duck"]);
	XCTAssert([array[1] isEqualToString:@"cow"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil];
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil];
	XCTAssert([array isEqualToArray:array_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Combo: add + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_add_add
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Add + Add
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array addObject:@"dog"];
	[array addObject:@"cat"];
	
	XCTAssert(array.count == 4);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_add_remove
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Add + Remove
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array addObject:@"dog"];
	[array removeObject:@"cow"];
	
	XCTAssert(array.count == 2);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_add_insert
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Add + Insert
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array addObject:@"dog"];
	[array insertObject:@"cat" atIndex:0];
	
	XCTAssert(array.count == 4);
	XCTAssert([array[0] isEqualToString:@"cat"]);
	XCTAssert([array[1] isEqualToString:@"cow"]);
	XCTAssert([array[2] isEqualToString:@"duck"]);
	XCTAssert([array[3] isEqualToString:@"dog"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_add_move
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Add + Move
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array addObject:@"dog"];
	[array moveObjectAtIndex:0 toIndex:1];
	
	XCTAssert(array.count == 3);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Combo: remove + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_remove_add
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Remove + Add
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array removeObject:@"cow"];
	[array addObject:@"dog"];
	
	XCTAssert(array.count == 2);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_remove_remove
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Remove + Remove
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array removeObject:@"cow"];
	[array removeObject:@"duck"];
	
	XCTAssert(array.count == 0);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_remove_insert
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Remove + Insert
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array removeObject:@"cow"];
	[array insertObject:@"dog" atIndex:0];
	
	XCTAssert(array.count == 2);
	XCTAssert([array[0] isEqualToString:@"dog"]);
	XCTAssert([array[1] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_remove_move
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Remove + Move
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	[array addObject:@"dog"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array removeObject:@"cow"];
	[array moveObjectAtIndex:0 toIndex:1];
	
	XCTAssert(array.count == 2);
	XCTAssert([array[0] isEqualToString:@"dog"]);
	XCTAssert([array[1] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Combo: insert + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_insert_add
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Add
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array insertObject:@"dog" atIndex:1];
	[array addObject:@"cat"];
	
	XCTAssert(array.count == 4);
	XCTAssert([array[0] isEqualToString:@"cow"]);
	XCTAssert([array[1] isEqualToString:@"dog"]);
	XCTAssert([array[2] isEqualToString:@"duck"]);
	XCTAssert([array[3] isEqualToString:@"cat"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_insert_remove
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Remove
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array insertObject:@"dog" atIndex:1];
	[array removeObject:@"cow"];
	
	XCTAssert(array.count == 2);
	XCTAssert([array[0] isEqualToString:@"dog"]);
	XCTAssert([array[1] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_insert_insert
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Insert
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array insertObject:@"dog" atIndex:1];
	[array insertObject:@"cat" atIndex:1];
	
	XCTAssert(array.count == 4);
	XCTAssert([array[0] isEqualToString:@"cow"]);
	XCTAssert([array[1] isEqualToString:@"cat"]);
	XCTAssert([array[2] isEqualToString:@"dog"]);
	XCTAssert([array[3] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_insert_move_a
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Move
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array insertObject:@"dog" atIndex:1];
	[array moveObjectAtIndex:2 toIndex:0];
	
	XCTAssert(array.count == 3);
	XCTAssert([array[0] isEqualToString:@"duck"]);
	XCTAssert([array[1] isEqualToString:@"cow"]);
	XCTAssert([array[2] isEqualToString:@"dog"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_insert_move_b
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Insert + Move
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array insertObject:@"dog" atIndex:1];
	[array moveObjectAtIndex:0 toIndex:2];
	
	XCTAssert(array.count == 3);
	XCTAssert([array[0] isEqualToString:@"dog"]);
	XCTAssert([array[1] isEqualToString:@"duck"]);
	XCTAssert([array[2] isEqualToString:@"cow"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Combo: move + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_move_add
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Add
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:0 toIndex:1];
	[array addObject:@"dog"];
	
	XCTAssert(array.count == 3);
	XCTAssert([array[0] isEqualToString:@"duck"]);
	XCTAssert([array[1] isEqualToString:@"cow"]);
	XCTAssert([array[2] isEqualToString:@"dog"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_move_remove
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Remove
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:0 toIndex:1];
	[array removeObject:@"cow"];
	
	XCTAssert(array.count == 1);
	XCTAssert([array[0] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_move_insert
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Insert
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:0 toIndex:1];
	[array insertObject:@"dog" atIndex:1];
	
	XCTAssert(array.count == 3);
	XCTAssert([array[0] isEqualToString:@"duck"]);
	XCTAssert([array[1] isEqualToString:@"dog"]);
	XCTAssert([array[2] isEqualToString:@"cow"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_move_move_a
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Move
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:0 toIndex:1];
	[array moveObjectAtIndex:0 toIndex:1];
	
	XCTAssert([array[0] isEqualToString:@"cow"]);
	XCTAssert([array[1] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_move_move_b
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Move
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	[array addObject:@"dog"];
	[array addObject:@"cat"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:1 toIndex:3];
	[array moveObjectAtIndex:2 toIndex:0];
	
	XCTAssert([array[0] isEqualToString:@"cat"]);
	XCTAssert([array[1] isEqualToString:@"cow"]);
	XCTAssert([array[2] isEqualToString:@"dog"]);
	XCTAssert([array[3] isEqualToString:@"duck"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_move_move_c
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Move
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	[array addObject:@"dog"];
	[array addObject:@"cat"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:0 toIndex:3];
	[array moveObjectAtIndex:2 toIndex:1];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_undo_move_move_d
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	// Basic undo/redo functionality.
	//
	// Move + Move
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	[array addObject:@"dog"];
	[array addObject:@"cat"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:0 toIndex:3];
	[array moveObjectAtIndex:1 toIndex:2];
	
	XCTAssert([array[0] isEqualToString:@"duck"]);
	XCTAssert([array[1] isEqualToString:@"cat"]);
	XCTAssert([array[2] isEqualToString:@"dog"]);
	XCTAssert([array[3] isEqualToString:@"cow"]);
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Previous Failures
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_failure_1
{
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// removeObjectAtIndex: 3
	// removeObjectAtIndex: 1
	// removeObjectAtIndex: 2
	
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array removeObjectAtIndex:3];
	[array removeObjectAtIndex:1];
	[array removeObjectAtIndex:2];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_failure_2
{
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// moveObjectAtIndex:1 toIndex:3
	// moveObjectAtIndex:1 toIndex:3
	
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:1 toIndex:3];
	[array moveObjectAtIndex:1 toIndex:3];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_failure_3
{
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// moveObjectAtIndex:3 toIndex:2
	// addObject: kizgnvjy
	// moveObjectAtIndex:5 toIndex:0
	
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:3 toIndex:2];
	[array addObject:@"zion"];
	[array moveObjectAtIndex:5 toIndex:0];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_failure_4
{
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// addObject: soktsaod
	// addObject: kugqcgmf
	// moveObjectAtIndex:3 toIndex:6
	
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array addObject:@"xan"];
	[array addObject:@"zion"];
	[array moveObjectAtIndex:3 toIndex:6];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_failure_5
{
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// moveObjectAtIndex:4 toIndex:1
	// removeObjectAtIndex:0
	
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:4 toIndex:1];
	[array removeObjectAtIndex:0];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_failure_6
{
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// removeObjectAtIndex:2
	// moveObjectAtIndex:3 toIndex:0
	// removeObjectAtIndex:3
	
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array removeObjectAtIndex:2];
	[array moveObjectAtIndex:3 toIndex:0];
	[array removeObjectAtIndex:3];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_failure_7
{
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// removeObjectAtIndex:2
	// moveObjectAtIndex:2 toIndex:3
	// removeObjectAtIndex:3
	
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array removeObjectAtIndex:2];
	[array moveObjectAtIndex:2 toIndex:3];
	[array removeObjectAtIndex:3];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_failure_8
{
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// moveObjectAtIndex:2 toIndex:4
	// moveObjectAtIndex:2 toIndex:3
	// removeObjectAtIndex:1
	
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array moveObjectAtIndex:2 toIndex:4];
	[array moveObjectAtIndex:2 toIndex:3];
	[array removeObjectAtIndex:1];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_failure_9
{
	// Initial array.count: 5
	//
	// addObject: duylyubo
	// moveObjectAtIndex:2 toIndex:5
	// removeObjectAtIndex:4
	// addObject: fmxourgc
	
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	[array addObject:@"frank"];
	[array moveObjectAtIndex:2 toIndex:5];
	[array removeObjectAtIndex:4];
	[array addObject:@"gwen"];
	
	NSDictionary *changeset_undo = [array changeset];
	array_b = [array immutableCopy];
	
	NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:nil]; // a -> b
	XCTAssert([array isEqualToArray:array_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo: Fuzz: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_add
{
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
		// Start with an object that has a random number of objects [0 - 10)
		{
			NSUInteger startCount = (NSUInteger)arc4random_uniform((uint32_t)10);
			
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
			
				[array addObject:key];
			}
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
		// Now add a random number of object [1 - 10)
		{
			NSUInteger changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)9);
			
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				[array addObject:key];
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		XCTAssert([array isEqualToArray:array_b]);
	}}
}

- (void)test_undo_fuzz_remove
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
 
		ZDCArray *array = [[ZDCArray alloc] init];
 
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
 
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
 
		[array clearChangeTracking];
		array_a = [array immutableCopy];
 
		// Now remove a random number of object [1 - 15)
		{
			NSUInteger changeCount;
			if (DEBUG_THIS_METHOD)
				changeCount = 3;
			else
				changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)14);
 
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
 
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex: %llu", (unsigned long long)idx);
				}
				if (array.count > 0) {
					[array removeObjectAtIndex:idx];
				}
			}
		}
 
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
 
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
 
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_undo_fuzz_insert
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
 
		ZDCArray *array = [[ZDCArray alloc] init];
 
		// Start with an object that has a random number of objects [0 - 10)
		{
			NSUInteger startCount = (NSUInteger)arc4random_uniform((uint32_t)10);
 
			for (NSUInteger i = 0; i < startCount; i++)
			{
				NSString *key = [self randomLetters:8];
 
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
 
		[array clearChangeTracking];
		array_a = [array immutableCopy];
 
		// Now insert a random number of object [1 - 10)
		{
			NSUInteger changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)9);
 
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				NSString *key = [self randomLetters:8];
 
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
 
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:%@ atIndex:%llu", key, (unsigned long long)idx);
				}
				[array insertObject:key atIndex:idx];
			}
		}
 
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
 
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
 
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_undo_fuzz_move
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
 
		ZDCArray *array = [[ZDCArray alloc] init];
 
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
 
				[array addObject:key];
			}
		}
 
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
 
		// Now make a random number of moves: [1 - 30)
 
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 2;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
 
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
			NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
 
			if (DEBUG_THIS_METHOD) {
				NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
			}
			if (array.count > 0) {
				[array moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
		}
 
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
 
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
 
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
					NSLog(@"addObject: %@", key);
				}
				[array addObject:key];
			}
			else
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex: %llu", (unsigned long long)idx);
				}
				if (array.count > 0) {
					[array removeObjectAtIndex:idx];
				}
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
					NSLog(@"addObject: %@", key);
				}
				[array addObject:key];
			}
			else
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:%@ atIndex:%llu", key, (unsigned long long)idx);
				}
				[array insertObject:key atIndex:idx];
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 3;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			if (arc4random_uniform((uint32_t)2) == 0)
			{
				// Add an item
				
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"addObject: %@", key);
				}
				[array addObject:key];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				if (array.count > 0) {
					[array moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				if (array.count > 0) {
					[array removeObjectAtIndex:idx];
				}
			}
			else
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[array insertObject:key atIndex:idx];
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 9;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			if (arc4random_uniform((uint32_t)2) == 0)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				if (array.count > 0) {
					[array removeObjectAtIndex:idx];
				}
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				if (array.count > 0) {
					[array moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[array insertObject:key atIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				if (array.count > 0) {
					[array moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)array.count);
				}
				[array addObject:key];
			}
			else if (random == 1)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				if (array.count > 0) {
					[array removeObjectAtIndex:idx];
				}
			}
			else
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[array insertObject:key atIndex:idx];
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
					NSLog(@"addObject: %@", key);
				}
				[array addObject:key];
			}
			else if (random == 1)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				if (array.count > 0) {
					[array removeObjectAtIndex:idx];
				}
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				if (array.count > 0) {
					[array moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
					NSLog(@"setObject:withKey: %@ (idx=%llu)", key, (unsigned long long)array.count);
				}
				[array addObject:key];
			}
			else if (random == 1)
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[array insertObject:key atIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				if (array.count > 0) {
					[array moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				if (array.count > 0) {
					[array removeObjectAtIndex:idx];
				}
			}
			else if (random == 1)
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:%@ atIndex:%llu", key, (unsigned long long)idx);
				}
				[array insertObject:key atIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				if (array.count > 0) {
					[array moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
	
	for (NSUInteger round = 0; round < 5000; round++) { @autoreleasepool
	{
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
					NSLog(@"addObject: %@", key);
				}
				[array addObject:key];
			}
			else if (random == 1)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				if (array.count > 0) {
					[array removeObjectAtIndex:idx];
				}
			}
			else if (random == 2)
			{
				// Modify an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				NSString *value = [self randomLetters:4];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"modify:%llu value:%@", (unsigned long long)idx, value);
				}
				array[idx] = value;
			}
			else if (random == 3)
			{
				// Insert an item
				
				NSString *key = [self randomLetters:8];
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:%@ atIndex:%llu", key, (unsigned long long)idx);
				}
				[array insertObject:key atIndex:idx];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				if (array.count > 0) {
					[array moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
		}
		
		NSDictionary *changeset_undo = [array changeset];
		array_b = [array immutableCopy];
		
		NSDictionary *changeset_redo = [array undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	// Empty dictionary will be starting state
	array_a = [array immutableCopy];
	
	{ // changeset: A
	
		[array addObject:@"cow"];
		[array addObject:@"duck"];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	{ // changeset: B
	
		[array addObject:@"dog"];
		[array addObject:@"cat"];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	
	array_b = [array immutableCopy];
	
	error = [array importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([array isEqualToArray:array_b]);
	
	NSDictionary *changeset_merged = [array changeset];
	
	NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_import_basic_2
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	[array addObject:@"dog"];
	[array addObject:@"cat"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	{ // changeset: A
		
		[array removeObjectAtIndex:0];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	{ // changeset: B
		
		[array removeObjectAtIndex:0];
		[array removeObjectAtIndex:0];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	
	array_b = [array immutableCopy];
	
	error = [array importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([array isEqualToArray:array_b]);
	
	NSDictionary *changeset_merged = [array changeset];
	
	NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_import_basic_3
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	{ // changeset: A
		
		[array insertObject:@"duck" atIndex:0];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	{ // changeset: B
		
		[array insertObject:@"dog" atIndex:1];
		[array insertObject:@"cat" atIndex:0];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	
	array_b = [array immutableCopy];
	
	error = [array importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([array isEqualToArray:array_b]);
	
	NSDictionary *changeset_merged = [array changeset];
	
	NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_import_basic_4
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	[array addObject:@"cow"];
	[array addObject:@"duck"];
	[array addObject:@"dog"];
	[array addObject:@"cat"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	{ // changeset: A
		
		[array moveObjectAtIndex:2 toIndex:3]; // dog
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	{ // changeset: B
		
		[array moveObjectAtIndex:2 toIndex:0]; // cat
		[array moveObjectAtIndex:3 toIndex:2]; // dog
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	
	array_b = [array immutableCopy];
	
	error = [array importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([array isEqualToArray:array_b]);
	
	NSDictionary *changeset_merged = [array changeset];
	
	NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Import: Failures
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_import_failure_1
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// moveObjectAtIndex:0 toIndex:1
	// ********************
	// moveObjectAtIndex:0 toIndex:3
	// ********************
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	{ // changeset: A
		
		[array moveObjectAtIndex:0 toIndex:1];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	{ // changeset: B
		
		[array moveObjectAtIndex:0 toIndex:3];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	
	array_b = [array immutableCopy];
	
	error = [array importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([array isEqualToArray:array_b]);
	
	NSDictionary *changeset_merged = [array changeset];
	
	NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_import_failure_2
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// moveObjectAtIndex:0 toIndex:3
	// moveObjectAtIndex:2 toIndex:2
	// ********************
	// moveObjectAtIndex:4 toIndex:3
	// moveObjectAtIndex:0 toIndex:3
	// ********************
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	{ // changeset: A
		
		[array moveObjectAtIndex:0 toIndex:3];
		[array moveObjectAtIndex:2 toIndex:2];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	{ // changeset: B
		
		[array moveObjectAtIndex:4 toIndex:3];
		[array moveObjectAtIndex:0 toIndex:3];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	
	array_b = [array immutableCopy];
	
	error = [array importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([array isEqualToArray:array_b]);
	
	NSDictionary *changeset_merged = [array changeset];
	
	NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_import_failure_3
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.coun: 5
	//
	// addObject: ftjnwyqy
	// moveObjectAtIndex:3 toIndex:4
	// ********************
	// insertObject:atIndex:3
	// moveObjectAtIndex:2 toIndex:6
	// ********************
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	{ // changeset: A
		
		[array addObject:@"frank"];
		[array moveObjectAtIndex:3 toIndex:4];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	{ // changeset: B
		
		[array insertObject:@"gwen" atIndex:3];
		[array moveObjectAtIndex:2 toIndex:6];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	
	array_b = [array immutableCopy];
	
	error = [array importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([array isEqualToArray:array_b]);
	
	NSDictionary *changeset_merged = [array changeset];
	
	NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_b]);
}

- (void)test_import_failure_4
{
	ZDCArray *array_a = nil;
	ZDCArray *array_b = nil;
	NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	NSError *error = nil;
	
	ZDCArray *array = [[ZDCArray alloc] init];
	
	// UNIT TEST FAILURE:
	// -----------------
	//
	// Initial array.count: 5
	//
	// moveObjectAtIndex:2 toIndex:1
	// addObject: opiimkhy
	// ********************
	// removeObjectAtIndex:3
	// moveObjectAtIndex:4 toIndex:1
	// ********************
	
	[array addObject:@"alice"];
	[array addObject:@"bob"];
	[array addObject:@"carol"];
	[array addObject:@"dave"];
	[array addObject:@"emily"];
	
	[array clearChangeTracking];
	array_a = [array immutableCopy];
	
	{ // changeset: A
		
		[array moveObjectAtIndex:2 toIndex:1];
		[array addObject:@"frank"];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	{ // changeset: B
		
		[array removeObjectAtIndex:3];
		[array moveObjectAtIndex:4 toIndex:1];
		
		[changesets addObject:([array changeset] ?: @{})];
	}
	
	array_b = [array immutableCopy];
	
	error = [array importChangesets:changesets];
	XCTAssert(error == nil);
	
	XCTAssert([array isEqualToArray:array_b]);
	
	NSDictionary *changeset_merged = [array changeset];
	
	NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_a]);
	
	[array undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([array isEqualToArray:array_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Import: Fuzz: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_import_fuzz_add
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
					NSLog(@"addObject: %@", key);
				}
				[array addObject:key];
			}
			
			[changesets addObject:([array changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		array_b = [array immutableCopy];
		
		error = [array importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([array isEqualToArray:array_b]);
		
		NSDictionary *changeset_merged = [array changeset];
		
		NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
				}
				if (array.count > 0) {
					[array removeObjectAtIndex:idx];
				}
			}
			
			[changesets addObject:([array changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		array_b = [array immutableCopy];
		
		error = [array importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([array isEqualToArray:array_b]);
		
		NSDictionary *changeset_merged = [array changeset];
		
		NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
				}
				[array insertObject:key atIndex:idx];
			}
			
			[changesets addObject:([array changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		array_b = [array immutableCopy];
		
		error = [array importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([array isEqualToArray:array_b]);
		
		NSDictionary *changeset_merged = [array changeset];
		
		NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[array moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
			
			[changesets addObject:([array changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		array_b = [array immutableCopy];
		
		error = [array importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([array isEqualToArray:array_b]);
		
		NSDictionary *changeset_merged = [array changeset];
		
		NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
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
		ZDCArray *array_a = nil;
		ZDCArray *array_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCArray *array = [[ZDCArray alloc] init];
		
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
				
				[array addObject:key];
			}
		}
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"Initial array.count: %llu", (unsigned long long)array.count);
		}
		
		[array clearChangeTracking];
		array_a = [array immutableCopy];
		
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
						NSLog(@"addObject: %@", key);
					}
					[array addObject:key];
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"removeObjectAtIndex:%llu", (unsigned long long)idx);
					}
					if (array.count > 0) {
						[array removeObjectAtIndex:idx];
					}
				}
				else if (random == 2)
				{
					// Insert an item
			
					NSString *key = [self randomLetters:8];
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
			
					if (DEBUG_THIS_METHOD) {
						NSLog(@"insertObject:forKey:atIndex:%llu", (unsigned long long)idx);
					}
					[array insertObject:key atIndex:idx];
				}
				else
				{
					// Move an item
			
					NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
					NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)array.count);
			
					if (DEBUG_THIS_METHOD) {
						NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
					}
					if (array.count > 0) {
						[array moveObjectAtIndex:oldIdx toIndex:newIdx];
					}
				}
			}
			
			[changesets addObject:([array changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		array_b = [array immutableCopy];
		
		error = [array importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([array isEqualToArray:array_b]);
		
		NSDictionary *changeset_merged = [array changeset];
		
		NSDictionary *changeset_redo = [array undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_a]);
		
		[array undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![array isEqualToArray:array_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([array isEqualToArray:array_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Merge - Simple
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_simpleMerge_1
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCArray *localArray = [[ZDCArray alloc] init];
	[localArray addObject:@"alice"];
	[localArray addObject:@"bob"];
	
	[localArray clearChangeTracking];
	ZDCArray *cloudArray = [localArray copy];
	
	{ // local changes
		
		[localArray removeObject:@"alice"];
		[localArray addObject:@"carol"];
		[changesets addObject:[localArray changeset]];
	}
	{ // cloud changes
		
		[cloudArray removeObject:@"bob"];
		[cloudArray addObject:@"dave"];
		[cloudArray makeImmutable];
	}
	
	[localArray mergeCloudVersion: cloudArray
	        withPendingChangesets: changesets
	                        error: &error];
	
	XCTAssert(![localArray containsObject:@"alice"]);
	XCTAssert(![localArray containsObject:@"bob"]);
	
	XCTAssert([localArray containsObject:@"carol"]);
	XCTAssert([localArray containsObject:@"dave"]);
}

- (void)test_simpleMerge_2
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCArray *localArray = [[ZDCArray alloc] init];
	[localArray addObject:@"alice"];
	[localArray addObject:@"bob"];
	
	[localArray clearChangeTracking];
	ZDCArray *cloudArray = [localArray copy];
	
	{ // local changes
		
		[localArray removeObject:@"alice"];
		[localArray addObject:@"carol"];
		[changesets addObject:[localArray changeset]];
	}
	{ // cloud changes
		
		[cloudArray removeObject:@"alice"];
		[cloudArray addObject:@"dave"];
		[cloudArray removeObject:@"bob"];
		[cloudArray addObject:@"emily"];
		[cloudArray makeImmutable];
	}
	
	[localArray mergeCloudVersion: cloudArray
	        withPendingChangesets: changesets
	                        error: &error];
	
	XCTAssert(![localArray containsObject:@"alice"]);
	XCTAssert(![localArray containsObject:@"bob"]);
	
	XCTAssert([localArray containsObject:@"carol"]);
	XCTAssert([localArray containsObject:@"dave"]);
	XCTAssert([localArray containsObject:@"emily"]);
}

- (void)test_simpleMerge_3
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCArray *localArray = [[ZDCArray alloc] init];
	[localArray addObject:@"alice"];
	
	[localArray clearChangeTracking];
	ZDCArray *cloudArray = [localArray copy];
	
	{ // local changes
		
		[localArray addObject:@"bob"];
		[changesets addObject:[localArray changeset]];
	}
	{ // cloud changes
		
		[cloudArray addObject:@"carol"];
		[cloudArray removeObject:@"alice"];
		[cloudArray addObject:@"dave"];
		[cloudArray makeImmutable];
	}
	
	[localArray mergeCloudVersion: cloudArray
	        withPendingChangesets: changesets
	                        error: &error];
	
	XCTAssert(![localArray containsObject:@"alice"]);
	
	XCTAssert([localArray containsObject:@"bob"]);
	XCTAssert([localArray containsObject:@"carol"]);
	XCTAssert([localArray containsObject:@"dave"]);
}

- (void)test_simpleMerge_4
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCArray *localArray = [[ZDCArray alloc] init];
	[localArray addObject:@"alice"];
	
	[localArray clearChangeTracking];
	ZDCArray *cloudArray = [localArray copy];
	
	{ // local changes
		
		[localArray addObject:@"bob"];
		[changesets addObject:[localArray changeset]];
	}
	{ // cloud changes
		
		[cloudArray removeObject:@"alice"];
		[cloudArray addObject:@"carol"];
		[cloudArray makeImmutable];
	}
	
	[localArray mergeCloudVersion: cloudArray
	        withPendingChangesets: changesets
	                        error: &error];
	
	XCTAssert(![localArray containsObject:@"alice"]);
	
	XCTAssert([localArray containsObject:@"bob"]);
	XCTAssert([localArray containsObject:@"carol"]);
}

- (void)test_simpleMerge_5
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCArray *localArray = [[ZDCArray alloc] init];
	[localArray addObject:@"alice"];
	[localArray addObject:@"bob"];
	
	[localArray clearChangeTracking];
	ZDCArray *cloudArray = [localArray copy];
	
	{ // local changes
		
		[localArray removeObject:@"bob"];
		[localArray addObject:@"carol"];
		[changesets addObject:[localArray changeset]];
	}
	{ // cloud changes
		
		[cloudArray removeObject:@"alice"];
		[cloudArray makeImmutable];
	}
	
	[localArray mergeCloudVersion: cloudArray
	        withPendingChangesets: changesets
	                        error: &error];
	
	XCTAssert(![localArray containsObject:@"alice"]);
	XCTAssert(![localArray containsObject:@"bob"]);
	
	XCTAssert([localArray containsObject:@"carol"]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Merge - With Duplicates
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_mergeWithDuplicates_1
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCArray *localArray = [[ZDCArray alloc] init];
	[localArray addObject:@"alice"];
	
	[localArray clearChangeTracking];
	ZDCArray *cloudArray = [localArray copy];
	
	{ // local changes
		
		[localArray addObject:@"alice"];
		[changesets addObject:[localArray changeset]];
	}
	{ // cloud changes
		
		[cloudArray addObject:@"alice"];
		[cloudArray makeImmutable];
	}
	
	[localArray mergeCloudVersion: cloudArray
	        withPendingChangesets: changesets
	                        error: &error];
	
	XCTAssert([localArray containsObject:@"alice"]);
	XCTAssert(localArray.count == 2);
}

- (void)test_mergeWithDuplicates_2
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCArray *localArray = [[ZDCArray alloc] init];
	[localArray addObject:@"alice"];
	[localArray addObject:@"alice"];
	
	[localArray clearChangeTracking];
	ZDCArray *cloudArray = [localArray copy];
	
	{ // local changes
		
		[localArray addObject:@"bob"];
		[changesets addObject:[localArray changeset]];
	}
	{ // cloud changes
		
		[cloudArray removeObjectAtIndex:0];
		[cloudArray addObject:@"bob"];
		[cloudArray makeImmutable];
	}
	
	[localArray mergeCloudVersion: cloudArray
	        withPendingChangesets: changesets
	                        error: &error];
	
	XCTAssert([localArray containsObject:@"alice"]);
	XCTAssert(localArray.count == 2);
}

- (void)test_mergeWithDuplicates_3
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCArray *localArray = [[ZDCArray alloc] init];
	[localArray addObject:@"alice"];
	[localArray addObject:@"alice"];
	
	[localArray clearChangeTracking];
	ZDCArray *cloudArray = [localArray copy];
	
	{ // local changes
		
		[localArray removeObjectAtIndex:0];
		[localArray addObject:@"bob"];
		[changesets addObject:[localArray changeset]];
	}
	{ // cloud changes
		
		[cloudArray addObject:@"bob"];
		[cloudArray makeImmutable];
	}
	
	[localArray mergeCloudVersion: cloudArray
	        withPendingChangesets: changesets
	                        error: &error];
	
	XCTAssert([localArray containsObject:@"alice"]);
	XCTAssert(localArray.count == 2);
}

@end

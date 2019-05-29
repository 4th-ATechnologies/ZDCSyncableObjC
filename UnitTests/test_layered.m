/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <XCTest/XCTest.h>

#import "ZDCDictionary.h"
#import "ZDCOrderedDictionary.h"

#import "ComplexRecord.h"

@interface test_layered : XCTestCase
@end

@implementation test_layered

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Dictionary of Dictionaries
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_dictionary_dictionary_add
{
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCDictionary<NSString*, ZDCDictionary*> *dict = [[ZDCDictionary alloc] init];
	
	dict[@"c"] = [[ZDCDictionary alloc] init];
	dict[@"d"] = [[ZDCDictionary alloc] init];
	
	dict_a = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

- (void)test_dictionary_dictionary_remove
{
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCDictionary<NSString*, ZDCDictionary*> *dict = [[ZDCDictionary alloc] init];
	
	dict[@"c"] = [[ZDCDictionary alloc] init];
	dict[@"d"] = [[ZDCDictionary alloc] init];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	dict_a = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"c"][@"cat"] = nil;
	dict[@"d"][@"dog"] = nil;
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

- (void)test_dictionary_dictionary_modify
{
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCDictionary<NSString*, ZDCDictionary*> *dict = [[ZDCDictionary alloc] init];
	
	dict[@"c"] = [[ZDCDictionary alloc] init];
	dict[@"d"] = [[ZDCDictionary alloc] init];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	dict_a = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"c"][@"cat"] = @"hey, I'm a cat";
	dict[@"d"][@"dog"] = @"ruff ruff";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

- (void)test_dictionary_dictionary_push
{
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCDictionary<NSString*, ZDCDictionary*> *dict = [[ZDCDictionary alloc] init];
	
	dict[@"c"] = [[ZDCDictionary alloc] init];
	dict[@"c"][@"cat"] = @"meow";
	
	dict_a = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"d"] = [[ZDCDictionary alloc] init];
	dict[@"d"][@"dog"] = @"bark";
	
	dict[@"c"][@"cat"] = @"hey, I'm a cat";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

- (void)test_dictionary_dictionary_pop
{
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCDictionary<NSString*, ZDCDictionary*> *dict = [[ZDCDictionary alloc] init];
	
	dict[@"c"] = [[ZDCDictionary alloc] init];
	dict[@"d"] = [[ZDCDictionary alloc] init];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	dict_a = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"d"] = nil;
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

- (void)test_dictionary_dictionary_swapin
{
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCDictionary *dict = [[ZDCDictionary alloc] init];
	
	dict[@"c"] = [[ZDCDictionary alloc] init];
	dict[@"c"][@"cat"] = @"meow";
	
	dict[@"d"] = @"dog";
	
	dict_a = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"d"] = [[ZDCDictionary alloc] init];
	dict[@"d"][@"dog"] = @"bark";
	
	dict[@"c"][@"cat"] = @"hey, I'm a cat";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

- (void)test_dictionary_dictionary_swapout
{
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCDictionary *dict = [[ZDCDictionary alloc] init];
	
	dict[@"c"] = [[ZDCDictionary alloc] init];
	dict[@"d"] = [[ZDCDictionary alloc] init];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	dict_a = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"d"] = @"dog";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCDictionary alloc] initWithDictionary:dict.rawDictionary copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark OrderedDictionary of OrderedDictionaries
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_orderedDictionary_orderedDictionary_add
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCOrderedDictionary<NSString*, ZDCOrderedDictionary*> *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"] = [[ZDCOrderedDictionary alloc] init];
	dict[@"d"] = [[ZDCOrderedDictionary alloc] init];
	
	dict_a = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_orderedDictionary_orderedDictionary_remove
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCOrderedDictionary<NSString*, ZDCOrderedDictionary*> *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"] = [[ZDCOrderedDictionary alloc] init];
	dict[@"d"] = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	dict_a = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"c"][@"cat"] = nil;
	dict[@"d"][@"dog"] = nil;
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_orderedDictionary_orderedDictionary_modify
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCOrderedDictionary<NSString*, ZDCOrderedDictionary*> *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"] = [[ZDCOrderedDictionary alloc] init];
	dict[@"d"] = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	dict_a = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"c"][@"cat"] = @"hey, I'm a cat";
	dict[@"d"][@"dog"] = @"ruff ruff";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_orderedDictionary_orderedDictionary_move
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCOrderedDictionary<NSString*, ZDCOrderedDictionary*> *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"] = [[ZDCOrderedDictionary alloc] init];
	dict[@"d"] = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	dict_a = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	[dict clearChangeTracking];
	
	[dict moveObjectAtIndex:0 toIndex:1];
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_orderedDictionary_orderedDictionary_push
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCOrderedDictionary<NSString*,ZDCOrderedDictionary*> *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"] = [[ZDCOrderedDictionary alloc] init];
	dict[@"c"][@"cat"] = @"meow";
	
	dict_a = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"d"] = [[ZDCOrderedDictionary alloc] init];
	dict[@"d"][@"dog"] = @"bark";
	
	dict[@"c"][@"cat"] = @"hey, I'm a cat";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_orderedDictionary_orderedDictionary_pop
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCOrderedDictionary<NSString*, ZDCOrderedDictionary*> *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"] = [[ZDCOrderedDictionary alloc] init];
	dict[@"d"] = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	dict_a = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"d"] = nil;
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_orderedDictionary_orderedDictionary_swapin
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"] = [[ZDCDictionary alloc] init];
	dict[@"c"][@"cat"] = @"meow";
	
	dict[@"d"] = @"dog";
	
	dict_a = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"d"] = [[ZDCOrderedDictionary alloc] init];
	dict[@"d"][@"dog"] = @"bark";
	
	dict[@"c"][@"cat"] = @"hey, I'm a cat";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

- (void)test_orderedDictionary_orderedDictionary_swapout
{
	ZDCOrderedDictionary *dict_a = nil;
	ZDCOrderedDictionary *dict_b = nil;
	NSError *error = nil;
	
	// Dictionary of dictionaries
	
	ZDCOrderedDictionary *dict = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"] = [[ZDCOrderedDictionary alloc] init];
	dict[@"d"] = [[ZDCOrderedDictionary alloc] init];
	
	dict[@"c"][@"cat"] = @"meow";
	dict[@"d"][@"dog"] = @"bark";
	
	dict_a = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	[dict clearChangeTracking];
	
	dict[@"d"] = @"dog";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [[ZDCOrderedDictionary alloc] initWithOrderedDictionary:dict copyItems:YES];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_a]);
	
	[dict undo:changeset_redo error:&error];
	XCTAssert(error == nil);
	XCTAssert([dict isEqualToOrderedDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark ComplexRecord
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_complexRecord
{
	ComplexRecord *cr_a = nil;
	ComplexRecord *cr_b = nil;
	NSError *error = nil;
	
	ComplexRecord *cr = [[ComplexRecord alloc] init];
	
	cr.someString = @"abc123";
	cr.someInteger = 42;
	
	cr.dict[@"dog"] = @"bark";
	cr.dict[@"cat"] = @"meow";
	
	[cr.set addObject:@"foo"];
	[cr.set addObject:@"bar"];
	
	[cr clearChangeTracking];
	cr_a = [cr immutableCopy];
	
	cr.someString = @"def456";
	cr.someInteger = 23;
	
	cr.dict[@"dog"] = @"ruff";
	cr.dict[@"duck"] = @"quack";
	cr.dict[@"cat"] = nil;
	
	[cr.set removeObject:@"bar"];
	[cr.set addObject:@"buzz"];
	
	NSDictionary *changeset_undo = [cr changeset];
	cr_b = [cr immutableCopy];
	
	NSDictionary *changeset_redo = [cr undo:changeset_undo error:&error];
	
	XCTAssert(error == nil);
	XCTAssert([cr isEqualToComplexRecord:cr_a]);
	
	[cr undo:changeset_redo error:&error];
	
	XCTAssert(error == nil);
	XCTAssert([cr isEqualToComplexRecord:cr_b]);
}

@end

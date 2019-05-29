/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <XCTest/XCTest.h>
#import "ZDCDictionary.h"

@interface test_ZDCDictionary : XCTestCase
@end

@implementation test_ZDCDictionary

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
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// - add
	
	ZDCDictionary *dict = [[ZDCDictionary alloc] init];
	
	// Empty dictionary will be starting state
	//
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	XCTAssert(dict.count == 2);
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil];
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil];
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

- (void)test_undo_basic_2
{
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// - remove
	
	ZDCDictionary *dict = [[ZDCDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = nil;
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil];
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil];
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

- (void)test_undo_basic_3
{
	ZDCDictionary *dict_a = nil;
	ZDCDictionary *dict_b = nil;
	
	// Basic undo/redo functionality.
	//
	// - modify
	
	ZDCDictionary *dict = [[ZDCDictionary alloc] init];
	
	dict[@"cow"] = @"moo";
	dict[@"duck"] = @"quack";
	
	[dict clearChangeTracking];
	dict_a = [dict immutableCopy];
	
	dict[@"cow"] = @"mooo";
	
	NSDictionary *changeset_undo = [dict changeset];
	dict_b = [dict immutableCopy];
	
	NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil];
	XCTAssert([dict isEqualToDictionary:dict_a]);
	
	[dict undo:changeset_redo error:nil];
	XCTAssert([dict isEqualToDictionary:dict_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Undo - Fuzz
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_everything
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCDictionary *dict_a = nil;
		ZDCDictionary *dict_b = nil;
		
		ZDCDictionary *dict = [[ZDCDictionary alloc] init];
		
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
				
				dict[key] = [self randomLetters:4];
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
				NSString *value = [self randomLetters:4];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"add: key(%@) = %@", key, value);
				}
				dict[key] = value;
			}
			else if (random == 1)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				NSString *key = nil;
				NSUInteger i = 0;
				for (id _key in dict)
				{
					if (i == idx) {
						key = _key;
						break;
					}
					i++;
				}
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"remove: key(%@)", key);
				}
				[dict removeObjectForKey:key];
			}
			else
			{
				// Modify an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
				
				NSString *key = nil;
				NSUInteger i = 0;
				for (id _key in dict)
				{
					if (i == idx) {
						key = _key;
						break;
					}
					i++;
				}
				
				NSString *value = [self randomLetters:4];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"modify: key(%@) = %@", key, value);
				}
				dict[key] = value;
			}
		}
		
		NSDictionary *changeset_undo = [dict changeset];
		dict_b = [dict immutableCopy];
		
		NSDictionary *changeset_redo = [dict undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![dict isEqualToDictionary:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToDictionary:dict_a]);
		
		[dict undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![dict isEqualToDictionary:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqualToDictionary:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_import_fuzz_everything
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCDictionary *dict_a = nil;
		ZDCDictionary *dict_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCDictionary *dict = [[ZDCDictionary alloc] init];
		
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
				uint32_t random = arc4random_uniform((uint32_t)3);
				
				if (random == 0)
				{
					// Add an item
					
					NSString *key = [self randomLetters:8];
					NSString *value = [self randomLetters:4];
					
					if (DEBUG_THIS_METHOD) {
						NSLog(@"add: key(%@) = %@", key, value);
					}
					dict[key] = value;
				}
				else if (random == 1)
				{
					// Remove an item
					
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
					
					NSString *key = nil;
					NSUInteger i = 0;
					for (id _key in dict)
					{
						if (i == idx) {
							key = _key;
							break;
						}
						i++;
					}
					
					if (DEBUG_THIS_METHOD) {
						NSLog(@"remove: key(%@)", key);
					}
					[dict removeObjectForKey:key];
				}
				else
				{
					// Modify an item
					
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)dict.count);
					
					NSString *key = nil;
					NSUInteger i = 0;
					for (id _key in dict)
					{
						if (i == idx) {
							key = _key;
							break;
						}
						i++;
					}
					
					NSString *value = [self randomLetters:4];
					
					if (DEBUG_THIS_METHOD) {
						NSLog(@"modify: key(%@) = %@", key, value);
					}
					dict[key] = value;
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
		
		XCTAssert([dict isEqual:dict_b]);
		
		NSDictionary *changeset_merged = [dict changeset];
		
		NSDictionary *changeset_redo = [dict undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqual:dict_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqual:dict_a]);
		
		[dict undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![dict isEqual:dict_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([dict isEqual:dict_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Merge - Simple
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_simpleMerge_1
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCDictionary *localDict = [[ZDCDictionary alloc] init];
	localDict[@"string"] = @"abc123";
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCDictionary *cloudDict = [localDict copy];
	
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
	
	ZDCDictionary *localDict = [[ZDCDictionary alloc] init];
	localDict[@"string"] = @"abc123";
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCDictionary *cloudDict = [localDict copy];
	
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
	
	ZDCDictionary *localDict = [[ZDCDictionary alloc] init];
	localDict[@"string"] = nil;
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCDictionary *cloudDict = [localDict copy];
	
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
	
	ZDCDictionary *localDict = [[ZDCDictionary alloc] init];
	localDict[@"string"] = nil;
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCDictionary *cloudDict = [localDict copy];
	
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
	
	ZDCDictionary *localDict = [[ZDCDictionary alloc] init];
	localDict[@"string"] = @"abc123";
	localDict[@"integer"] = @(42);
	
	[localDict clearChangeTracking];
	ZDCDictionary *cloudDict = [localDict copy];
	
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
	
	ZDCDictionary *localDict = [[ZDCDictionary alloc] init];
	localDict[@"dict"] = [[ZDCDictionary alloc] init];
	localDict[@"dict"][@"dog"] = @"bark";
	
	[localDict clearChangeTracking];
	ZDCDictionary *cloudDict = [[ZDCDictionary alloc] initWithDictionary:localDict.rawDictionary copyItems:YES];
	
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

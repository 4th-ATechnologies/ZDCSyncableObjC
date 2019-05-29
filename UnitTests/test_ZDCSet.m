/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <XCTest/XCTest.h>
#import "ZDCSet.h"

@interface test_ZDCSet : XCTestCase
@end

@implementation test_ZDCSet

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
#pragma mark Fuzz
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_everything
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCSet *set_a = nil;
		ZDCSet *set_b = nil;
		
		ZDCSet *set = [[ZDCSet alloc] init];
		
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
				
				[set addObject:key];
			}
		}
		
		[set clearChangeTracking];
		set_a = [set immutableCopy];
		
		// Now make a random number of changes: [1 - 30)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 4;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			uint32_t random = arc4random_uniform((uint32_t)2);
			
			if (random == 0)
			{
				// Add an item
				
				NSString *key = [self randomLetters:8];
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"addObject: %@", key);
				}
				[set addObject:key];
			}
			else if (random == 1)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)set.count);
				
				NSString *key = nil;
				NSUInteger i = 0;
				for (NSString *obj in set)
				{
					if (i == idx) {
						key = obj;
						break;
					}
					i++;
				}
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"removeObject:%@", key);
				}
				[set removeObject:key];
			}
		}
		
		NSDictionary *changeset_undo = [set changeset];
		set_b = [set immutableCopy];
		
		NSDictionary *changeset_redo = [set undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![set isEqualToSet:set_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([set isEqualToSet:set_a]);
		
		[set undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![set isEqualToSet:set_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([set isEqualToSet:set_b]);
		
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
		ZDCSet *set_a = nil;
		ZDCSet *set_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCSet *set = [[ZDCSet alloc] init];
		
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
				
				[set addObject:key];
			}
		}
		
		[set clearChangeTracking];
		set_a = [set immutableCopy];
		
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
				uint32_t random = arc4random_uniform((uint32_t)2);
		
				if (random == 0)
				{
					// Add an item
		
					NSString *key = [self randomLetters:8];
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"addObject: %@", key);
					}
					[set addObject:key];
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)set.count);
		
					NSString *key = nil;
					NSUInteger i = 0;
					for (NSString *obj in set)
					{
						if (i == idx) {
							key = obj;
							break;
						}
						i++;
					}
					
					if (DEBUG_THIS_METHOD) {
						NSLog(@"removeObject: %@", key);
					}
					[set removeObject:key];
				}
			}
			
			[changesets addObject:([set changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		set_b = [set immutableCopy];
		
		error = [set importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([set isEqualToSet:set_b]);
		
		NSDictionary *changeset_merged = [set changeset];
		
		NSDictionary *changeset_redo = [set undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![set isEqualToSet:set_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([set isEqualToSet:set_a]);
		
		[set undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![set isEqualToSet:set_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([set isEqualToSet:set_b]);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

- (void)test_merge_fuzz_everything
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		
		ZDCSet *set = [[ZDCSet alloc] init];
		
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
				
				[set addObject:key];
			}
		}
		
		[set clearChangeTracking];
		ZDCSet *set_cloud = [set immutableCopy]; // sanity check: don't allow modification (for now)
		
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
				uint32_t random = arc4random_uniform((uint32_t)2);
		
				if (random == 0)
				{
					// Add an item
		
					NSString *key = [self randomLetters:8];
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"local: addObject: %@", key);
					}
					[set addObject:key];
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)set.count);
					
					NSString *key = nil;
					NSUInteger i = 0;
					for (NSString *obj in set)
					{
						if (i == idx) {
							key = obj;
							break;
						}
						i++;
					}
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"local: removeObject: %@", key);
					}
					[set removeObject:key];
				}
			}
			
			[changesets addObject:([set changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		[set makeImmutable];          // sanity check: don't allow modification (for now)
		set_cloud = [set_cloud copy]; // sanity check: allow modification again
		
		{
			// Make a random number of changes (to dict_cloud): [1 - 30)
		
			NSUInteger changeCount;
			if (DEBUG_THIS_METHOD)
				changeCount = 2;
			else
				changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)29);
		
			for (NSUInteger i = 0; i < changeCount; i++)
			{
				uint32_t random = arc4random_uniform((uint32_t)2);
		
				if (random == 0)
				{
					// Add an item
		
					NSString *key = [self randomLetters:8];
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"cloud: addObject: %@", key);
					}
					[set_cloud addObject:key];
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)set.count);
		
					NSString *key = nil;
					NSUInteger i = 0;
					for (NSString *obj in set)
					{
						if (i == idx) {
							key = obj;
							break;
						}
						i++;
					}
					
					if (DEBUG_THIS_METHOD) {
						NSLog(@"cloud: removeObject: %@", key);
					}
					[set_cloud removeObject:key];
				}
			}
		}
		
		set = [set copy];           // sanity check: allow modification again
		[set_cloud makeImmutable]; // sanity check: don't allow modification anymore
		
		ZDCSet *set_preMerge = [set immutableCopy];
		
		NSError *error = nil;
		NSDictionary *redo = [set mergeCloudVersion:set_cloud withPendingChangesets:changesets error:&error];
		
		if (DEBUG_THIS_METHOD && error) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert(error == nil);
		
		[set undo:redo error:&error];
		
		if (DEBUG_THIS_METHOD && error) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert(error == nil);
		
		if (DEBUG_THIS_METHOD && ![set isEqualToSet:set_preMerge]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([set isEqualToSet:set_preMerge]);
		
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
	
	ZDCSet *localSet = [[ZDCSet alloc] init];
	[localSet addObject:@"abc123"];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCSet *cloudSet = [localSet copy];
	
	{ // local changes
		
		[localSet removeObject:@"abc123"];
		[localSet addObject:@"def456"];
		[changesets addObject:[localSet changeset]];
	}
	{ // cloud changes
		
		[cloudSet removeObject:@(42)];
		[cloudSet addObject:@(43)];
		[cloudSet makeImmutable];
	}
	
	[localSet mergeCloudVersion: cloudSet
	      withPendingChangesets: changesets
	                      error: &error];
	
	XCTAssert(![localSet containsObject:@"abc123"]);
	XCTAssert(![localSet containsObject:@(42)]);
	
	XCTAssert([localSet containsObject:@"def456"]);
	XCTAssert([localSet containsObject:@(43)]);
}

- (void)test_simpleMerge_2
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCSet *localSet = [[ZDCSet alloc] init];
	[localSet addObject:@"abc123"];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCSet *cloudSet = [localSet copy];
	
	{ // local changes
		
		[localSet removeObject:@"abc123"];
		[localSet addObject:@"def456"];
		[changesets addObject:[localSet changeset]];
	}
	{ // cloud changes
		
		[cloudSet removeObject:@"abc123"];
		[cloudSet addObject:@"xyz789"];
		[cloudSet removeObject:@(42)];
		[cloudSet addObject:@(43)];
		[cloudSet makeImmutable];
	}
	
	[localSet mergeCloudVersion: cloudSet
	      withPendingChangesets: changesets
	                      error: &error];
	
	XCTAssert(![localSet containsObject:@"abc123"]);
	XCTAssert(![localSet containsObject:@(42)]);
	
	XCTAssert([localSet containsObject:@"def456"]);
	XCTAssert([localSet containsObject:@"xyz789"]);
	XCTAssert([localSet containsObject:@(43)]);
}

- (void)test_simpleMerge_3
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCSet *localSet = [[ZDCSet alloc] init];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCSet *cloudSet = [localSet copy];
	
	{ // local changes
		
		[localSet addObject:@"def456"];
		[changesets addObject:[localSet changeset]];
	}
	{ // cloud changes
		
		[cloudSet addObject:@"xyz789"];
		[cloudSet removeObject:@(42)];
		[cloudSet addObject:@(43)];
		[cloudSet makeImmutable];
	}
	
	[localSet mergeCloudVersion: cloudSet
	      withPendingChangesets: changesets
	                      error: &error];
	
	XCTAssert(![localSet containsObject:@(42)]);
	
	XCTAssert([localSet containsObject:@"def456"]);
	XCTAssert([localSet containsObject:@"xyz789"]);
	XCTAssert([localSet containsObject:@(43)]);
}

- (void)test_simpleMerge_4
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCSet *localSet = [[ZDCSet alloc] init];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCSet *cloudSet = [localSet copy];
	
	{ // local changes
		
		[localSet addObject:@"def456"];
		[changesets addObject:[localSet changeset]];
	}
	{ // cloud changes
		
		[cloudSet removeObject:@(42)];
		[cloudSet addObject:@(43)];
		[cloudSet makeImmutable];
	}
	
	[localSet mergeCloudVersion: cloudSet
	      withPendingChangesets: changesets
	                      error: &error];
	
	XCTAssert(![localSet containsObject:@(42)]);
	
	XCTAssert([localSet containsObject:@"def456"]);
	XCTAssert([localSet containsObject:@(43)]);
}

- (void)test_simpleMerge_5
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ZDCSet *localSet = [[ZDCSet alloc] init];
	[localSet addObject:@"abc123"];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCSet *cloudSet = [localSet copy];
	
	{ // local changes
		
		[localSet removeObject:@(42)];
		[localSet addObject:@(43)];
		[changesets addObject:[localSet changeset]];
	}
	{ // cloud changes
		
		[cloudSet removeObject:@"abc123"];
		[cloudSet makeImmutable];
	}
	
	[localSet mergeCloudVersion: cloudSet
	      withPendingChangesets: changesets
	                      error: &error];
	
	XCTAssert(![localSet containsObject:@(42)]);
	XCTAssert(![localSet containsObject:@"abc123"]);
	
	XCTAssert([localSet containsObject:@(43)]);
}

@end

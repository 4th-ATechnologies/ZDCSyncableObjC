/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <XCTest/XCTest.h>
#import "ZDCOrderedSet.h"

@interface test_ZDCOrderedSet : XCTestCase
@end

@implementation test_ZDCOrderedSet

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
#pragma mark Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_basic_1
{
	ZDCOrderedSet *orderedSet_a = nil;
	ZDCOrderedSet *orderedSet_b = nil;
	
	// Basic undo/redo functionality.
	//
	// - add
	
	ZDCOrderedSet *orderedSet = [[ZDCOrderedSet alloc] init];
	
	// Empty dictionary will be starting state
	//
	orderedSet_a = [orderedSet immutableCopy];
	
	[orderedSet addObject:@"cow"];
	[orderedSet addObject:@"duck"];
	
	XCTAssert(orderedSet.count == 2);
	
	NSDictionary *changeset_undo = [orderedSet changeset];
	orderedSet_b = [orderedSet immutableCopy];
	
	NSDictionary *changeset_redo = [orderedSet undo:changeset_undo error:nil];
	XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_a]);
	
	[orderedSet undo:changeset_redo error:nil];
	XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_b]);
}

- (void)test_undo_basic_2
{
	ZDCOrderedSet *orderedSet_a = nil;
	ZDCOrderedSet *orderedSet_b = nil;
	
	// Basic undo/redo functionality.
	//
	// - remove
	
	ZDCOrderedSet *orderedSet = [[ZDCOrderedSet alloc] init];
	
	[orderedSet addObject:@"cow"];
	[orderedSet addObject:@"duck"];
	
	[orderedSet clearChangeTracking];
	orderedSet_a = [orderedSet immutableCopy];
	
	[orderedSet removeObject:@"cow"];
	
	NSDictionary *changeset_undo = [orderedSet changeset];
	orderedSet_b = [orderedSet immutableCopy];
	
	NSDictionary *changeset_redo = [orderedSet undo:changeset_undo error:nil];
	XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_a]);
	
	[orderedSet undo:changeset_redo error:nil];
	XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_b]);
}

- (void)test_undo_basic_3
{
	ZDCOrderedSet *orderedSet_a = nil;
	ZDCOrderedSet *orderedSet_b = nil;
	
	// Basic undo/redo functionality.
	//
	// - move
	
	ZDCOrderedSet *orderedSet = [[ZDCOrderedSet alloc] init];
	
	[orderedSet addObject:@"cow"];
	[orderedSet addObject:@"duck"];
	
	[orderedSet clearChangeTracking];
	orderedSet_a = [orderedSet immutableCopy];
	
	[orderedSet moveObjectAtIndex:0 toIndex:1];
	
	XCTAssert([orderedSet[0] isEqualToString:@"duck"]);
	XCTAssert([orderedSet[1] isEqualToString:@"cow"]);
	
	NSDictionary *changeset_undo = [orderedSet changeset];
	orderedSet_b = [orderedSet immutableCopy];
	
	NSDictionary *changeset_redo = [orderedSet undo:changeset_undo error:nil];
	XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_a]);
	
	[orderedSet undo:changeset_redo error:nil];
	XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Fuzz
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_undo_fuzz_everything
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 1000; round++) { @autoreleasepool
	{
		ZDCOrderedSet *orderedSet_a = nil;
		ZDCOrderedSet *orderedSet_b = nil;
		
		ZDCOrderedSet *orderedSet = [[ZDCOrderedSet alloc] init];
		
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
				
				[orderedSet addObject:key];
			}
		}
		
		[orderedSet clearChangeTracking];
		orderedSet_a = [orderedSet immutableCopy];
		
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
				[orderedSet addObject:key];
			}
			else if (random == 1)
			{
				// Remove an item
				
				NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet.count);
				
				NSString *key = nil;
				NSUInteger i = 0;
				for (NSString *obj in orderedSet)
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
				[orderedSet removeObject:key];
			}
			else
			{
				// Move an item
				
				NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet.count);
				NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet.count);
				
				if (DEBUG_THIS_METHOD) {
					NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
				}
				[orderedSet moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
		}
		
		NSDictionary *changeset_undo = [orderedSet changeset];
		orderedSet_b = [orderedSet immutableCopy];
		
		NSDictionary *changeset_redo = [orderedSet undo:changeset_undo error:nil]; // a <- b
		if (DEBUG_THIS_METHOD && ![orderedSet isEqualToOrderedSet:orderedSet_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_a]);
		
		[orderedSet undo:changeset_redo error:nil]; // a -> b
		if (DEBUG_THIS_METHOD && ![orderedSet isEqualToOrderedSet:orderedSet_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_b]);
		
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
		ZDCOrderedSet *orderedSet_a = nil;
		ZDCOrderedSet *orderedSet_b = nil;
		NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
		NSError *error = nil;
		
		ZDCOrderedSet *orderedSet = [[ZDCOrderedSet alloc] init];
		
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
				
				[orderedSet addObject:key];
			}
		}
		
		[orderedSet clearChangeTracking];
		orderedSet_a = [orderedSet immutableCopy];
		
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
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"addObject: %@", key);
					}
					[orderedSet addObject:key];
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet.count);
		
					NSString *key = nil;
					NSUInteger i = 0;
					for (NSString *obj in orderedSet)
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
					[orderedSet removeObject:key];
				}
				else
				{
					// Move an item
					
					NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet.count);
					NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet.count);
					
					if (DEBUG_THIS_METHOD) {
						NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
					}
					[orderedSet moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
			
			[changesets addObject:([orderedSet changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		orderedSet_b = [orderedSet immutableCopy];
		
		error = [orderedSet importChangesets:changesets];
		XCTAssert(error == nil);
		
		XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_b]);
		
		NSDictionary *changeset_merged = [orderedSet changeset];
		
		NSDictionary *changeset_redo = [orderedSet undo:changeset_merged error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![orderedSet isEqualToOrderedSet:orderedSet_a]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_a]);
		
		[orderedSet undo:changeset_redo error:&error];
		XCTAssert(error == nil);
		if (DEBUG_THIS_METHOD && ![orderedSet isEqualToOrderedSet:orderedSet_b]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_b]);
		
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
		
		ZDCOrderedSet *orderedSet = [[ZDCOrderedSet alloc] init];
		
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
				
				[orderedSet addObject:key];
			}
		}
		
		[orderedSet clearChangeTracking];
		ZDCOrderedSet *orderedSet_cloud = [orderedSet immutableCopy]; // sanity check: don't allow modification (for now)
		
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
				uint32_t random = arc4random_uniform((uint32_t)3);
		
				if (random == 0)
				{
					// Add an item
		
					NSString *key = [self randomLetters:8];
		
					if (DEBUG_THIS_METHOD) {
						NSLog(@"local: addObject: %@", key);
					}
					[orderedSet addObject:key];
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet.count);
					
					NSString *key = nil;
					NSUInteger i = 0;
					for (NSString *obj in orderedSet)
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
					[orderedSet removeObject:key];
				}
				else
				{
					// Move an item
					
					NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet.count);
					NSUInteger newIdx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet.count);
					
					if (DEBUG_THIS_METHOD) {
						NSLog(@"moveObjectAtIndex:%llu toIndex:%llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
					}
					[orderedSet moveObjectAtIndex:oldIdx toIndex:newIdx];
				}
			}
			
			[changesets addObject:([orderedSet changeset] ?: @{})];
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"********************");
			}
		}
		
		[orderedSet makeImmutable];          // sanity check: don't allow modification (for now)
		orderedSet_cloud = [orderedSet_cloud copy]; // sanity check: allow modification again
		
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
					[orderedSet_cloud addObject:key];
				}
				else if (random == 1)
				{
					// Remove an item
		
					NSUInteger idx = (NSUInteger)arc4random_uniform((uint32_t)orderedSet_cloud.count);
					
					if (DEBUG_THIS_METHOD) {
						NSLog(@"cloud: removeObjectAtIndex: %llu (%@)", (unsigned long long)idx, orderedSet_cloud[idx]);
					}
					[orderedSet_cloud removeObjectAtIndex:idx];
				}
			}
		}
		
		orderedSet = [orderedSet copy];           // sanity check: allow modification again
		[orderedSet_cloud makeImmutable]; // sanity check: don't allow modification anymore
		
		ZDCOrderedSet *orderedSet_preMerge = [orderedSet immutableCopy];
		
		NSError *error = nil;
		NSDictionary *redo = [orderedSet mergeCloudVersion:orderedSet_cloud withPendingChangesets:changesets error:&error];
		
		if (DEBUG_THIS_METHOD && error) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert(error == nil);
		
		[orderedSet undo:redo error:&error];
		
		if (DEBUG_THIS_METHOD && error) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert(error == nil);
		
		if (DEBUG_THIS_METHOD && ![orderedSet isEqualToOrderedSet:orderedSet_preMerge]) {
			NSLog(@"It's going to FAIL");
		}
		XCTAssert([orderedSet isEqualToOrderedSet:orderedSet_preMerge]);
		
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
	
	ZDCOrderedSet *localSet = [[ZDCOrderedSet alloc] init];
	[localSet addObject:@"abc123"];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCOrderedSet *cloudSet = [localSet copy];
	
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
	
	ZDCOrderedSet *localSet = [[ZDCOrderedSet alloc] init];
	[localSet addObject:@"abc123"];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCOrderedSet *cloudSet = [localSet copy];
	
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
	
	ZDCOrderedSet *localSet = [[ZDCOrderedSet alloc] init];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCOrderedSet *cloudSet = [localSet copy];
	
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
	
	ZDCOrderedSet *localSet = [[ZDCOrderedSet alloc] init];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCOrderedSet *cloudSet = [localSet copy];
	
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
	
	ZDCOrderedSet *localSet = [[ZDCOrderedSet alloc] init];
	[localSet addObject:@"abc123"];
	[localSet addObject:@(42)];
	
	[localSet clearChangeTracking];
	ZDCOrderedSet *cloudSet = [localSet copy];
	
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

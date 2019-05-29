/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <XCTest/XCTest.h>

#import "ZDCRecord.h"

#import "SimpleRecord.h"
#import "ComplexRecord.h"

@interface test_ZDCRecord : XCTestCase
@end

@implementation test_ZDCRecord

- (void)test_undo
{
	SimpleRecord *sr_a = nil;
	SimpleRecord *sr_b = nil;
	
	SimpleRecord *sr = [[SimpleRecord alloc] init];
	
	sr.someString = @"abc123";
	sr.someInteger = 42;
	
	[sr clearChangeTracking];
	sr_a = [sr immutableCopy];
	
	sr.someString = @"def456";
	sr.someInteger = 23;
	
	NSDictionary *changeset_undo = [sr changeset];
	sr_b = [sr immutableCopy];
	
	NSError *error = nil;
	NSDictionary *changeset_redo = [sr undo:changeset_undo error:&error];
	
	XCTAssert(error == nil);
	XCTAssert([sr isEqualToSimpleRecord:sr_a]);
	
	[sr undo:changeset_redo error:&error];
	
	XCTAssert(error == nil);
	XCTAssert([sr isEqualToSimpleRecord:sr_b]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Merge: Simple
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_simpleMerge_1
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	SimpleRecord *localRecord = [[SimpleRecord alloc] init];
	localRecord.someString = @"abc123";
	localRecord.someInteger = 42;
	
	[localRecord clearChangeTracking];
	SimpleRecord *cloudRecord = [localRecord copy];
	
	{ // local changes
		
		localRecord.someString = @"def456";
		[changesets addObject:[localRecord changeset]];
	}
	{ // cloud changes
		
		cloudRecord.someInteger = 43;
		[cloudRecord makeImmutable];
	}
	
	[localRecord mergeCloudVersion: cloudRecord
	         withPendingChangesets: changesets
	                         error: &error];
	
	XCTAssert([localRecord.someString isEqualToString:@"def456"]);
	XCTAssert(localRecord.someInteger == 43);
}

- (void)test_simpleMerge_2
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	SimpleRecord *localRecord = [[SimpleRecord alloc] init];
	localRecord.someString = @"abc123";
	localRecord.someInteger = 42;
	
	[localRecord clearChangeTracking];
	SimpleRecord *cloudRecord = [localRecord copy];
	
	{ // local changes
		
		localRecord.someString = @"def456";
		[changesets addObject:[localRecord changeset]];
	}
	{ // cloud changes
		
		cloudRecord.someString = @"xyz789";
		cloudRecord.someInteger = 43;
		[cloudRecord makeImmutable];
	}
	
	[localRecord mergeCloudVersion: cloudRecord
	         withPendingChangesets: changesets
	                         error: &error];
	
	XCTAssert([localRecord.someString isEqualToString:@"xyz789"]);
	XCTAssert(localRecord.someInteger == 43);
}

- (void)test_simpleMerge_3
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	SimpleRecord *localRecord = [[SimpleRecord alloc] init];
	localRecord.someString = nil;
	localRecord.someInteger = 42;
	
	[localRecord clearChangeTracking];
	SimpleRecord *cloudRecord = [localRecord copy];
	
	{ // local changes
		
		localRecord.someString = @"def456";
		[changesets addObject:[localRecord changeset]];
	}
	{ // cloud changes
		
		cloudRecord.someString = @"xyz789";
		cloudRecord.someInteger = 43;
		[cloudRecord makeImmutable];
	}
	
	[localRecord mergeCloudVersion: cloudRecord
	         withPendingChangesets: changesets
	                         error: &error];
	
	XCTAssert([localRecord.someString isEqualToString:@"xyz789"]);
	XCTAssert(localRecord.someInteger == 43);
}

- (void)test_simpleMerge_4
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	SimpleRecord *localRecord = [[SimpleRecord alloc] init];
	localRecord.someString = nil;
	localRecord.someInteger = 42;
	
	[localRecord clearChangeTracking];
	SimpleRecord *cloudRecord = [localRecord copy];
	
	{ // local changes
		
		localRecord.someString = @"def456";
		[changesets addObject:[localRecord changeset]];
	}
	{ // cloud changes
		
		cloudRecord.someInteger = 43;
		[cloudRecord makeImmutable];
	}
	
	[localRecord mergeCloudVersion: cloudRecord
	         withPendingChangesets: changesets
	                         error: &error];
	
	XCTAssert([localRecord.someString isEqualToString:@"def456"]);
	XCTAssert(localRecord.someInteger == 43);
}

- (void)test_simpleMerge_5
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	SimpleRecord *localRecord = [[SimpleRecord alloc] init];
	localRecord.someString = @"abc123";
	localRecord.someInteger = 42;
	
	[localRecord clearChangeTracking];
	SimpleRecord *cloudRecord = [localRecord copy];
	
	{ // local changes
		
		localRecord.someInteger = 43;
		[changesets addObject:[localRecord changeset]];
	}
	{ // cloud changes
		
		cloudRecord.someString = nil;
		[cloudRecord makeImmutable];
	}
	
	[localRecord mergeCloudVersion: cloudRecord
	         withPendingChangesets: changesets
	                         error: &error];
	
	XCTAssert(localRecord.someString == nil);
	XCTAssert(localRecord.someInteger == 43);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Merge: Complex
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test_complexMerge_1
{
	NSError *error = nil;
	NSMutableArray<NSDictionary *> *changesets = [NSMutableArray array];
	
	ComplexRecord *localRecord = [[ComplexRecord alloc] init];
	localRecord.dict[@"dog"] = @"bark";
	
	[localRecord clearChangeTracking];
	ComplexRecord *cloudRecord = [localRecord copy];
	
	{ // local changes
		
		localRecord.someString = @"abc123";
		localRecord.dict[@"cat"] = @"meow";
		[changesets addObject:[localRecord changeset]];
	}
	{ // cloud changes
		
		cloudRecord.someInteger = 43;
		cloudRecord.dict[@"duck"] = @"quack";
		[cloudRecord makeImmutable];
	}
	
	[localRecord mergeCloudVersion: cloudRecord
	         withPendingChangesets: changesets
	                         error: &error];
	
	XCTAssert([localRecord.someString isEqualToString:@"abc123"]);
	XCTAssert(localRecord.someInteger == 43);
	
	XCTAssert([localRecord.dict[@"dog"] isEqualToString:@"bark"]);
	XCTAssert([localRecord.dict[@"cat"] isEqualToString:@"meow"]);
	XCTAssert([localRecord.dict[@"duck"] isEqualToString:@"quack"]);
}

@end

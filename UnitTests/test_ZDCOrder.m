/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <XCTest/XCTest.h>
#import "ZDCOrder.h"

@interface test_ZDCOrder : XCTestCase
@end

@implementation test_ZDCOrder

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

- (void)test_fuzz
{
	BOOL const DEBUG_THIS_METHOD = NO;
	
	for (NSUInteger round = 0; round < 5000; round++) { @autoreleasepool
	{
		NSArray<NSString*> *src = nil;
		
		NSUInteger arrayCount;
		if (DEBUG_THIS_METHOD)
			arrayCount = 10;
		else
			arrayCount = 20 + (NSUInteger)arc4random_uniform((uint32_t)10);
		
		// Start with an object that has a random number of objects [20 - 30)
		{
			NSMutableArray<NSString*> *_src = [NSMutableArray arrayWithCapacity:arrayCount];
			
			for (NSUInteger i = 0; i < arrayCount; i++)
			{
				NSString *key = [self randomLetters:8];
				
				[_src addObject:key];
			}
			
			src = [_src copy];
		}
		
		NSMutableArray<NSString*> *dst = [src mutableCopy];
		
		// Now make a random number of changes: [1 - 20)
		
		NSUInteger changeCount;
		if (DEBUG_THIS_METHOD)
			changeCount = 2;
		else
			changeCount = 1 + (NSUInteger)arc4random_uniform((uint32_t)19);
		
		for (NSUInteger i = 0; i < changeCount; i++)
		{
			NSUInteger oldIdx = (NSUInteger)arc4random_uniform((uint32_t)dst.count);
			NSUInteger newIdx;
			do {
				newIdx = (NSUInteger)arc4random_uniform((uint32_t)dst.count);
			} while (oldIdx == newIdx);
			
			if (DEBUG_THIS_METHOD) {
				NSLog(@"move: %llu -> %llu", (unsigned long long)oldIdx, (unsigned long long)newIdx);
			}
			NSString *key = dst[oldIdx];
			
			[dst removeObjectAtIndex:oldIdx];
			[dst insertObject:key atIndex:newIdx];
		}
		
		// Does it halt ?
		NSArray *changes = [ZDCOrder estimateChangesetFrom:src to:dst hints:nil];
		
		XCTAssert(changes.count >= 0);
		
		if (DEBUG_THIS_METHOD) {
			NSLog(@"-------------------------------------------------");
		}
	}}
}

@end

/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCOrder.h"

@implementation ZDCOrder

/**
 * See header file for documentation.
 */
+ (NSArray<id> *)estimateChangesetFrom:(NSArray<id> *)inSrc
                                    to:(NSArray<id> *)dst
                                 hints:(NSSet<id> *)hints
{
	// Sanity checks
	
	NSUInteger const count = inSrc.count;
	if (count != dst.count)
	{
		// If this is NOT true, we're going to end up with an exception below anyway...
		
		@throw [self invalidArraysException:@"Cannot compare arrays of different lengths."];
		return nil;
	}
	{
		// If this is NOT true, we're going to end up with an exception below anyway...
		
		BOOL mismatch = NO;
		NSMutableArray *dstCopy = [dst mutableCopy];
		
		for (id obj in inSrc)
		{
			NSUInteger idx = [dstCopy indexOfObject:obj];
			if (idx == NSNotFound)
			{
				mismatch = YES;
				break;
			}
			else
			{
				[dstCopy removeObjectAtIndex:idx];
			}
		}
		
		if (mismatch)
		{
			@throw [self invalidArraysException:@"Cannot compare arrays with different sets of keys."];
			return nil;
		}
	}
	
	NSMutableArray *loopSrc = [inSrc mutableCopy];
	NSMutableArray *src = [NSMutableArray arrayWithCapacity:count];
	
	NSMutableArray<id> *result = [NSMutableArray array];
	
	// Description of the problem:
	//
	// We're given the current sort order in the cloud, and the original sort order.
	// But we don't know exactly what changes were made by remote devices.
	//
	// (Although we do have some hints, based on items known to have been added).
	//
	// But given that multiple re-ordering paths can start a X and end at Y,
	// we cannot prove that the re-ordering we calculate is actually what occurred.
	//
	// The best we can hope for is along the lines of an "educated guess".
	
	if (hints.count > 0)
	{
		NSMutableDictionary *hints_idx = [NSMutableDictionary dictionaryWithCapacity:hints.count];
		NSMutableArray *hints_order = [NSMutableArray arrayWithCapacity:hints.count];
		
		for (id key in hints)
		{
			NSUInteger idx = [dst indexOfObject:key];
			if (idx != NSNotFound)
			{
				hints_idx[key] = @(idx);
				[hints_order addObject:key];
				
				idx = [loopSrc indexOfObject:key];
				[loopSrc removeObjectAtIndex:idx];
			}
		}
		
		[hints_order sortUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
			
			NSNumber *idx1 = hints_idx[key1];
			NSNumber *idx2 = hints_idx[key2];
			
			return [idx1 compare:idx2];
		}];
		
		for (id key in hints_order)
		{
			NSUInteger idx = [hints_idx[key] unsignedIntegerValue];
			
			[loopSrc insertObject:key atIndex:idx];
			[result addObject:key];
		}
	}
	
	// Algorithm:
	//
	// 1. Compare src vs dst, moving from FIRST to LAST (index 0 to index last).
	//    When a difference is discovered, change src by swapping the correct key into place,
	//    and recording the swapped key in changes_firstToLast.
	//
	// 2. Compare src vs dst, moving from LAST to FIRST (index last to index 0).
	//    When a difference is discovered, change src by swapping the correct key into place,
	//    and recording the swapped key in changes_lastToFirst.
	//
	// 3. If the arrays match (changes_x.count == 0), you're done.
	//
	// 4. Otherwise, compare the counts of changes_firstToLast vs change_lastToFirst.
	//    Pick the one with the shortest count.
	//    And execute the first change in its list.
	//
	// 5. Repeat steps 1-4 until done.
	
	
	NSMutableArray<id> *changes_firstToLast = [NSMutableArray array];
	NSMutableArray<id> *changes_lastToFirst = [NSMutableArray array];
	
	NSUInteger idx_firstToLast_remove = 0;
	NSUInteger idx_firstToLast_insert = 0;
	
	NSUInteger idx_lastToFirst_remove = 0;
	NSUInteger idx_lastToFirst_insert = 0;
	
	NSUInteger i = 0;
	NSUInteger j = 0;
	BOOL done = NO;
	do {
		
		// Step 1: Compare: First to Last
		{
			[src setArray:loopSrc];
			
			for (i = 0; i < dst.count; i++)
			{
				id key_src = src[i];
				id key_dst = dst[i];
				
				if (![key_src isEqual:key_dst])
				{
					NSUInteger idx = [src indexOfObject:key_dst inRange:NSMakeRange(i+1, count-i-1)];
					
					[src removeObjectAtIndex:idx];
					[src insertObject:key_dst atIndex:i];
					
					if (changes_firstToLast.count == 0) {
						idx_firstToLast_remove = idx;
						idx_firstToLast_insert = i;
					}
					
					[changes_firstToLast addObject:key_dst];
				}
			}
		}
		
		// Step 2: Compare: Last to First
		//
		if (changes_firstToLast.count > 0)
		{
			[src setArray:loopSrc];
			
			for (j = count; j > 0; j--)
			{
				i = j-1;
				
				id key_src = src[i];
				id key_dst = dst[i];
				
				if (![key_src isEqual:key_dst])
				{
					NSUInteger idx = [src indexOfObject:key_dst inRange:NSMakeRange(0, i)];
					
					[src removeObjectAtIndex:idx];
					[src insertObject:key_dst atIndex:i];
					
					if (changes_lastToFirst.count == 0) {
						idx_lastToFirst_remove = idx;
						idx_lastToFirst_insert = i;
					}
					
					[changes_lastToFirst addObject:key_dst];
				}
			}
		}
		else // if (changes_firstToLast.count == 0)
		{
			done = YES;
		}
		
		if (!done)
		{
			if (changes_firstToLast.count <= changes_lastToFirst.count)
			{
				id key = changes_firstToLast[0];
				[result addObject:key];
				
				[loopSrc removeObjectAtIndex:idx_firstToLast_remove];
				[loopSrc insertObject:key atIndex:idx_firstToLast_insert];
			}
			else
			{
				id key = changes_lastToFirst[0];
				[result addObject:key];
				
				[loopSrc removeObjectAtIndex:idx_lastToFirst_remove];
				[loopSrc insertObject:key atIndex:idx_lastToFirst_insert];
			}
			
			[changes_firstToLast removeAllObjects];
			[changes_lastToFirst removeAllObjects];
		}
		
	} while (!done);
	
	return result;
}

+ (NSException *)invalidArraysException:(NSString *)details
{
	NSDictionary *userInfo = @{
		NSLocalizedRecoverySuggestionErrorKey: details
	};
	NSString *reason = @"Invalid arrays given as parameters.";
	
	return [NSException exceptionWithName:@"ZDCOrderException" reason:reason userInfo:userInfo];
}

@end

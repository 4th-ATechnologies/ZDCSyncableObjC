/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCArray.h"

#import "ZDCObjectSubclass.h"
#import "ZDCOrder.h"

// Encoding/Decoding Keys
//
static int const kCurrentVersion = 0;
#pragma unused(kCurrentVersion)

static NSString *const kCoding_version = @"version";
static NSString *const kCoding_array   = @"array";

// Changeset Keys
//
static NSString *const kChangeset_added   = @"added";
static NSString *const kChangeset_moved   = @"moved";
static NSString *const kChangeset_deleted = @"deleted";

@implementation ZDCArray {
@private

	NSMutableArray *array;
	
	NSMutableIndexSet *added;                         // [{ currentIndex }]
	NSMutableDictionary<NSNumber*, NSNumber*> *moved; // key={currentIndex}, value={previousIndex}
	NSMutableDictionary<NSNumber*, id> *deleted;      // key={previousIndex}, value={object}
}

@dynamic rawArray;
@dynamic count;

- (instancetype)init
{
	return [self initWithArray:nil copyItems:NO];
}

- (instancetype)initWithArray:(NSArray *)inArray
{
	return [self initWithArray:inArray copyItems:NO];
}

- (instancetype)initWithArray:(NSArray *)inArray copyItems:(BOOL)copyItems
{
	if ((self = [super init]))
	{
		NSUInteger capacity = inArray ? inArray.count : 4;
		
		array = [[NSMutableArray alloc] initWithCapacity:capacity];
		added = [[NSMutableIndexSet alloc] init];
		
		NSUInteger idx = 0;
		for (id obj in inArray)
		{
			[array addObject:(copyItems ? [obj copy] : obj)];
			[added addIndex:idx];
			 
			idx++;
		}
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCoding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		array = [decoder decodeObjectForKey:kCoding_array];
		
		if (array == nil) {
			array = [[NSMutableArray alloc] init];
		}
		
		// Note: ephemeral properties (i.e. for change tracking) are not serialized
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if (kCurrentVersion != 0) {
		[coder encodeInt:kCurrentVersion forKey:kCoding_version];
	}
	
	[coder encodeObject:array forKey:kCoding_array];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)copyWithZone:(NSZone *)zone
{
	ZDCArray *copy = [super copyWithZone:zone]; // [ZDCObject copyWithZone:]
	
	copy->array = [self->array mutableCopy];
	
	copy->added = [self->added mutableCopy];
	copy->moved = [self->moved mutableCopy];
	copy->deleted = [self->deleted mutableCopy];
	
	return copy;
}

/**
 * For complicated copying scenarios, such as nested deep copies.
 * This method is declared in: ZDCObjectSubclass.h
 */
- (void)copyChangeTrackingTo:(id)another
{
	if ([another isKindOfClass:[ZDCArray class]])
	{
		__unsafe_unretained ZDCArray *copy = (ZDCArray *)another;
		if (!copy.isImmutable)
		{
			copy->added = [self->added mutableCopy];
			copy->moved = [self->moved mutableCopy];
			copy->deleted = [self->deleted mutableCopy];
			
			[super copyChangeTrackingTo:another];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Raw
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * See header file for description.
 */
- (NSArray<id> *)rawArray
{
	return [array copy];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)count
{
	return array.count;
}

- (id)objectAtIndex:(NSUInteger)idx
{
	return [array objectAtIndex:idx];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
	return array[idx];
}

- (BOOL)containsObject:(id)anObject
{
	return [array containsObject:anObject];
}

- (NSUInteger)indexOfObject:(id)anObject
{
	return [array indexOfObject:anObject];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Writing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addObject:(id)object
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (object == nil) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:nil userInfo:nil];
		return;
	}
	
	[self _willInsertObjectAtIndex:array.count];
	[array addObject:object];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)idx
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (object == nil) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:nil userInfo:nil];
		return;
	}
	if (idx > array.count) {
		@throw [NSException exceptionWithName:NSRangeException reason:nil userInfo:nil];
		return;
	}
	
	[self _willInsertObjectAtIndex:idx];
	[array insertObject:object atIndex:idx];
}

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)idx
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (object == nil) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:nil userInfo:nil];
		return;
	}
	if (idx > array.count) {
		@throw [NSException exceptionWithName:NSRangeException reason:nil userInfo:nil];
		return;
	}
	
	if (idx == array.count)
	{
		[self _willInsertObjectAtIndex:idx];
		array[idx] = object;
	}
	else
	{
		[self _willRemoveObjectAtIndex:idx];
		[array removeObjectAtIndex:idx];
		
		[self _willInsertObjectAtIndex:idx];
		[array insertObject:object atIndex:idx];
	}
}

/**
 * See header file for description.
 */
- (void)moveObjectAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex;
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if (oldIndex >= array.count) {
		@throw [NSException exceptionWithName:NSRangeException reason:nil userInfo:nil];
		return;
	}
	if (newIndex >= array.count) {
		newIndex = array.count - 1;
	}
	if (oldIndex == newIndex) {
		return;
	}
	
	id obj = array[oldIndex];
	[self _willMoveObjectFromIndex:oldIndex toIndex:newIndex];
	
	[array removeObjectAtIndex:oldIndex];
	[array insertObject:obj atIndex:newIndex];
}

- (void)removeObject:(id)object
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (object == nil) return;
	
	NSUInteger idx = [array indexOfObject:object];
	while (idx != NSNotFound)
	{
		[self _willRemoveObjectAtIndex:idx];
		[array removeObjectAtIndex:idx];
		
		idx = [array indexOfObject:object];
	}
}

- (void)removeObjectAtIndex:(NSUInteger)idx
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (idx >= array.count) {
		@throw [NSException exceptionWithName:NSRangeException reason:nil userInfo:nil];
		return;
	}
	
	[self _willRemoveObjectAtIndex:idx];
	[array removeObjectAtIndex:idx];
}

- (void)removeAllObjects
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	while (array.count > 0)
	{
		[self _willRemoveObjectAtIndex:0];
		[array removeObjectAtIndex:0];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Change Tracking Internals
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)_willInsertObjectAtIndex:(NSUInteger const)insertionIdx
{
	NSParameterAssert(insertionIdx <= array.count);
	
	if (added == nil) {
		added = [[NSMutableIndexSet alloc] init];
	}
	
	// ADD: Step 1 of 2
	//
	// Update the 'added' indexSet.
	
	[self shiftAddedIndexesStartingAtIndex:insertionIdx by:1];
	
	NSAssert(![added containsIndex:insertionIdx], @"Logic error");
	[added addIndex:insertionIdx];
	
	// ADD: Step 2 of 2
	//
	// The currentIndex of some items may be increasing.
	// So we need to update the 'moved' dictionary accordingly.
	
	[self incrementMovedCurrentIndexesStartingAtIndex:insertionIdx];
}

- (void)_willRemoveObjectAtIndex:(NSUInteger const)deletionIdx
{
	NSParameterAssert(deletionIdx < array.count);
	
	if (deleted == nil) {
		deleted = [[NSMutableDictionary alloc] init];
	}
	
	// REMOVE: Step 1 of 4:
	//
	// Determine if this will be counted as a deletion, or a simply undoing a previous add/insert.
	
	BOOL wasAddedThenDeleted = [added containsIndex:deletionIdx];
	
	if (wasAddedThenDeleted)
	{
		// The currentIndex of some items may be decreasing
		
		[self decrementMovedCurrentIndexesStartingAtIndex:deletionIdx];
		
	#ifndef NS_BLOCK_ASSERTIONS
		[self checkMoved];
	#endif
		
	}
	else // if (!wasAddedThenDeleted)
	{
		// REMOVE: Step 2 of 4:
		//
		// Add the item to `deleted`.
		// And to do so, we need to know the correct originalIndex (which may not be deletionIndex).
		//
		// Remember that our goal is to create a changeset that can be used to undo this change.
		// So it's important to understand the order in which the undo operation operates:
		//
		//                       direction    <=       this      <=     in      <=      read
		// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
		//
		// We can see that undoing delete operations is the last step.
		// So we need to take this into account by taking into consideration moves, adds & previous deletes.
		
		id deletedObj = array[deletionIdx];
		
		NSUInteger originalIdx;
		NSUInteger originalIdx_addMoveOnly;
		
		{ // scoping
			
			NSMutableArray<id> *originalArray = [NSMutableArray arrayWithCapacity:array.count];
			
			for (NSUInteger idx = 0; idx < array.count; idx++)
			{
				if (![added containsIndex:idx] && (moved[@(idx)] == nil))
				{
					[originalArray addObject:array[idx]];
				}
			}
			
			NSArray<NSNumber*> *moved_sortedKeys_byPreviousIdx =
				[moved keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
			
			for (NSNumber *num in moved_sortedKeys_byPreviousIdx)
			{
				NSUInteger currentIdx = num.unsignedIntegerValue;
				
				id obj = array[currentIdx];
				NSUInteger previousIdx = [moved[num] unsignedIntegerValue];
					
				[originalArray insertObject:obj atIndex:previousIdx];
			}
			
			originalIdx_addMoveOnly = [originalArray indexOfObjectIdenticalTo:deletedObj];
			
			NSArray<NSNumber*> *deleted_sortedKeys = [[deleted allKeys] sortedArrayUsingComparator:
				^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
			
			for (NSNumber *num in deleted_sortedKeys)
			{
				NSUInteger previousIdx = num.unsignedIntegerValue;
				id obj = deleted[num];
				
				[originalArray insertObject:obj atIndex:previousIdx];
			}
			
			originalIdx = [originalArray indexOfObjectIdenticalTo:deletedObj];
		}
		
	#ifndef NS_BLOCK_ASSERTIONS
		[self checkDeleted:originalIdx];
	#endif
		deleted[@(originalIdx)] = deletedObj;
		
		// REMOVE: Step 3 of 4:
		//
		// Remove deleted item from 'moved'.
		//
		// Recall that we undo deletes AFTER we undo moves.
		// So we need to fixup the 'moved' dictionary so everything works as expected.
		{
			moved[@(deletionIdx)] = nil;
			
			NSArray<NSNumber*> *sortedKeys = [[moved allKeys] sortedArrayUsingComparator:
				^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
			
			for (NSNumber *num in sortedKeys)
			{
				NSUInteger currentIdx = num.unsignedIntegerValue;
				NSUInteger previousIdx = [moved[num] unsignedIntegerValue];
				
				if ((currentIdx > deletionIdx) || (previousIdx > originalIdx_addMoveOnly))
				{
					moved[num] = nil;
					
					if (currentIdx > deletionIdx) {
						currentIdx--;
					}
					if (previousIdx > originalIdx_addMoveOnly) {
						previousIdx--;
					}
					
					moved[@(currentIdx)] = @(previousIdx);
				}
			}
			
		#ifndef NS_BLOCK_ASSERTIONS
			[self checkMoved];
		#endif
		}
	}
	
	// REMOVE: Step 4 of 4
	//
	// Update the 'added' set.
	//
	// Recall that 'added' is just a NSMutableIndexSet which is supposed to point
	// to the items that were added within this changeset.
	// The removal of this item may have changed the indexes of some items,
	// so we need to update the indexes that were affected.
	
	[added removeIndex:deletionIdx];
	[self shiftAddedIndexesStartingAtIndex:deletionIdx by:-1];
}

- (void)_willMoveObjectFromIndex:(NSUInteger const)oldIdx toIndex:(NSUInteger const)newIdx
{
	NSParameterAssert(oldIdx < array.count);
	NSParameterAssert(newIdx <= array.count);
	NSParameterAssert(oldIdx != newIdx);
	
	// Note: we don't have to concern ourselves with deletes here.
	// This is because of the order in which the undo operation operates:
	//
	//                       direction    <=       this      <=     in      <=       read
	// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
	//
	// We will undo moves before we undo deletes.
	
	if (moved == nil) {
		moved = [[NSMutableDictionary alloc] init];
	}
	
	// MOVE: Step 1 of 6
	//
	// Are we moving an item that was added within this changeset ?
	// If so, then the change is consolidated into the add/insert action.
	
	BOOL wasAdded = [added containsIndex:oldIdx];
	NSUInteger originalIdx = 0;
	
	if (!wasAdded)
	{
		// MOVE: Step 2 of 6:
		//
		// Calculate the originalIndex of the object within the array (at the beginning of the changeset).
		//
		// Remember, we cannot simply use oldIdx.
		// Previous moves/inserts within the changeset may have skewed the oldIdx such that it's no longer accurate.
		
		if (moved[@(oldIdx)])
		{
			originalIdx = [moved[@(oldIdx)] unsignedIntegerValue];
		}
		else
		{
			NSMutableArray<id> *originalArray = [NSMutableArray arrayWithCapacity:array.count];
	
			for (NSUInteger idx = 0; idx < array.count; idx++)
			{
				if (![added containsIndex:idx] && (moved[@(idx)] == nil))
				{
					[originalArray addObject:array[idx]];
				}
			}
	
			NSArray<NSNumber*> *moved_sortedKeys_byPreviousIdx =
				[moved keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
		
			for (NSNumber *num in moved_sortedKeys_byPreviousIdx)
			{
				NSUInteger currentIdx = num.unsignedIntegerValue;
		
				id obj = array[currentIdx];
				NSUInteger previousIdx = [moved[num] unsignedIntegerValue];
		
				[originalArray insertObject:obj atIndex:previousIdx];
			}
		
			id targetObj = array[oldIdx];
	
			originalIdx = [originalArray indexOfObjectIdenticalTo:targetObj];
			NSAssert(originalIdx != NSNotFound, @"Logic error");
		}
		
		// MOVE: Step 3 of 6
		//
		// If the item has been moved before (within the context of this changeset),
		// then remove the old entry. It will be replaced with a new entry momentarily.
		
		moved[@(oldIdx)] = nil;
	}
		
	// MOVE: Step 4 of 6
	//
	// The items within the 'moved' array map from `current_index` to `previous_index`.
	// But we're about to move items around, which could change the current_index of many items.
	// So we need to update the 'moved' dictionary.
	//
	// In particular, we need to change the keys (which represent the `current_index`),
	// for any items whose current_index will be changed due to the move.
	
	if (oldIdx < newIdx)
	{
		// The currentIndex of some items may be decreasing
		
		NSArray<NSNumber*> *sortedKeys = [[moved allKeys] sortedArrayUsingComparator:
			^NSComparisonResult(NSNumber *num1, NSNumber *num2)
		{
			return [num1 compare:num2]; // sort in ascending order
		}];
		
		for (NSNumber *num in sortedKeys)
		{
			NSUInteger idx = num.unsignedIntegerValue;
			
			if ((idx > oldIdx) && (idx <= newIdx))
			{
				NSNumber *previousIdx = moved[num];
				
				moved[num] = nil;
				moved[@(idx-1)] = previousIdx;
			}
		}
	}
	else if (oldIdx > newIdx)
	{
		// The currentIndex of some items may be increasing
		
		NSArray<NSNumber*> *sortedKeys = [[moved allKeys] sortedArrayUsingComparator:
			^NSComparisonResult(NSNumber *num1, NSNumber *num2)
		{
			return [num2 compare:num1]; // sort in descending order
		}];
		
		for (NSNumber *num in sortedKeys)
		{
			NSUInteger idx = num.unsignedIntegerValue;
			
			if ((idx < oldIdx) && (idx >= newIdx))
			{
				NSNumber *previousIdx = moved[num];
				
				moved[num] = nil;
				moved[@(idx+1)] = previousIdx;
			}
		}
	}
	
	if (!wasAdded)
	{
		// MOVE: Step 5 of 6
		//
		// Insert the entry that reflects this move action.
		
		moved[@(newIdx)] = @(originalIdx);
	#ifndef NS_BLOCK_ASSERTIONS
		[self checkMoved];
	#endif
	}
	
	// MOVE: Step 6 of 6
	//
	// Update the 'added' set.
	//
	// Recall that 'added' is just a NSMutableIndexSet which is supposed to point
	// to the items that were added within this changeset.
	// The removal of this item may have changed the indexes of some items,
	// so we need to update the indexes that were affected.
	
	if (wasAdded)
	{
		[added removeIndex:oldIdx];
		[self shiftAddedIndexesStartingAtIndex:oldIdx by:-1];
		
		[self shiftAddedIndexesStartingAtIndex:newIdx by:1];
		[added addIndex:newIdx];
	}
	else
	{
		[self shiftAddedIndexesStartingAtIndex:oldIdx by:-1];
		[self shiftAddedIndexesStartingAtIndex:newIdx by:1];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)incrementMovedCurrentIndexesStartingAtIndex:(NSUInteger)offset
{
	NSArray<NSNumber*> *sortedKeys = [[moved allKeys] sortedArrayUsingComparator:
		^NSComparisonResult(NSNumber *num1, NSNumber *num2)
	{
		return [num2 compare:num1]; // sort in descending order
	}];
	
	for (NSNumber *num in sortedKeys)
	{
		NSUInteger idx = num.unsignedIntegerValue;
		
		if (idx >= offset)
		{
			NSNumber *previousIdx = moved[num];
			
			moved[num] = nil;
			moved[@(idx+1)] = previousIdx;
		}
	}
}

- (void)decrementMovedCurrentIndexesStartingAtIndex:(NSUInteger)offset
{
	NSArray<NSNumber*> *sortedKeys = [[moved allKeys] sortedArrayUsingComparator:
		^NSComparisonResult(NSNumber *num1, NSNumber *num2)
	{
		return [num1 compare:num2]; // sort in ascending order
	}];
	
	for (NSNumber *num in sortedKeys)
	{
		NSUInteger idx = num.unsignedIntegerValue;
		
		if (idx >= offset)
		{
			NSNumber *previousIdx = moved[num];
			
			moved[num] = nil;
			moved[@(idx-1)] = previousIdx;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Framework Bugs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)shiftAddedIndexesStartingAtIndex:(NSUInteger)offset by:(NSUInteger)shift
{
	NSAssert(shift == 1 || shift == -1, @"Unexpected shift amount");
	
	// There are some UGLY bugs in NSMutableIndexSet.
	//
	// Bug example #1:
	//
	// [added addIndex:1];
	// [added shiftIndexesStartingAtIndex:2 by:-1];
	//
	// Result:
	//   Empty frigging set.
	//   It straight up deleted our frigging index. WTF.
	//
	// Apparently, there are plenty more bugs in NSMutableIndexSet to be aware of:
	// - https://openradar.appspot.com/14707836
	// - http://ootips.org/yonat/workaround-for-bug-in-nsindexset-shiftindexesstartingatindex/
	// - https://www.mail-archive.com/cocoa-dev@lists.apple.com/msg44062.html
	//
	// So we're just going to do this the long way - which is at least reliable.
	
	NSIndexSet *copy = [added copy];
	[added removeAllIndexes];
	
	[copy enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		
		if (idx < offset) {
			[self->added addIndex:idx];
		}
		else {
			[self->added addIndex:(idx + shift)];
		}
	}];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Sanity Checks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#ifndef NS_BLOCK_ASSERTIONS

- (void)checkDeleted:(NSUInteger)originalIdx
{
	NSAssert(originalIdx != NSNotFound, @"Calculated originalIdx is invalid (for 'deleted')");
	
	NSAssert(deleted[@(originalIdx)] == nil, @"Calculated originalIdx is wrong (for 'deleted')");
}

- (void)checkMoved
{
	// The 'moved' dictionary:
	// - key   : currentIndex
	// - value : previousIndex
	//
	// If everything is accurate, then a given 'previousIndex' value should
	// only be represented ONCE in the dictionary.
	
	NSMutableIndexSet *existing = [[NSMutableIndexSet alloc] init];
	
	for (NSNumber *num in [moved objectEnumerator])
	{
		NSUInteger idx = num.unsignedIntegerValue;
		
		if ([existing containsIndex:idx])
		{
			NSAssert(NO, @"Calculated previousIdx is wrong (for 'moved')");
		}
		
		[existing addIndex:idx];
	}
}

#endif
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Enumeration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block
{
	[array enumerateObjectsUsingBlock:block];
}

- (NSEnumerator<id> *)objectEnumerator
{
	return [array objectEnumerator];
}

- (NSEnumerator<id> *)reverseObjectEnumerator
{
	return [array reverseObjectEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len
{
	return [array countByEnumeratingWithState:state objects:buffer count:len];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Equality
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isEqual:(nullable id)another
{
	if ([another isKindOfClass:[ZDCArray class]]) {
		return [self isEqualToArray:(ZDCArray *)another];
	}
	else {
		return NO;
	}
}

- (BOOL)isEqualToArray:(nullable ZDCArray *)another
{
	if (another == nil) return NO; // null dereference crash ahead
	
	if (![array isEqualToArray:another->array]) return NO;
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark ZDCObject Overrides
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)makeImmutable
{
	[super makeImmutable];
	
	for (id obj in array)
	{
		if ([obj isKindOfClass:[ZDCObject class]])
		{
			[(ZDCObject *)obj makeImmutable];
		}
	}
}

- (BOOL)hasChanges
{
	if ([super hasChanges]) return YES;
	
	if (added.count   > 0 ||
	    deleted.count > 0 ||
	    moved.count   > 0  ) return YES;
	
	for (id obj in array)
	{
		if ([obj isKindOfClass:[ZDCObject class]])
		{
			if ([(ZDCObject *)obj hasChanges]) return YES;
		}
	}
	
	return NO;
}

- (void)clearChangeTracking
{
	[super clearChangeTracking];
	
	[added removeAllIndexes];
	[deleted removeAllObjects];
	[moved removeAllObjects];
	
	for (id obj in array)
	{
		if ([obj isKindOfClass:[ZDCObject class]])
		{
			[(ZDCObject *)obj clearChangeTracking];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark ZDCSyncable
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (nullable NSDictionary *)_changeset
{
	if (![self hasChanges]) return nil;
	
	// Reminder: ivars look like this:
	//
	// NSMutableIndexSet *added;
	// NSMutableDictionary<NSNumber*, id> *deleted;
	// NSMutableDictionary<NSNumber*, NSNumber*> * moved;
	
	NSMutableDictionary<NSString*, id> *changeset = [NSMutableDictionary dictionaryWithCapacity:3];
	
	if (added.count > 0)
	{
		// changeset: {
		//   added: [
		//     idx, ...
		//   ],
		//   ...
		// }
		
		changeset[kChangeset_added] = [added copy];
	}
	
	if (deleted.count > 0)
	{
		// changeset: {
		//   deleted: {
		//     idx: obj, ...
		//   },
		//   ...
		// }
		
		changeset[kChangeset_deleted] = [deleted copy];
	}
	
	if (moved.count > 0)
	{
		// changeset: {
		//   moved: {
		//     idx: idx, ...
		//   },
		//   ...
		// }
		
		changeset[kChangeset_moved] = [moved copy];
	}
	
	return changeset;
}

/**
 * See ZDCSyncable.h for method description.
 */
- (nullable NSDictionary *)changeset
{
	NSDictionary *changeset = [self _changeset];
	[self clearChangeTracking];
	
	return changeset;
}

/**
 * See ZDCSyncable.h for method description.
 */
- (nullable NSDictionary *)peakChangeset
{
	return [self _changeset];
}

- (BOOL)isMalformedChangeset:(NSDictionary *)changeset
{
	if (changeset.count == 0) {
		return NO;
	}
	
	{ // Scoping
		
		// changeset: {
		//   added: NSIndexSet
		//   ...
		// }
		
		NSIndexSet *changeset_added = changeset[kChangeset_added];
		if (changeset_added)
		{
			if (![changeset_added isKindOfClass:[NSIndexSet class]]) {
				return YES;
			}
		}
	}
	{ // Scoping
		
		// changeset: {
		//   deleted: {
		//     idx: obj, ...
		//   },
		//   ...
		// }
		
		NSDictionary *changeset_deleted = changeset[kChangeset_deleted];
		if (changeset_deleted)
		{
			if (![changeset_deleted isKindOfClass:[NSDictionary class]]) {
				return YES;
			}
			
			for (NSString *index in changeset_deleted)
			{
				if (![index isKindOfClass:[NSNumber class]]) {
					return YES;
				}
			}
		}
	}
	{ // Scoping
		
		// changeset: {
		//   moved: {
		//     idx: idx, ...
		//   },
		//   ...
		// }
		
		NSDictionary *changeset_moved = changeset[kChangeset_moved];
		if (changeset_moved)
		{
			if (![changeset_moved isKindOfClass:[NSDictionary class]]) {
				return YES;
			}
			
			for (id key in changeset_moved)
			{
				if (![key isKindOfClass:[NSNumber class]]) {
					return YES;
				}
				
				id value = changeset_moved[key];
				
				if (![value isKindOfClass:[NSNumber class]]) {
					return YES;
				}
			}
		}
	}
	
	// Looks good (not malformed)
	return NO;
}

- (NSError *)_undo:(NSDictionary *)changeset
{
	// Important: `isMalformedChangeset:` must be called before invoking this method.
	
	// This method is called from both `undo::` & `importChangesets::`.
	//
	// When called from `undo::`, there aren't any existing changes,
	// and we can simplify (+optimize) some of our code.
	//
	// However that's sometimes not the case when called from `importChangesets::`.
	// So we have to guard for that situation.
	
	BOOL const isSimpleUndo = ![self hasChanges];
	
	// Change tracking algorithm:
	//
	// We have 3 sources of information to apply:
	//
	// - Added items
	//
	//     Each item that was added will be represented in the respective set.
	//
	// - Moved items
	//
	//     For each item that was moved, we have the 'newIndex' and 'oldIndex'.
	//
	// - Deleted items
	//
	//     For each item that was deleted, we have the 'obj' and 'oldIndex'.
	//
	//
	// In order for the algorithm to work, the 3 sources of information MUST be
	// applied 1-at-a-time, and in a specific order. Moving backwards,
	// from [current state] to [previous state] the order is:
	//
	//                       direction    <=       this      <=     in      <=      read
	// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
	
	// Step 1 of 3:
	//
	// Undo added objects.
	
	NSIndexSet *changeset_added = changeset[kChangeset_added];
	if (changeset_added.count > 0)
	{
		[changeset_added enumerateIndexesWithOptions: NSEnumerationReverse
		                                  usingBlock:^(NSUInteger idx, BOOL *stop)
		{
			[self removeObjectAtIndex:idx];
		}];
	}
	
	// Step 2 of 3:
	//
	// Undo move operations
	
	NSDictionary *changeset_moved = changeset[kChangeset_moved];
	if (changeset_moved.count > 0)
	{
		// We need to fix the `changeset_moved` dictionary.
		//
		// Here's the deal:
		// We're trying to track both items that were added, and items that were moved.
		// To accomplish this task, we use 2 data structures:
		//
		// - NSMutableIndexSet *added;                         // [{ currentIndex }]
		// - NSMutableDictionary<NSNumber*, NSNumber*> *moved; // key={currentIndex}, value={previousIndex}
		//
		// OK, but wait...
		// The currentIndex of items within the 'moved' dictionary could represent either:
		//
		// Option A: the currentIndex of items BEFORE undoing added objects
		// Option B: the currentIndex of items AFTER undoing added objects
		//
		// It turns out that option B is MUCH EASIER to work with.
		// It only requires this fixup operation here,
		// to update the currentIndex to match the current state (since we just undid add operations).
		
		if (changeset_added)
		{
			NSMutableDictionary *fixup = [NSMutableDictionary dictionaryWithCapacity:changeset_moved.count];
			
			for (NSNumber *num in changeset_moved)
			{
				__block NSUInteger currentIdx = num.unsignedIntegerValue;
	
				[changeset_added enumerateIndexesWithOptions: NSEnumerationReverse
				                                  usingBlock:^(NSUInteger addedIdx, BOOL *stop)
				{
					if (currentIdx > addedIdx) {
						currentIdx--;
					}
				}];
	
				fixup[@(currentIdx)] = changeset_moved[num];
			}
	
			changeset_moved = fixup;
		}
		
		// We have a list of tuples representing {currentIndex, previousIndex}.
		// So for each object, we need to:
		// - remove it from it's currentIndex
		// - add it back in it's previousIndex
		//
		// And we need to keep track of the changeset as we're doing this.
		
		if (moved == nil) {
			moved = [[NSMutableDictionary alloc] init];
		}
		
		NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
		NSMutableArray *tuplesToReAdd = [NSMutableArray array];
		
		for (NSNumber *num in changeset_moved)
		{
			NSUInteger currentIdx = num.unsignedIntegerValue;
			NSUInteger previousIdx = [changeset_moved[num] unsignedIntegerValue];
			
			if (isSimpleUndo)
			{
				moved[@(previousIdx)] = @(currentIdx); // just flip-flopping the values
			}
			
			[indexesToRemove addIndex:currentIdx];
			
			if (currentIdx >= array.count) {
				return [self mismatchedChangeset];
			}
			
			id obj = array[currentIdx];
			[tuplesToReAdd addObject:@[ @(previousIdx), obj ]];
		}
		
		[tuplesToReAdd sortUsingComparator:
			^NSComparisonResult(NSArray *tuple1, NSArray *tuple2)
		{
			NSNumber *idx1 = tuple1[0];
			NSNumber *idx2 = tuple2[0];
			
			return [idx1 compare:idx2];
		}];
		
		if (!isSimpleUndo)
		{
			// We're importing changesets - aka merging multiple changesets into one changeset
			
			// Import: 1 of 5
			//
			// Calculate the originalArray (excluding delete operations)
			
			NSMutableArray<id> *originalArray = [NSMutableArray arrayWithCapacity:array.count];
			
			for (NSUInteger idx = 0; idx < array.count; idx++)
			{
				if (![added containsIndex:idx] && (moved[@(idx)] == nil))
				{
					[originalArray addObject:array[idx]];
				}
			}
			
			NSArray<NSNumber*> *moved_sortedKeys_byPreviousIdx =
				[moved keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
			
			for (NSNumber *num in moved_sortedKeys_byPreviousIdx)
			{
				NSUInteger currentIdx = num.unsignedIntegerValue;
				
				id obj = array[currentIdx];
				NSUInteger previousIdx = [moved[num] unsignedIntegerValue];
				
				[originalArray insertObject:obj atIndex:previousIdx];
			}
			
			// Import: 2 of 5
			//
			// We're about to move a bunch of items around.
			// This means we need to fixup the `added` & `moved` indexes.
			//
			// Start by removing all the target items from the `moved` dictionary.
			// We're going to replace them momentarily with updated keys.
			
			NSMutableIndexSet *wasAdded = [[NSMutableIndexSet alloc] init];
			
			for (NSNumber *num_currentIdx in changeset_moved)
			{
				moved[num_currentIdx] = nil; // remove current value, will replace next
				
				NSUInteger currentIdx = num_currentIdx.unsignedIntegerValue;
				
				if ([added containsIndex:currentIdx])
				{
					[added removeIndex:currentIdx];
					[wasAdded addIndex:currentIdx];
				}
			}
			
			// Import: 3 of 5
			//
			// Fixup the `added` & `moved` indexes.
			
			[indexesToRemove enumerateIndexesWithOptions: NSEnumerationReverse
			                                  usingBlock:^(NSUInteger idxToRemove, BOOL *stop)
			{
			#pragma clang diagnostic push
			#pragma clang diagnostic ignored "-Wimplicit-retain-self"
				
				[self shiftAddedIndexesStartingAtIndex:idxToRemove by:-1];
				[self decrementMovedCurrentIndexesStartingAtIndex:idxToRemove];
				
			#pragma clang diagnostic pop
			}];
			
			for (NSArray *tuple in tuplesToReAdd)
			{
				NSUInteger idxToAdd = [tuple[0] unsignedIntegerValue];
				
				[self shiftAddedIndexesStartingAtIndex:idxToAdd by:1];
				[self incrementMovedCurrentIndexesStartingAtIndex:idxToAdd];
			}
			
			// Import: 4 of 5
			//
			// For all the items we're moving, add them into the `moved` dictionary.
			
			[changeset_moved enumerateKeysAndObjectsUsingBlock:
				^(NSNumber *num_currentIdx, NSNumber *num_targetIdx, BOOL *stop)
			{
			#pragma clang diagnostic push
			#pragma clang diagnostic ignored "-Wimplicit-retain-self"
				
				NSUInteger currentIdx = num_currentIdx.unsignedIntegerValue;
				NSUInteger targetIdx = num_targetIdx.unsignedIntegerValue;
				
				// currentIdx :
				//   Where item is in current state of array.
				//   However:
				//   - current state of array doesn't represent original state of array
				//   - current state of array doesn't represent final state of array
				// targetIdx :
				//   Where we're going to put the item (i.e. it's currentIdx AFTER we've performed moves)
				
				if ([wasAdded containsIndex:currentIdx])
				{
					[added addIndex:targetIdx];
				}
				else
				{
					id targetObj = array[currentIdx];
				
					NSUInteger originalIdx = [originalArray indexOfObjectIdenticalTo:targetObj];
					if (originalIdx != NSNotFound)
					{
						moved[@(targetIdx)] = @(originalIdx);
					}
				}
				
			#pragma clang diagnostic pop
			}];
		}
		
		// Import: 5 of 5
		//
		// Perform the actual move (within the underlying array).
		
		[array removeObjectsAtIndexes:indexesToRemove];
		
		for (NSArray *tuple in tuplesToReAdd)
		{
			NSUInteger idx = [tuple[0] unsignedIntegerValue];
			id obj = tuple[1];
			
			if (idx > array.count) {
				return [self mismatchedChangeset];
			}
			[array insertObject:obj atIndex:idx];
		}
	}
	
	// Step 3 of 3:
	//
	// Undo deleted objects.
	
	NSDictionary *changeset_deleted = changeset[kChangeset_deleted];
	if (changeset_deleted.count > 0)
	{
		NSMutableArray<NSNumber*> *sorted = [[changeset_deleted allKeys] mutableCopy];
		
		[sorted sortUsingComparator:^NSComparisonResult(NSNumber *idx1, NSNumber *idx2) {
			
			return [idx1 compare:idx2];
		}];
		
		for (NSNumber *num in sorted)
		{
			id obj = changeset_deleted[num];
			NSUInteger index = num.unsignedIntegerValue;
			
			[self insertObject:obj atIndex:index];
		}
	}
	
	return nil;
}

/**
 * See ZDCSyncable.h for method description.
 */
- (nullable NSDictionary *)undo:(NSDictionary *)changeset error:(NSError **)errPtr
{
	NSError *error = [self performUndo:changeset];
	if (error)
	{
		if (errPtr) *errPtr = error;
		return nil;
	}
	else
	{
		// Undo successful - generate redo changeset
		NSDictionary *reverseChangeset = [self changeset];
		
		if (errPtr) *errPtr = nil;
		return (reverseChangeset ?: @{}); // don't return nil without error
	}
}

/**
 * See ZDCSyncable.h for method description.
 */
- (nullable NSError *)performUndo:(NSDictionary *)changeset
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if ([self hasChanges])
	{
		// You cannot invoke this method if the object currently has changes.
		// The code doesn't know what you want to happen.
		// Are you asking us to throw away the current changes ?
		// Are you expecting us to magically merge everything ?
		return [self hasChangesError];
	}
	
	if ([self isMalformedChangeset:changeset])
	{
		return [self malformedChangesetError];
	}
	
	NSError *error = [self _undo:changeset];
	if (error)
	{
		// Abandon botched undo attempt - revert to original state
		[self rollback];
	}
	
	return error;
}

/**
 * See ZDCSyncable.h for method description.
 */
- (void)rollback
{
	NSDictionary *changeset = [self changeset];
	if (changeset)
	{
		[self undo:changeset error:nil];
	}
}

/**
 * See ZDCSyncable.h for method description.
 */
- (nullable NSDictionary *)mergeChangesets:(NSArray<NSDictionary*> *)orderedChangesets
                                     error:(NSError *_Nullable *_Nullable)errPtr
{
	NSError *error = [self importChangesets:orderedChangesets];
	if (error)
	{
		if (errPtr) *errPtr = error;
		return nil;
	}
	else
	{
		NSDictionary *mergedChangeset = [self changeset];
		
		if (errPtr) *errPtr = nil;
		return (mergedChangeset ?: @{}); // don't return nil without error
	}
}

- (nullable NSError *)importChangesets:(NSArray<NSDictionary*> *)orderedChangesets
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if ([self hasChanges])
	{
		// You cannot invoke this method if the object currently has changes.
		// The code doesn't know what you want to happen.
		// Are you asking us to throw away the current changes ?
		// Are you expecting us to magically merge everything ?
		return [self hasChangesError];
	}
	
	// Check for malformed changesets.
	// It's better to detect this early on, before we start modifying the object.
	//
	for (NSDictionary *changeset in orderedChangesets)
	{
		if ([self isMalformedChangeset:changeset])
		{
			return [self malformedChangesetError];
		}
	}
	
	if (orderedChangesets.count == 0) {
		return nil;
	}
	
	NSError *result_error = nil;
	NSMutableArray<NSDictionary*> *changesets_redo = [NSMutableArray arrayWithCapacity:orderedChangesets.count];
	
	for (NSDictionary *changeset in [orderedChangesets reverseObjectEnumerator])
	{
		result_error = [self _undo:changeset];
		if (result_error)
		{
			// Abort botched attempt - Revert to original state (before current `_undo:`)
			[self rollback];
			
			// We still need to revert previous `_undo:` calls
			break;
		}
		else
		{
			NSDictionary *redo = [self changeset];
			if (redo) {
				[changesets_redo addObject:redo];
			}
		}
	}
	
	for (NSDictionary *redo in [changesets_redo reverseObjectEnumerator])
	{
		NSError *error = [self _undo:redo];
		if (error)
		{
			// Not much we can do here - we're in a bad state
			if (result_error == nil) {
				result_error = error;
			}
			
			break;
		}
	}
	
	return result_error;
}

/**
 * Calculates the original order from the changesets.
 */
+ (BOOL)getOriginalOrder:(NSArray<id> **)outOriginalOrder
                   added:(NSArray<id> **)outAdded
                 deleted:(NSArray<id> **)outDeleted
                    from:(NSArray<id> *)inOrder
       pendingChangesets:(NSArray<NSDictionary*> *)pendingChangesets
{
	// Important: `isMalformedChangeset:` must be called before invoking this method.
	
	NSMutableArray<id> *order = [inOrder mutableCopy];
	NSMutableArray<id> *added = [NSMutableArray array];
	NSMutableArray<id> *deleted = [NSMutableArray array];
	
	for (NSDictionary *changeset in [pendingChangesets reverseObjectEnumerator])
	{
		// IMPORTANT:
		//
		// All of this code comes from the `_undo:` method.
		// It's been changed to modify only the `order` ivar.
		//
		// For documentation & discussion of this code & logic,
		// please see the `_undo:` method.
		
		// Step 1 of 3:
		//
		// Undo added objects.
	
		NSIndexSet *changeset_added = changeset[kChangeset_added];
		if (changeset_added.count > 0)
		{
			__block BOOL mismatch = NO;
			[changeset_added enumerateIndexesWithOptions: NSEnumerationReverse
			                                  usingBlock:^(NSUInteger idx, BOOL *stop)
			{
				if (idx >= order.count) {
					mismatch = YES;
					*stop = YES;
					return;
				}
				
				id obj = order[idx];
				if ([deleted containsObject:obj])
				{
					// This item is deleted in a later changeset.
					// So the two actions cancel each other out.
					[deleted removeObject:obj];
				}
				else
				{
					[added addObject:obj];
				}
				
				[order removeObjectAtIndex:idx];
			}];
			
			if (mismatch) {
				return NO;
			}
		}
		
		// Step 2 of 3:
		//
		// Undo move operations
		
		NSDictionary *changeset_moved = changeset[kChangeset_moved];
		if (changeset_moved.count > 0)
		{
			if (changeset_added)
			{
				NSMutableDictionary *fixup = [NSMutableDictionary dictionaryWithCapacity:changeset_moved.count];
	
				for (NSNumber *num in changeset_moved)
				{
					__block NSUInteger currentIdx = num.unsignedIntegerValue;
	
					[changeset_added enumerateIndexesWithOptions: NSEnumerationReverse
					                                  usingBlock:^(NSUInteger addedIdx, BOOL *stop)
					{
						if (currentIdx > addedIdx) {
							currentIdx--;
						}
					}];
	
					fixup[@(currentIdx)] = changeset_moved[num];
				}
	
				changeset_moved = fixup;
			}
			
			NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
			NSMutableArray *tuplesToReAdd = [NSMutableArray array];
			
			for (NSNumber *num in changeset_moved)
			{
				NSUInteger currentIdx = num.unsignedIntegerValue;
				NSUInteger previousIdx = [changeset_moved[num] unsignedIntegerValue];
				
				[indexesToRemove addIndex:currentIdx];
				
				if (currentIdx >= order.count) {
					return NO; // mismatchedChangeset
				}
				
				id obj = order[currentIdx];
				[tuplesToReAdd addObject:@[ @(previousIdx), obj ]];
			}
			
			[tuplesToReAdd sortUsingComparator:
				^NSComparisonResult(NSArray *tuple1, NSArray *tuple2)
			{
				NSNumber *idx1 = tuple1[0];
				NSNumber *idx2 = tuple2[0];
	
				return [idx1 compare:idx2];
			}];
			
			[order removeObjectsAtIndexes:indexesToRemove];
			
			for (NSArray *tuple in tuplesToReAdd)
			{
				NSUInteger idx = [tuple[0] unsignedIntegerValue];
				id obj = tuple[1];
				
				if (idx > order.count) {
					return NO; // mismatchedChangeset
				}
				
				[order insertObject:obj atIndex:idx];
			}
		}
		
		// Step 3 of 3:
		//
		// Undo deleted objects.
	
		NSDictionary *changeset_deleted = changeset[kChangeset_deleted];
		if (changeset_deleted.count > 0)
		{
			NSMutableArray<NSNumber*> *sorted = [[changeset_deleted allKeys] mutableCopy];
	
			[sorted sortUsingComparator:^NSComparisonResult(NSNumber *idx1, NSNumber *idx2) {
	
				return [idx1 compare:idx2];
			}];
	
			for (NSNumber *num in sorted)
			{
				id obj = changeset_deleted[num];
				NSUInteger index = num.unsignedIntegerValue;
				
				if (index > order.count) {
					return NO; // mismatchedChangeset
				}
				
				if ([added containsObject:obj])
				{
					// This object gets re-added in a later changeset.
					// So the two actions cancel each other out.
					[added removeObject:obj];
				}
				else
				{
					[deleted addObject:obj];
				}
	
				[order insertObject:obj atIndex:index];
			}
		}
	}
	
	*outOriginalOrder = order;
	*outAdded = added;
	*outDeleted = deleted;
	
	return YES;
}

- (nullable NSDictionary *)mergeCloudVersion:(id)inCloudVersion
                       withPendingChangesets:(nullable NSArray<NSDictionary*> *)pendingChangesets
                                       error:(NSError *_Nullable *_Nullable)errPtr
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if ([self hasChanges])
	{
		// You cannot invoke this method if the object currently has changes.
		// The code doesn't know what you want to happen.
		// Are you asking us to throw away the current changes ?
		// Are you expecting us to magically merge everything ?
		if (errPtr) *errPtr = [self hasChangesError];
		return nil;
	}
	
	// Check for malformed changesets.
	// It's better to detect this early on, before we start modifying the object.
	//
	for (NSDictionary *changeset in pendingChangesets)
	{
		if ([self isMalformedChangeset:changeset])
		{
			if (errPtr) *errPtr = [self malformedChangesetError];
			return nil;
		}
	}
	
	if (![inCloudVersion isKindOfClass:[self class]])
	{
		if (errPtr) *errPtr = [self incorrectObjectClass];
		return nil;
	}
	ZDCArray *cloudVersion = (ZDCArray *)inCloudVersion;
	
	// Step 1 of 6:
	//
	// If there are pending changes, calculate the original order.
	// This will be used later on during the merge process.
	//
	// We also get the list of added & removed objects while we're at it.
	//
	// Important:
	//   We need to do this in the beginning, because we need an unmodified `array`.
	
	NSArray<id> *originalOrder = nil;
	NSArray<id> *local_added = nil;
	NSArray<id> *local_deleted = nil;
	
	if (pendingChangesets.count > 0)
	{
		BOOL success = [[self class] getOriginalOrder: &originalOrder
		                                        added: &local_added
		                                      deleted: &local_deleted
		                                         from: array
		                            pendingChangesets: pendingChangesets];
		if (!success)
		{
			if (errPtr) *errPtr = [self mismatchedChangeset];
			return nil;
		}
	}
	
	// Step 2 of 6:
	//
	// Add objects that were added by remote devices.
	
	NSUInteger const preAddedCount = array.count;
	{
		NSMutableArray *localArray = [self->array mutableCopy];
		
		for (id obj in cloudVersion->array)
		{
			NSUInteger localIdx = [localArray indexOfObject:obj];
			if (localIdx == NSNotFound)
			{
				// Object exists in cloudVersion, but not in localVersion.
	
				if ([local_deleted containsObject:obj]) {
					// We've deleted the object locally, but haven't pushed changes to cloud yet.
				}
				else {
					// Object added by remote device.
					[self addObject:obj];
				}
			}
			else
			{
				[localArray removeObjectAtIndex:localIdx];
			}
		}
	}
	
	// Step 3 of 6:
	//
	// Delete objects that were deleted by remote devices.
	{
		NSMutableArray *cloudArray = [cloudVersion->array mutableCopy];
		NSUInteger i = 0;
		
		for (NSUInteger k = 0; k < preAddedCount; k++)
		{
			id obj = array[i];
			
			NSUInteger cloudIdx = [cloudArray indexOfObject:obj];
			if (cloudIdx == NSNotFound)
			{
				// Object exists in localVersion, but not in cloudVersion.
		
				if ([local_added containsObject:obj]) {
					// We've added the object locally, but haven't pushed changes to cloud yet.
					i++;
				}
				else {
					// Object deleted by remote device.
					
					[self removeObjectAtIndex:i];
				}
			}
			else
			{
				[cloudArray removeObjectAtIndex:cloudIdx];
				i++;
			}
		}
	}
	
	// Step 4 of 6:
	//
	// Prepare to merge the order.
	//
	// At this point, we've added every obj that was in the cloudVersion, but not in our localVersion.
	// And we've deleted every obj that was deleted from the cloudVersion.
	//
	// Another change we need to take into consideration are obj's that we've deleted locally.
	//
	// Our aim here is to derive 2 arrays, one from cloudVersion, and another from self.
	// Both of these arrays will have the same count, and contain the same objs, but possibly in a different order.
	
	NSMutableArray *order_localVersion = [NSMutableArray arrayWithCapacity:array.count];
	NSMutableArray *order_cloudVersion = [NSMutableArray arrayWithCapacity:array.count];
	
	{
		NSMutableArray *cloudArray = [cloudVersion->array mutableCopy];
		
		for (id obj in self->array)
		{
			NSUInteger idx = [cloudArray indexOfObject:obj];
			if (idx != NSNotFound)
			{
				[cloudArray removeObjectAtIndex:idx];
				[order_localVersion addObject:obj];
			}
		}
	}
	{
		NSMutableArray *localArray = [self->array mutableCopy];
		
		for (id obj in cloudVersion->array)
		{
			NSUInteger idx = [localArray indexOfObject:obj];
			if (idx != NSNotFound)
			{
				[localArray removeObjectAtIndex:idx];
				[order_cloudVersion addObject:obj];
			}
		}
	}
	
	NSAssert(order_localVersion.count == order_cloudVersion.count, @"Logic error");
	
	// Step 5 of 6:
	//
	// So now we have a 2 lists of items that we can compare: local vs cloud.
	// But when we detect a difference between the lists, what does that tell us ?
	//
	// It could mean:
	// - the location was changed remotely
	// - the location was changed locally
	// - or both (in which case remote wins)
	//
	// So we're going to need to make an "educated guess" as to which items
	// might have been moved by a remote device.
	
	NSMutableArray<id> *movedObjs_remote = nil;
	
	if (pendingChangesets.count == 0)
	{
		movedObjs_remote = [cloudVersion->array mutableCopy];
	}
	else // if (pendingChangesets.count > 0)
	{
		NSMutableArray *order_originalVersion = [NSMutableArray arrayWithCapacity:originalOrder.count];
		NSMutableArray *order_cloudVersion = [NSMutableArray arrayWithCapacity:originalOrder.count];
		
		{
			NSMutableArray *cloudArray = [cloudVersion->array mutableCopy];
			
			for (id obj in originalOrder)
			{
				NSUInteger idx = [cloudArray indexOfObject:obj];
				if (idx != NSNotFound)
				{
					[cloudArray removeObjectAtIndex:idx];
					[order_originalVersion addObject:obj];
				}
			}
		}
		{
			NSMutableArray *localOriginalArray = [originalOrder mutableCopy];
			
			for (id obj in cloudVersion->array)
			{
				NSUInteger idx = [localOriginalArray indexOfObject:obj];
				if (idx != NSNotFound)
				{
					[localOriginalArray removeObjectAtIndex:idx];
					[order_cloudVersion addObject:obj];
				}
			}
		}
		
		NSAssert(order_originalVersion.count == order_cloudVersion.count, @"Logic error");
		
		NSArray *estimate =
			[ZDCOrder estimateChangesetFrom: order_originalVersion
			                             to: order_cloudVersion
			                          hints: nil];
		
		movedObjs_remote = [estimate mutableCopy];
	}
	
	// Step 6 of 6:
	//
	// We have all the information we need to merge the order now.
	
	for (NSUInteger i = 0; i < order_cloudVersion.count; i++)
	{
		id obj_remote = order_cloudVersion[i];
		id obj_local  = order_localVersion[i];
		
		if (![obj_remote isEqual:obj_local])
		{
			BOOL changed_remote = NO;
			{
				NSUInteger idx = [movedObjs_remote indexOfObject:obj_remote];
				if (idx != NSNotFound)
				{
					changed_remote = YES;
					[movedObjs_remote removeObjectAtIndex:idx];
				}
			}
			
			if (changed_remote)
			{
				// Remote wins.
				
				id obj = obj_remote;
				
				// Move key into proper position (with changed_local)
				
				NSRange searchRange = NSMakeRange(i+1, order_localVersion.count-i-1);
				NSUInteger idx = [order_localVersion indexOfObject:obj inRange:searchRange];
				
				[order_localVersion removeObjectAtIndex:idx];
				[order_localVersion insertObject:obj atIndex:i];
				
				// Move key into proper position (within orderedSet)
				//
				// Note:
				//   We already added all the objects that were added by remote devices.
				//   And we already deleted all the objects that were deleted by remote devices.
				
				NSUInteger oldIdx = [self indexOfObject:obj];
				NSUInteger newIdx = 0;
				if (i > 0)
				{
					id prvObj_local = order_localVersion[i-1];
					newIdx = [self indexOfObject:prvObj_local] + 1;
				}
				
				[self moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
			else
			{
				// Local wins.
				
				id obj = obj_local;
				
				// Move remote into proper position (with changed_remote)
				
				NSRange searchRange = NSMakeRange(i+1, order_cloudVersion.count-i-1);
				NSUInteger idx = [order_cloudVersion indexOfObject:obj inRange:searchRange];
				
				[order_cloudVersion removeObjectAtIndex:idx];
				[order_cloudVersion insertObject:obj atIndex:i];
			}
		}
	}
	
	if (errPtr) *errPtr = nil;
	return ([self changeset] ?: @{});
}

@end

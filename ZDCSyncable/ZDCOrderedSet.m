/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCOrderedSet.h"

#import "ZDCObjectSubclass.h"
#import "ZDCOrder.h"

// Encoding/Decoding Keys
//
static int const kCurrentVersion = 0;
#pragma unused(kCurrentVersion)

static NSString *const kCoding_version    = @"version";
static NSString *const kCoding_orderedSet = @"orderedSet";

// Changeset Keys
//
static NSString *const kChangeset_added   = @"added";
static NSString *const kChangeset_indexes = @"indexes";
static NSString *const kChangeset_deleted = @"deleted";


@implementation ZDCOrderedSet {
@private
	
	NSMutableOrderedSet<id> *orderedSet;
	
	NSMutableSet<id> *added;
	NSMutableDictionary<id, NSNumber*> *originalIndexes;
	NSMutableDictionary<id, NSNumber*> *deletedIndexes;
}

@dynamic rawOrderedSet;
@dynamic count;
@dynamic firstObject;
@dynamic lastObject;

- (instancetype)init
{
	if ((self = [super init]))
	{
		orderedSet = [[NSMutableOrderedSet alloc] init];
	}
	return self;
}

- (instancetype)initWithArray:(nullable NSArray<id> *)inArray
{
	return [self initWithArray:inArray copyItems:NO];
}

- (instancetype)initWithArray:(nullable NSArray<id> *)inArray copyItems:(BOOL)flag
{
	if ((self = [super init]))
	{
		orderedSet = inArray ?
		  [[NSMutableOrderedSet alloc] initWithArray:inArray copyItems:flag] :
		  [[NSMutableOrderedSet alloc] init];
		
		if (orderedSet.count > 0)
		{
			added = [[NSMutableSet alloc] initWithCapacity:orderedSet.count];
			
			for (id obj in orderedSet)
			{
				[added addObject:obj];
			}
		}
	}
	return self;
}

- (instancetype)initWithSet:(nullable NSSet<id> *)inSet
{
	return [self initWithSet:inSet copyItems:NO];
}

- (instancetype)initWithSet:(nullable NSSet<id> *)inSet copyItems:(BOOL)flag
{
	if ((self = [super init]))
	{
		orderedSet = inSet ?
		  [[NSMutableOrderedSet alloc] initWithSet:inSet copyItems:flag] :
		  [[NSMutableOrderedSet alloc] init];
		
		if (orderedSet.count > 0)
		{
			added = [[NSMutableSet alloc] initWithCapacity:orderedSet.count];
			
			for (id obj in orderedSet)
			{
				[added addObject:obj];
			}
		}
	}
	return self;
}

- (instancetype)initWithOrderedSet:(nullable NSOrderedSet<id> *)inOrderedSet
{
	return [self initWithOrderedSet:inOrderedSet copyItems:NO];
}

- (instancetype)initWithOrderedSet:(nullable NSOrderedSet<id> *)inOrderedSet copyItems:(BOOL)flag
{
	if ((self = [super init]))
	{
		orderedSet = inOrderedSet ?
		  [[NSMutableOrderedSet alloc] initWithOrderedSet:inOrderedSet copyItems:flag] :
		  [[NSMutableOrderedSet alloc] init];
		
		if (orderedSet.count > 0)
		{
			added = [[NSMutableSet alloc] initWithCapacity:orderedSet.count];
			
			for (id obj in orderedSet)
			{
				[added addObject:obj];
			}
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
		orderedSet = [decoder decodeObjectForKey:kCoding_orderedSet];
		
		if (orderedSet == nil) {
			orderedSet = [[NSMutableOrderedSet alloc] init];
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
	
	[coder encodeObject:orderedSet forKey:kCoding_orderedSet];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)copyWithZone:(NSZone *)zone
{
	ZDCOrderedSet *copy = [super copyWithZone:zone]; // [ZDCObject copyWithZone:]
	
	copy->orderedSet = [self->orderedSet mutableCopy];
	
	copy->added           = [self->added mutableCopy];
	copy->originalIndexes = [self->originalIndexes mutableCopy];
	copy->deletedIndexes  = [self->deletedIndexes mutableCopy];
	
	return copy;
}

/**
 * For complicated copying scenarios, such as nested deep copies.
 * This method is declared in: ZDCObjectSubclass.h
 */
- (void)copyChangeTrackingTo:(id)another
{
	if ([another isKindOfClass:[ZDCOrderedSet class]])
	{
		__unsafe_unretained ZDCOrderedSet *copy = (ZDCOrderedSet *)another;
		if (!copy.isImmutable)
		{
			copy->added           = [self->added mutableCopy];
			copy->originalIndexes = [self->originalIndexes mutableCopy];
			copy->deletedIndexes  = [self->deletedIndexes mutableCopy];
			
			[super copyChangeTrackingTo:another];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Raw
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSOrderedSet<id> *)rawOrderedSet
{
	return [orderedSet copy];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)count
{
	return orderedSet.count;
}

- (id)firstObject
{
	return orderedSet.firstObject;
}

- (id)lastObject
{
	return orderedSet.lastObject;
}

- (BOOL)containsObject:(id)object
{
	return [orderedSet containsObject:object];
}

- (id)objectAtIndex:(NSUInteger)idx
{
	return [orderedSet objectAtIndex:idx];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
	return [orderedSet objectAtIndexedSubscript:idx];
}

- (NSUInteger)indexOfObject:(id)object
{
	return [orderedSet indexOfObject:object];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Writing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addObject:(id)obj
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (obj == nil) return;
	
	if (![orderedSet containsObject:obj])
	{
		[self _willInsertObject:obj atIndex:orderedSet.count];
		[orderedSet addObject:obj];
	}
}

- (void)insertObject:(id)obj atIndex:(NSUInteger)requestedIdx
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (obj == nil) return;
	
	if (![orderedSet containsObject:obj])
	{
		NSUInteger idx;
		if (requestedIdx <= orderedSet.count) {
			idx = requestedIdx;
		}
		else {
			idx = orderedSet.count;
		}
		
		[self _willInsertObject:obj atIndex:idx];
		[orderedSet insertObject:obj atIndex:idx];
	}
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
	[self insertObject:obj atIndex:idx];
}

- (void)moveObjectAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if (oldIndex >= orderedSet.count) {
		return;
	}
	if (newIndex >= orderedSet.count) {
		newIndex = orderedSet.count - 1;
	}
	if (oldIndex == newIndex) {
		return;
	}
	
	id obj = orderedSet[oldIndex];
	[self _willMoveObject:obj fromIndex:oldIndex toIndex:newIndex];
	
	[orderedSet removeObjectAtIndex:oldIndex];
	[orderedSet insertObject:obj atIndex:newIndex];
}

- (void)removeObject:(id)obj
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (obj == nil) return;
	
	NSUInteger idx = [orderedSet indexOfObject:obj];
	if (idx != NSNotFound)
	{
		[self _willRemoveObject:obj atIndex:idx];
		[orderedSet removeObjectAtIndex:idx];
	}
}

- (void)removeObjectAtIndex:(NSUInteger)idx
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if (idx < orderedSet.count)
	{
		id obj = orderedSet[idx];
		
		[self _willRemoveObject:obj atIndex:idx];
		[orderedSet removeObjectAtIndex:idx];
	}
}

- (void)removeAllObjects
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	while (orderedSet.count > 0)
	{
		id obj = orderedSet[0];
		
		[self _willRemoveObject:obj atIndex:0];
		[orderedSet removeObjectAtIndex:0];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Change Tracking Internals
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)_willInsertObject:(id)obj atIndex:(NSUInteger const)idx
{
	NSParameterAssert(obj != nil);
	NSParameterAssert(idx <= orderedSet.count);
	
	if (added == nil) {
		added = [[NSMutableSet alloc] init];
	}
	
	// INSERT: Step 1 of 2:
	//
	// Update added as needed.
	
	[added addObject:obj];
	
	// INSERT: Step 2 of 2:
	//
	// If we're re-adding an item that was deleted within this changeset,
	// then we need to remove it from the deleted list.
	
	deletedIndexes[obj] = nil;
}

- (void)_willRemoveObject:(id)obj atIndex:(NSUInteger const)idx
{
	NSParameterAssert(obj != nil);
	NSParameterAssert(idx < orderedSet.count);
	
	if (added == nil) {
		added = [[NSMutableSet alloc] init];
	}
	if (originalIndexes == nil) {
		originalIndexes = [[NSMutableDictionary alloc] init];
	}
	if (deletedIndexes == nil) {
		deletedIndexes = [[NSMutableDictionary alloc] init];
	}
	
	// REMOVE: 1 of 3
	//
	// Update `added` as needed.
	// And check to see if we're deleting a item that was added within changeset.
	
	BOOL wasAddedThenDeleted = NO;
	
	if ([added containsObject:obj])
	{
		// Value was added within snapshot, and is now being removed
		wasAddedThenDeleted = YES;
		[added removeObject:obj];
	}
	
	// If we're deleting an item that was also added within this changeset,
	// then the two actions cancel each other out.
	//
	// Otherwise, this is a legitamate delete, and we need to record it.
	
	if (!wasAddedThenDeleted)
	{
		// REMOVE: Step 2 of 3:
		//
		// Add the item to `removedIndexes`.
		// And to do so, we need to know the correct originalIndex.
		//
		// Remember that our goal is to create a changeset that can be used to undo this change.
		// So it's important to understand the order in which the undo operation operates:
		//
		//                       direction    <=       this      <=     in      <=      read
		// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
		//
		// We can see that undoing delete operations is the last step.
		// So we need to take this into account by taking into consideration moves, adds & previous deletes.
		
		NSUInteger originalIdx = idx;
		NSUInteger originalIdx_addMoveOnly = idx;
	
		// Check items that were moved/added within this changeset
		
		if (originalIndexes[obj] != nil)
		{
			// Shortcut - we've already tracked & calculated the originalIndex.
			//
			// Actually, this is more than just a shortcut.
			// Since the item being deleted is already in originalIndexes,
			// this would throw off our calculations below.
			//
			
			originalIdx = [originalIndexes[obj] unsignedIntegerValue];
		}
		else
		{
			NSMutableArray<NSString*> *originalOrder = [NSMutableArray arrayWithCapacity:orderedSet.count];
			for (id obj in orderedSet)
			{
				if ((originalIndexes[obj] == nil) && (![added containsObject:obj]))
				{
					[originalOrder addObject:obj];
				}
			}
		
			NSArray<NSString*> *sortedKeys = [originalIndexes keysSortedByValueUsingComparator:
				^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
	
			for (id key in sortedKeys)
			{
				NSUInteger prvIdx = [originalIndexes[key] unsignedIntegerValue];
	
				[originalOrder insertObject:key atIndex:prvIdx];
			}
	
			originalIdx = [originalOrder indexOfObject:obj];
		}
		
		originalIdx_addMoveOnly = originalIdx;
		
		{ // Check items that were deleted within this changeset
		
			NSArray<NSString*> *sortedKeys = [deletedIndexes keysSortedByValueUsingComparator:
				^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
		
			for (id key in sortedKeys)
			{
				NSNumber *deletedIdx = deletedIndexes[key];
				if ([deletedIdx unsignedIntegerValue] <= originalIdx)
				{
					// An item was deleted in front of us within this changeset. (front=lower_index)
					originalIdx++;
				}
			}
		}
		
	#ifndef NS_BLOCK_ASSERTIONS
		[self checkDeletedIndexes:originalIdx];
	#endif
		deletedIndexes[obj] = @(originalIdx);
		
		// REMOVE: Step 3 of 3:
		//
		// Remove deleted item from originalIndexes.
		//
		// And recall that we undo deletes AFTER we undo moves.
		// So we need to fixup the originalIndexes so everything works as expected.
		
		originalIndexes[obj] = nil;
		
		for (NSString *altKey in [originalIndexes allKeys])
		{
			NSUInteger altIdx = [(NSNumber *)originalIndexes[altKey] unsignedIntegerValue];
			if (altIdx >= originalIdx_addMoveOnly) {
				originalIndexes[altKey] = @(altIdx - 1);
			}
		}
		
	#ifndef NS_BLOCK_ASSERTIONS
		[self checkOriginalIndexes];
	#endif
	}
}

- (void)_willMoveObject:(id)obj
              fromIndex:(NSUInteger const)oldIdx
                toIndex:(NSUInteger const)newIdx
{
	NSParameterAssert(obj != nil);
	NSParameterAssert(oldIdx < orderedSet.count);
	NSParameterAssert(newIdx <= orderedSet.count);
	NSParameterAssert(oldIdx != newIdx);
	
	if (originalIndexes == nil) {
		originalIndexes = [[NSMutableDictionary alloc] init];
	}
	
	// MOVE: Step 1 of 1:
	//
	// We need to add the item to originalIndexes (if it's not already listed).
	// And to do so, we need to know the correct originalIndex.
	//
	// However, we cannot simply use oldIdx.
	// Previous moves within the changeset may have scewed the oldIdx such that's it's no longer accurate.
	//
	// Also, remember that we don't have to concern ourselves with deletes.
	// This is because of the order in which the undo operation operates:
	//
	//                       direction    <=       this      <=     in      <=       read
	// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
	//
	// We will undo moves before we undo deletes.
	
	if ((originalIndexes[obj] == nil) && (![added containsObject:obj]))
	{
		__block NSUInteger originalIdx = oldIdx;
		
		NSMutableArray<NSString*> *originalOrder = [NSMutableArray arrayWithCapacity:orderedSet.count];
		for (id obj in orderedSet)
		{
			if ((originalIndexes[obj] == nil) && (![added containsObject:obj]))
			{
				[originalOrder addObject:obj];
			}
		}
	
		NSArray<NSString*> *sortedKeys = [originalIndexes keysSortedByValueUsingComparator:
			^NSComparisonResult(NSNumber *num1, NSNumber *num2)
		{
			return [num1 compare:num2];
		}];
		
		for (NSString *key in sortedKeys)
		{
			NSUInteger prvIdx = [originalIndexes[key] unsignedIntegerValue];
		
			[originalOrder insertObject:key atIndex:prvIdx];
		}
		
		originalIdx = [originalOrder indexOfObject:obj];
		
	#ifndef NS_BLOCK_ASSERTIONS
		[self checkOriginalIndexes:originalIdx];
	#endif
		originalIndexes[obj] = @(originalIdx);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Sanity Checks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#ifndef NS_BLOCK_ASSERTIONS

- (void)checkOriginalIndexes
{
	NSMutableIndexSet *existing = [[NSMutableIndexSet alloc] init];
	
	for (id obj in originalIndexes)
	{
		NSUInteger originalIdx = [originalIndexes[obj] unsignedIntegerValue];
		NSAssert(originalIdx != NSNotFound, @"Calculated originalIdx is wrong (within originalIndexes)");
		
		if ([existing containsIndex:originalIdx])
		{
			NSAssert(NO, @"Modified originalIndexes is wrong (within originalIndexes)");
		}
		
		[existing addIndex:originalIdx];
	}
}

- (void)checkOriginalIndexes:(NSUInteger)originalIdx
{
	NSAssert(originalIdx != NSNotFound, @"Calculated originalIdx is wrong (for originalIndexes)");
	
	for (id obj in originalIndexes)
	{
		NSNumber *existing = originalIndexes[obj];
		if ([existing unsignedIntegerValue] == originalIdx)
		{
			NSAssert(NO, @"Calculated originalIdx is wrong (for originalIndexes)");
		}
	}
}

- (void)checkDeletedIndexes:(NSUInteger)originalIdx
{
	NSAssert(originalIdx != NSNotFound, @"Calculated originalIdx is wrong (for deletedIndexes)");
	
	for (id obj in deletedIndexes)
	{
		NSNumber *existing = deletedIndexes[obj];
		if ([existing unsignedIntegerValue] == originalIdx)
		{
			NSAssert(NO, @"Calculated originalIdx is wrong (for deletedIndexes)");
		}
	}
}

#endif
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Enumeration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block
{
	[orderedSet enumerateObjectsUsingBlock:block];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len
{
	return [orderedSet countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSEnumerator<id> *)objectEnumerator
{
	return [orderedSet objectEnumerator];
}

- (NSEnumerator<id> *)reverseObjectEnumerator
{
	return [orderedSet reverseObjectEnumerator];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Equality
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isEqual:(nullable id)another
{
	if ([another isKindOfClass:[ZDCOrderedSet class]]) {
		return [self isEqualToOrderedSet:(ZDCOrderedSet *)another];
	}
	else {
		return NO;
	}
}

- (BOOL)isEqualToOrderedSet:(nullable ZDCOrderedSet *)another
{
	if (another == nil) return NO; // null dereference crash ahead
	
	return [self->orderedSet isEqualToOrderedSet:another->orderedSet];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark ZDCObject Overrides
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)makeImmutable
{
	[super makeImmutable];
	
	for (id obj in orderedSet)
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
	
	if (added.count           > 0 ||
	    originalIndexes.count > 0 ||
	    deletedIndexes.count  > 0  ) return YES;
	
	for (id obj in orderedSet)
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
	
	[added removeAllObjects];
	[originalIndexes removeAllObjects];
	[deletedIndexes removeAllObjects];
	
	for (id obj in orderedSet)
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
	
	NSMutableDictionary<NSString*, id> *changeset = [NSMutableDictionary dictionaryWithCapacity:3];
	
	if (added.count > 0)
	{
		// changeset: {
		//   added: [{
		//     obj, ...
		//   }],
		//   ...
		// }
		
		NSMutableSet *changeset_added = [NSMutableSet setWithCapacity:added.count];
		
		for (id obj in added)
		{
			if ([obj conformsToProtocol:@protocol(NSCopying)]) {
				[changeset_added addObject:[obj copy]];
			}
			else {
				[changeset_added addObject:obj];
			}
		}
		
		changeset[kChangeset_added] = [changeset_added copy];
	}
	
	if (originalIndexes.count > 0)
	{
		// changeset: {
		//   indexes: {
		//     obj: oldIndex, ...
		//   },
		//   ...
		// }
		
		NSMutableDictionary *changeset_indexes = [NSMutableDictionary dictionaryWithCapacity:originalIndexes.count];
		
		[originalIndexes enumerateKeysAndObjectsUsingBlock:^(id obj, NSNumber *oldIndex, BOOL *stop) {
			
			NSUInteger newIndex = [self indexOfObject:obj];
			if (newIndex != NSNotFound) {
				changeset_indexes[obj] = oldIndex;
			}
		}];
		
		if (changeset_indexes.count > 0) {
			changeset[kChangeset_indexes] = [changeset_indexes copy];
		}
	}
	
	if (deletedIndexes.count > 0)
	{
		// changeset: {
		//   deleted: {
		//     obj: oldIndex, ...
		//   },
		//   ...
		// }
		//
		// Note: The object is being used as the key in a dictionary.
		
		changeset[kChangeset_deleted] = [deletedIndexes copy];
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
		
		NSSet *changeset_added = changeset[kChangeset_added];
		if (changeset_added)
		{
			if (![changeset_added isKindOfClass:[NSSet class]]) {
				return YES;
			}
		}
	}
	{ // Scoping
		
		NSDictionary *changeset_indexes = changeset[kChangeset_indexes];
		if (changeset_indexes)
		{
			if (![changeset_indexes isKindOfClass:[NSDictionary class]]) {
				return YES;
			}
			
			// All values must be numbers.
			// All number must not be NSNotFound.
			
			for (id key in changeset_indexes)
			{
				id value = changeset_indexes[key];
				if (![value isKindOfClass:[NSNumber class]]) {
					return YES;
				}
				
				NSUInteger idx = [value unsignedIntegerValue];
				if (idx == NSNotFound) {
					return YES;
				}
			}
		}
	}
	{ // Scoping
		
		NSDictionary *changeset_deleted = changeset[kChangeset_deleted];
		if (changeset_deleted)
		{
			if (![changeset_deleted isKindOfClass:[NSDictionary class]]) {
				return YES;
			}
			
			// All values must be numbers.
			// All number must not be NSNotFound.
			
			for (id key in changeset_deleted)
			{
				id value = changeset_deleted[key];
				if (![value isKindOfClass:[NSNumber class]]) {
					return YES;
				}
				
				NSUInteger idx = [value unsignedIntegerValue];
				if (idx == NSNotFound) {
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
	//     For each item that was moved, we have the 'obj' and 'oldIndex'.
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
	// Undo added objects & restore previous values.
	
	NSSet *changeset_added = changeset[kChangeset_added];
	if (changeset_added.count > 0)
	{
		for (id obj in changeset_added)
		{
			if ([self containsObject:obj])
			{
				[self removeObject:obj];
			}
		}
	}
	
	// Step 2 of 3:
	//
	// Undo move operations
	
	NSDictionary *changeset_moves = changeset[kChangeset_indexes];
	if (changeset_moves.count > 0)
	{
		// We have a list of objects, and their originalIndexes.
		// So for each object, we need to:
		// - remove it from it's currentIndex
		// - add it back in it's originalIndex
		//
		// And we need to keep track of the changeset (originalIndexes) as we're doing this.
		
		if (originalIndexes == nil) {
			originalIndexes = [[NSMutableDictionary alloc] init];
		}
		
		NSMutableArray<id> *moved_objs = [NSMutableArray arrayWithCapacity:changeset_moves.count];
		NSMutableIndexSet *moved_indexes = [[NSMutableIndexSet alloc] init];
		
		for (id obj in changeset_moves)
		{
			NSUInteger idx = [self indexOfObject:obj];
			if (idx != NSNotFound) // shouldn't happen; sanity check
			{
				if (isSimpleUndo)
				{
				#ifndef NS_BLOCK_ASSERTIONS
					[self checkOriginalIndexes:idx];
				#endif
					
					originalIndexes[obj] = @(idx);
				}
				
				[moved_objs addObject:obj];
				[moved_indexes addIndex:idx];
			}
		}
		
		if (!isSimpleUndo)
		{
			NSMutableArray<NSString*> *originalOrder = [NSMutableArray arrayWithCapacity:orderedSet.count];
			
			for (id obj in orderedSet)
			{
				if ((originalIndexes[obj] == nil) && (![added containsObject:obj]))
				{
					[originalOrder addObject:obj];
				}
			}
			
			NSArray<id> *sorted = [originalIndexes keysSortedByValueUsingComparator:
				^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
			
			for (id obj in sorted)
			{
				NSUInteger prvIdx = [originalIndexes[obj] unsignedIntegerValue];
				[originalOrder insertObject:obj atIndex:prvIdx];
			}
			
			for (id moved_obj in moved_objs)
			{
				if (originalIndexes[moved_obj] == nil)
				{
					NSUInteger originalIdx = [originalOrder indexOfObject:moved_obj];
					if (originalIdx != NSNotFound)
					{
					#ifndef NS_BLOCK_ASSERTIONS
						[self checkOriginalIndexes:originalIdx];
					#endif
						originalIndexes[moved_obj] = @(originalIdx);
					}
					else
					{
						// Might be the case during an `importChanges::` operation,
						// where an item was added in changeset_A, and moved in changeset_B.
					}
				}
			}
		}
		
		[orderedSet removeObjectsAtIndexes:moved_indexes];
	
		// Sort keys by targetIdx (originalIdx).
		// We want to add them from lowest idx to highest idx.
		[moved_objs sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			
			NSNumber *idx1 = changeset_moves[obj1];
			NSNumber *idx2 = changeset_moves[obj2];
			
			return [idx1 compare:idx2];
		}];
		
		for (id moved_obj in moved_objs)
		{
			NSUInteger idx = [changeset_moves[moved_obj] unsignedIntegerValue];
			if (idx > orderedSet.count) {
				return [self mismatchedChangeset];
			}
			[orderedSet insertObject:moved_obj atIndex:idx];
		}
	}
	
	// Step 3 of 3:
	//
	// Undo deleted objects.
	
	NSDictionary *changeset_deleted = changeset[kChangeset_deleted];
	if (changeset_deleted.count > 0)
	{
		NSMutableArray<NSString*> *sorted = [[changeset_deleted allKeys] mutableCopy];
		
		[sorted sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			
			NSNumber *idx1 = changeset_deleted[obj1];
			NSNumber *idx2 = changeset_deleted[obj2];
			
			return [idx1 compare:idx2];
		}];
		
		for (id oldObj in sorted)
		{
			NSUInteger index = [(NSNumber *)changeset_deleted[oldObj] unsignedIntegerValue];
			
			[self insertObject:oldObj atIndex:index];
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

/**
 * See ZDCSyncable.h for method description.
 */
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
+ (nullable NSArray<id> *)_originalOrderFrom:(NSArray<id> *)inOrder
                           pendingChangesets:(NSArray<NSDictionary*> *)pendingChangesets
{
	// Important: `isMalformedChangeset:` must be called before invoking this method.
	
	NSMutableArray<id> *order = [inOrder mutableCopy];
	
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
		
		NSSet *changeset_added = changeset[kChangeset_added];
		if (changeset_added.count > 0)
		{
			for (id obj in changeset_added)
			{
				NSUInteger idx = [order indexOfObject:obj];
				if (idx != NSNotFound)
				{
					[order removeObjectAtIndex:idx];
				}
			}
		}
		
		// Step 2 of 3:
		//
		// Undo move operations
	
		NSDictionary *changeset_moves = changeset[kChangeset_indexes];
		if (changeset_moves.count > 0)
		{
			// We have a list of objects, and their originalIndexes.
			// So for each object, we need to:
			// - remove it from it's currentIndex
			// - add it back in it's originalIndex
	
			NSMutableArray<id> *moved_objs = [NSMutableArray arrayWithCapacity:changeset_moves.count];
			NSMutableIndexSet *moved_indexes = [[NSMutableIndexSet alloc] init];
	
			for (id obj in changeset_moves)
			{
				NSUInteger idx = [order indexOfObject:obj];
				if (idx != NSNotFound) // shouldn't happen; sanity check
				{
					[moved_objs addObject:obj];
					[moved_indexes addIndex:idx];
				}
			}
			
			[order removeObjectsAtIndexes:moved_indexes];
	
			// Sort keys by targetIdx (originalIdx).
			// We want to add them from lowest idx to highest idx.
			[moved_objs sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
	
				NSNumber *idx1 = changeset_moves[obj1];
				NSNumber *idx2 = changeset_moves[obj2];
	
				return [idx1 compare:idx2];
			}];
	
			for (id moved_obj in moved_objs)
			{
				NSUInteger idx = [changeset_moves[moved_obj] unsignedIntegerValue];
				if (idx > order.count)
				{
					return nil;
				}
				[order insertObject:moved_obj atIndex:idx];
			}
		}
		
		// Step 3 of 3:
		//
		// Undo deleted objects.
	
		NSDictionary *changeset_deleted = changeset[kChangeset_deleted];
		if (changeset_deleted.count > 0)
		{
			NSMutableArray<NSString*> *sorted = [[changeset_deleted allKeys] mutableCopy];
	
			[sorted sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
	
				NSNumber *idx1 = changeset_deleted[obj1];
				NSNumber *idx2 = changeset_deleted[obj2];
	
				return [idx1 compare:idx2];
			}];
	
			for (id oldObj in sorted)
			{
				NSUInteger idx = [(NSNumber *)changeset_deleted[oldObj] unsignedIntegerValue];
				if (idx > order.count)
				{
					return nil;
				}
				[order insertObject:oldObj atIndex:idx];
			}
		}
	}

	return order;
}

/**
 * See ZDCSyncable.h for method description.
 */
- (nullable NSDictionary *)mergeCloudVersion:(id)inCloudVersion
                       withPendingChangesets:(nullable NSArray<NSDictionary *> *)pendingChangesets
                                       error:(NSError *__autoreleasing  _Nullable * _Nullable)errPtr
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
	ZDCOrderedSet *cloudVersion = (ZDCOrderedSet *)inCloudVersion;
	
	// Step 1 of 7:
	//
	// If there are pending changes, calculate the original order.
	// This will be used later on during the merge process.
	//
	// Important:
	//   We need to do this in the beginning, because we need an unmodified `orderedSet`.
	
	NSArray<id> *originalOrder = nil;
	if (pendingChangesets.count > 0)
	{
		originalOrder = [[self class] _originalOrderFrom:[orderedSet array] pendingChangesets:pendingChangesets];
		if (originalOrder == nil)
		{
			if (errPtr) *errPtr = [self mismatchedChangeset];
			return nil;
		}
	}
	
	// Step 2 of 7:
	//
	// Determine which objects have been added & deleted (locally, based on pendingChangesets)
	
	NSMutableSet *local_added = nil;
	NSMutableSet *local_deleted = nil;
	
	if (pendingChangesets.count > 0)
	{
		local_added = [NSMutableSet set];
		local_deleted = [NSMutableSet set];
		
		for (NSDictionary *changeset in pendingChangesets)
		{
			NSSet *changeset_added = changeset[kChangeset_added];
			NSSet *changeset_deleted = changeset[kChangeset_deleted];
			
			for (id obj in changeset_added)
			{
				if ([local_deleted containsObject:obj]) {
					[local_deleted removeObject:obj];
				}
				else {
					[local_added addObject:obj];
				}
			}
			for (id obj in changeset_deleted)
			{
				if ([local_added containsObject:obj]) {
					[local_added removeObject:obj];
				}
				else {
					[local_deleted addObject:obj];
				}
			}
		}
	}
	
	// Step 3 of 7:
	//
	// Add objects that were added by remote devices.
	
	for (id obj in cloudVersion->orderedSet)
	{
		if (![self->orderedSet containsObject:obj])
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
	}
	
	// Step 4 of 7:
	//
	// Delete objects that were deleted by remote devices.
	
	NSMutableArray *deleteMe = nil;
	
	for (id obj in self->orderedSet) // enumerating self->orderedSet => cannot be modified during enumeration
	{
		if (![cloudVersion->orderedSet containsObject:obj])
		{
			// Object exists in localVersion, but not in cloudVersion.
			
			if ([local_added containsObject:obj]) {
				// We've added the object locally, but haven't pushed changes to cloud yet.
			}
			else {
				// Object deleted by remote device.
				if (deleteMe == nil) {
					deleteMe = [NSMutableArray array];
				}
				
				[deleteMe addObject:obj];
			}
		}
	}
	
	for (id obj in deleteMe)
	{
		[self removeObject:obj];
	}
	
	// Step 5 of 7:
	//
	// Prepare to merge the order.
	// 
	// At this point, we've added every obj that was in the cloudVersion, but not in our localVersion.
	// And we've deleted every obj that was deleted from the cloudVersion.
	//
	// Another change we need to take into consideration are obj's that we've deleted locally.
	//
	// Our aim here is to derive 2 arrays, one from cloudVersion->order, and another from self->order.
	// Both of these arrays will have the same count, and contain the same objs, but possibly in a different order.
	
	NSMutableArray *order_localVersion = [[self->orderedSet array] mutableCopy];
	NSMutableArray *order_cloudVersion = [[cloudVersion->orderedSet array] mutableCopy];
	
	{
		NSMutableSet *merged = [[self->orderedSet set] mutableCopy];
		[merged intersectSet:[cloudVersion->orderedSet set]];
		
		NSUInteger i = 0;
		while (i < order_localVersion.count)
		{
			id obj = order_localVersion[i];
			if ([merged containsObject:obj]) {
				i++;
			}
			else {
				[order_localVersion removeObjectAtIndex:i];
			}
		}
		
		i = 0;
		while (i < order_cloudVersion.count)
		{
			id obj = order_cloudVersion[i];
			if ([merged containsObject:obj]) {
				i++;
			}
			else {
				[order_cloudVersion removeObjectAtIndex:i];
			}
		}
	}
	
	// Step 6 of 7:
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
	
	NSMutableSet<id> *movedObjs_remote = [NSMutableSet set];
	
	if (pendingChangesets.count == 0)
	{
		[movedObjs_remote addObjectsFromArray:[cloudVersion->orderedSet array]];
	}
	else // if (pendingChangesets.count > 0)
	{
		NSMutableSet *merged = [NSMutableSet setWithArray:originalOrder];
		[merged intersectSet:[cloudVersion->orderedSet set]];
		
		NSMutableArray *order_originalVersion = [originalOrder mutableCopy];
		NSMutableArray *order_cloudVersion = [[cloudVersion->orderedSet array] mutableCopy];
		
		NSUInteger i = 0;
		while (i < order_originalVersion.count)
		{
			id obj = order_originalVersion[i];
			if ([merged containsObject:obj]) {
				i++;
			}
			else {
				[order_originalVersion removeObjectAtIndex:i];
			}
		}
		
		i = 0;
		while (i < order_cloudVersion.count)
		{
			id obj = order_cloudVersion[i];
			if ([merged containsObject:obj]) {
				i++;
			}
			else {
				[order_cloudVersion removeObjectAtIndex:i];
			}
		}
		
		NSArray *estimate =
			[ZDCOrder estimateChangesetFrom: order_originalVersion
			                            to: order_cloudVersion
			                         hints: nil];
		
		[movedObjs_remote addObjectsFromArray:estimate];
	}
	
	// Step 7 of 7:
	//
	// We have all the information we need to merge the order now.
	
	for (NSUInteger i = 0; i < order_cloudVersion.count; i++)
	{
		id obj_remote = order_cloudVersion[i];
		id obj_local  = order_localVersion[i];
		
		if (![obj_remote isEqual:obj_local])
		{
			BOOL changed_remote = [movedObjs_remote containsObject:obj_remote];
			
			if (changed_remote)
			{
				// Remote wins.
				
				id obj = obj_remote;
				
				// Move key into proper position (within changed_local)
				
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
				
				// Move remote into proper position (within changed_remote)
				
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

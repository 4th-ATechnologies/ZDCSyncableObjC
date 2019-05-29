/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCOrderedDictionary.h"

#import "ZDCObjectSubclass.h"
#import "ZDCNull.h"
#import "ZDCOrder.h"
#import "ZDCRef.h"

// Encoding/Decoding Keys
//
static int const kCurrentVersion = 0;
#pragma unused(kCurrentVersion)

static NSString *const kCoding_version = @"version";
static NSString *const kCoding_dict    = @"dict";
static NSString *const kCoding_order   = @"order";

// Changeset Keys
//
static NSString *const kChangeset_refs    = @"refs";
static NSString *const kChangeset_values  = @"values";
static NSString *const kChangeset_indexes = @"indexes";
static NSString *const kChangeset_deleted = @"deleted";

/**
 * Changeset Tracking Architecture:
 *
 * We use a technique called "snapshot transform".
 *
 * Snapshot transform encodes all the changes that have occurred between snapshot A & B,
 * and does so in such a manner as to minimize the size of the changeset.
 * This is helpful in the context of cloud syncing, as only the snapshots are destined for syncing,
 * and the changesets must be stored to disk (for assistence in merging & conflict resolution).
 *
 * Given the following information:
 * - current state of object
 * - changeset
 *
 * We can move backwards in time to the previous state of the object.
 * This is accomplished by calling the 'undo' method, and passing in a changest.
 * The 'undo' method also returns a changeset, which can be used to 'redo' the changes it made.
 *
 * (So both undo & redo are supported. But there is only a single method used for both operations.)
 *
 * Snapshot transform also allows us to limit the size of a changeset by merging all changes between "snapshots".
 * For example, when moving from state X to Y, there may have been transitional states X1, X2, X3, etc.
 * The changeset does not track the transitional states. It only allows you to move back to state X.
 *
 * This optimization is capable of supporting undo/redo operations in a user interface,
 * while still remaining optimized for a system where changesets must be stored to disk.
 *
 * For example, imagine a situation where the a user is making changes to an object.
 * Within the user interface, we want to support undo & redo for all the little changes the user has made.
 * However, when we save the object to disk, we only need a changeset that reflects
 * the changes from the previous stored state.
 *
 * To support this, the object allows you to call the snapshot method which will return a changeset.
 * This can be used for undo operations. And when you're ready to save the object to disk,
 * you can merge all the snapshot changesets into a single merged changeset.
**/
@implementation ZDCOrderedDictionary {
@private
	
	NSMutableDictionary<id, id> *dict;
	NSMutableArray<id> *order;
	
	NSMutableDictionary<id, id> *originalValues;
	NSMutableDictionary<id, NSNumber*> *originalIndexes;
	NSMutableDictionary<id, NSNumber*> *deletedIndexes;
}

@dynamic rawDictionary;
@dynamic rawOrder;
@dynamic count;
@dynamic firstObject;
@dynamic lastObject;

- (instancetype)init
{
	return [self initWithDictionary:nil copyItems:NO];
}

- (instancetype)initWithDictionary:(nullable NSDictionary<id, id> *)inRaw
{
	return [self initWithDictionary:inRaw copyItems:NO];
}

- (instancetype)initWithDictionary:(nullable NSDictionary<id, id> *)inRaw copyItems:(BOOL)flag
{
	if ((self = [super init]))
	{
		NSUInteger capacity = inRaw ? inRaw.count : 4;
		
		dict = [[NSMutableDictionary alloc] initWithCapacity:capacity];
		order = [[NSMutableArray alloc] initWithCapacity:capacity];
		
		originalValues = [[NSMutableDictionary alloc] initWithCapacity:capacity];
		
		[inRaw enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			
			self->dict[key] = flag ? [obj copy] : obj;
			[self->order addObject:key];
			
			self->originalValues[key] = [ZDCNull null];
		}];
	}
	return self;
}

- (instancetype)initWithOrderedDictionary:(nullable ZDCOrderedDictionary<id, id> *)another
{
	return [self initWithOrderedDictionary:another copyItems:NO];
}

- (instancetype)initWithOrderedDictionary:(nullable ZDCOrderedDictionary<id, id> *)another copyItems:(BOOL)flag
{
	if ((self = [super init]))
	{
		NSUInteger capacity = another ? another.count : 4;
		
		dict = [[NSMutableDictionary alloc] initWithCapacity:capacity];
		order = [[NSMutableArray alloc] initWithCapacity:capacity];
		
		originalValues = [[NSMutableDictionary alloc] initWithCapacity:capacity];
		
		[another enumerateKeysAndObjectsUsingBlock:^(id key, id obj, NSUInteger idx, BOOL *stop) {
			
			self->dict[key] = flag ? [obj copy] : obj;
			[self->order addObject:key];
			
			self->originalValues[key] = [ZDCNull null];
		}];
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
		dict = [decoder decodeObjectForKey:kCoding_dict];
		order = [decoder decodeObjectForKey:kCoding_order];
		
		if (dict == nil) {
			dict = [[NSMutableDictionary alloc] init];
		}
		if (order == nil) {
			order = [[NSMutableArray alloc] init];
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
	
	[coder encodeObject:dict forKey:kCoding_dict];
	[coder encodeObject:order forKey:kCoding_order];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)copyWithZone:(NSZone *)zone
{
	ZDCOrderedDictionary *copy = [super copyWithZone:zone]; // [ZDCObject copyWithZone:]
	
	copy->dict = [self->dict mutableCopy];
	copy->order = [self->order mutableCopy];
	
	copy->originalValues = [self->originalValues mutableCopy];
	copy->originalIndexes = [self->originalIndexes mutableCopy];
	copy->deletedIndexes = [self->deletedIndexes mutableCopy];
	
	return copy;
}

/**
 * For complicated copying scenarios, such as nested deep copies.
 * This method is declared in: ZDCObjectSubclass.h
 */
- (void)copyChangeTrackingTo:(id)another
{
	if ([another isKindOfClass:[ZDCOrderedDictionary class]])
	{
		__unsafe_unretained ZDCOrderedDictionary *copy = (ZDCOrderedDictionary *)another;
		if (!copy.isImmutable)
		{
			copy->originalValues = [self->originalValues mutableCopy];
			copy->originalIndexes = [self->originalIndexes mutableCopy];
			copy->deletedIndexes = [self->deletedIndexes mutableCopy];
			
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
- (NSDictionary<NSString*, id> *)rawDictionary
{
	return [dict copy];
}

/**
 * See header file for description.
 */
- (NSArray<NSString*> *)rawOrder
{
	return [order copy];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * See header file for description.
 */
- (NSUInteger)count
{
	return order.count;
}

/**
 * See header file for description.
 */
- (nullable id)firstObject
{
	if (order.count > 0)
		return order[0];
	else
		return nil;
	
}

/**
 * See header file for description.
 */
- (nullable id)lastObject
{
	if (order.count > 0)
		return order[order.count-1];
	else
		return nil;
}

/**
 * See header file for description.
 */
- (NSArray<id> *)allKeys
{
	return [order copy];
}

/**
 * See header file for description.
 */
- (BOOL)containsKey:(id)key
{
	if (key)
		return CFDictionaryContainsKey((CFDictionaryRef)dict, (const void *)key);
	else
		return NO;
}

/**
 * See header file for description.
 */
- (NSUInteger)indexForKey:(id)key
{
	if (![self containsKey:key]) {
		return NSNotFound;
	}
	
	return [order indexOfObject:key];
}

/**
 * See header file for description.
 */
- (nullable id)objectForKey:(id)key
{
	return [dict objectForKey:key];
}

/**
 * See header file for description.
 */
- (id)keyAtIndex:(NSUInteger)idx
{
	return order[idx];
}

/**
 * See header file for description.
 */
- (id)objectAtIndex:(NSUInteger)idx
{
	id key = order[idx];
	return dict[key];
}

/**
 * See header file for description.
 */
- (nullable id)objectForKeyedSubscript:(id)key
{
	return dict[key];
}

/**
 * See header file for description.
 */
- (nullable id)objectAtIndexedSubscript:(NSUInteger)idx
{
	id key = order[idx];
	return dict[key];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Writing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * See header file for description.
 */
- (void)setObject:(nullable id)object forKey:(id)key
{
	if (object == nil) {
		[self removeObjectForKey:key];
		return;
	}
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (key == nil) {
		return;
	}
	
	if ([self containsKey:key])
	{
		[self _willUpdateValueForKey:key];
		
		dict[key] = object;
	}
	else
	{
		NSUInteger index = order.count;
		[self _willInsertObjectAtIndex:index withKey:key];
		
		dict[key] = object;
		[order addObject:[key copy]]; // [key copy] => mutable string protection
	}
}

/**
 * See header file for description.
 */
- (void)setObject:(nullable id)object forKeyedSubscript:(id)key
{
	[self setObject:object forKey:key];
}

/**
 * Allows for syntax: dict[index] = value;
 */
/*
 * This doesn't seem to work...
 * Compiler complains when caller uses syntax: dict[index] = value;
 *
- (void)setObject:(nullable id)object atIndexedSubscript:(NSUInteger)idx
{
	if (object == nil) {
		[self removeObjectAtIndex:idx];
		return;
	}
	if (self.isImmutable) {
		@throw [self immutableException];
	}

	if (idx >= order.count) return;
	NSString *key = order[idx];

	[self _willUpdateValueForKey:key];
 
	dict[key] = object;
}
*/

/**
 * See header file for description.
 */
- (NSUInteger)addObject:(id)object forKey:(id)key
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if (object == nil) return NSNotFound;
	if (key == nil) return NSNotFound;
	
	NSUInteger index = [self indexForKey:key];
	if (index == NSNotFound)
	{
		index = order.count - 1;
		[self _willInsertObjectAtIndex:index withKey:key];
		
		dict[key] = object;
		[order addObject:[key copy]]; // [key copy] => mutable string protection
	}
	else
	{
		[self _willUpdateValueForKey:key];
		dict[key] = object;
	}
	
	return index;
}

/**
 * See header file for description.
 */
- (NSUInteger)insertObject:(id)object forKey:(id)key atIndex:(NSUInteger)requestedIndex
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if (object == nil) return NSNotFound;
	if (key == nil) return NSNotFound;
	
	NSUInteger index = [self indexForKey:key];
	if (index == NSNotFound)
	{
		if (requestedIndex <= order.count) {
			index = requestedIndex;
		}
		else {
			index = order.count - 1;
		}
		
		[self _willInsertObjectAtIndex:index withKey:key];
		
		dict[key] = object;
		[order insertObject:[key copy] atIndex:index]; // [key copy] => mutable string protection
	}
	else
	{
		[self _willUpdateValueForKey:key];
		dict[key] = object;
	}
	
	return index;
}

/**
 * See header file for description.
 */
- (void)moveObjectAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if (oldIndex >= order.count) {
		return;
	}
	if (newIndex >= order.count) {
		newIndex = order.count - 1;
	}
	if (oldIndex == newIndex) {
		return;
	}
	
	NSString *key = order[oldIndex];
	[self _willMoveObjectFromIndex:oldIndex toIndex:newIndex withKey:key];
	
	[order removeObjectAtIndex:oldIndex];
	[order insertObject:key atIndex:newIndex];
}

/**
 * See header file for description.
 */
- (void)removeObjectForKey:(id)key
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	NSUInteger idx = [self indexForKey:key];
	if (idx == NSNotFound) {
		return;
	}
	
	[self _willRemoveObjectAtIndex:idx withKey:key];
	
	dict[key] = nil;
	[order removeObjectAtIndex:idx];
}

/**
 * See header file for descrition.
 */
- (void)removeObjectsForKeys:(NSArray<id> *)keys
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if (keys.count == 0) return;
	
	for (NSString *key in keys)
	{
		NSUInteger idx = [self indexForKey:key];
		if (idx == NSNotFound) {
			continue;
		}
		
		[self _willRemoveObjectAtIndex:idx withKey:key];
		
		dict[key] = nil;
		[order removeObjectAtIndex:idx];
	}
}

/**
 * See header file for description.
 */
- (void)removeObjectAtIndex:(NSUInteger)idx
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if (idx >= order.count) return;
	NSString *key = order[idx];
	
	[self _willRemoveObjectAtIndex:idx withKey:key];
	
	dict[key] = nil;
	[order removeObjectAtIndex:idx];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Change Tracking Internals
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)_willUpdateValueForKey:(id)key
{
	NSParameterAssert(key != nil);
	
	if (originalValues == nil) {
		originalValues = [[NSMutableDictionary alloc] init];
	}
	
	if (originalValues[key] == nil) {
		originalValues[key] = dict[key];
	}
}

- (void)_willInsertObjectAtIndex:(NSUInteger const)idx withKey:(id)key
{
	NSParameterAssert(idx <= order.count);
	NSParameterAssert(key != nil);
	
	if (originalValues == nil) {
		originalValues = [[NSMutableDictionary alloc] init];
	}
	
	// INSERT: Step 1 of 2:
	//
	// Update originalValues as needed.
	
	if (originalValues[key] == nil) {
		originalValues[key] = [ZDCNull null];
	}
	
	// INSERT: Step 2 of 2:
	//
	// If we're re-adding an item that was deleted within this changeset,
	// then we need to remove it from the deleted list.
	
	deletedIndexes[key] = nil;
}

- (void)_willRemoveObjectAtIndex:(NSUInteger const)idx withKey:(id)key
{
	NSParameterAssert(idx < order.count);
	NSParameterAssert(key != nil);
	
	if (originalValues == nil) {
		originalValues = [[NSMutableDictionary alloc] init];
	}
	if (originalIndexes == nil) {
		originalIndexes = [[NSMutableDictionary alloc] init];
	}
	if (deletedIndexes == nil) {
		deletedIndexes = [[NSMutableDictionary alloc] init];
	}
	
	// REMOVE: 1 of 3
	//
	// Update originalValues as needed.
	// And check to see if we're deleting a item that was added within changeset.
	
	BOOL wasAddedThenDeleted = NO;
	
	id originalValue = originalValues[key];
	if (originalValue == nil)
	{
		originalValues[key] = dict[key];
	}
	else if (originalValue == [ZDCNull null])
	{
		// Value was added within snapshot, and is now being removed
		wasAddedThenDeleted = YES;
		originalValues[key] = nil;
	}
	
	// If we're deleting an item that was also added within this changeset,
	// then the two actions cancel each other out.
	//
	// Otherwise, this is a legitamate delete, and we need to record it.
	
	if (!wasAddedThenDeleted)
	{
		// REMOVE: Step 2 of 3:
		//
		// Add the item to deletedIndexes.
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
		
		if (originalIndexes[key] != nil)
		{
			// Shortcut - we've already tracked & calculated the originalIndex.
			//
			// Actually, this is more than just a shortcut.
			// Since the item being deleted is already in originalIndexes,
			// this would throw off our calculations below.
			//
			
			originalIdx = [originalIndexes[key] unsignedIntegerValue];
		}
		else
		{
			NSMutableArray<id> *originalOrder = [NSMutableArray arrayWithCapacity:order.count];
			for (id key in order)
			{
				if ((originalIndexes[key] == nil) && (originalValues[key] != [ZDCNull null]))
				{
					[originalOrder addObject:key];
				}
			}
		
			NSArray<id> *sortedKeys = [originalIndexes keysSortedByValueUsingComparator:
				^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
	
			for (id key in sortedKeys)
			{
				NSUInteger prvIdx = [originalIndexes[key] unsignedIntegerValue];
	
				[originalOrder insertObject:key atIndex:prvIdx];
			}
	
			originalIdx = [originalOrder indexOfObject:key];
		}
		
		originalIdx_addMoveOnly = originalIdx;
		
		{ // Check items that were deleted within this changeset
		
			NSArray<id> *sortedKeys = [deletedIndexes keysSortedByValueUsingComparator:
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
		[self checkeDeletedIndexes:originalIdx];
	#endif
		deletedIndexes[key] = @(originalIdx);
		
		// REMOVE: Step 3 of 3:
		//
		// Remove deleted item from originalIndexes.
		//
		// And recall that we undo deletes AFTER we undo moves.
		// So we need to fixup the originalIndexes so everything works as expected.
		
		originalIndexes[key] = nil;
		
		for (id altKey in [originalIndexes allKeys])
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

- (void)_willMoveObjectFromIndex:(NSUInteger const)oldIdx
                         toIndex:(NSUInteger const)newIdx
                         withKey:(id)key
{
	NSParameterAssert(oldIdx < order.count);
	NSParameterAssert(newIdx <= order.count);
	NSParameterAssert(oldIdx != newIdx);
	NSParameterAssert(key != nil);
	
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
	
	if ((originalIndexes[key] == nil) && (originalValues[key] != [ZDCNull null]))
	{
		__block NSUInteger originalIdx = oldIdx;
		
		NSMutableArray<id> *originalOrder = [NSMutableArray arrayWithCapacity:order.count];
		for (id key in order)
		{
			if ((originalIndexes[key] == nil) && (originalValues[key] != [ZDCNull null]))
			{
				[originalOrder addObject:key];
			}
		}
	
		NSArray<id> *sortedKeys = [originalIndexes keysSortedByValueUsingComparator:
			^NSComparisonResult(NSNumber *num1, NSNumber *num2)
		{
			return [num1 compare:num2];
		}];
		
		for (id key in sortedKeys)
		{
			NSUInteger prvIdx = [originalIndexes[key] unsignedIntegerValue];
		
			[originalOrder insertObject:key atIndex:prvIdx];
		}
		
		originalIdx = [originalOrder indexOfObject:key];
		
	#ifndef NS_BLOCK_ASSERTIONS
		[self checkOriginalIndexes:originalIdx];
	#endif
		originalIndexes[key] = @(originalIdx);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Sanity Checks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#ifndef NS_BLOCK_ASSERTIONS

- (void)checkOriginalIndexes
{
	NSMutableIndexSet *existing = [[NSMutableIndexSet alloc] init];
	
	for (id key in originalIndexes)
	{
		NSUInteger originalIdx = [originalIndexes[key] unsignedIntegerValue];
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
	
	for (id key in originalIndexes)
	{
		NSNumber *existing = originalIndexes[key];
		if ([existing unsignedIntegerValue] == originalIdx)
		{
			NSAssert(NO, @"Calculated originalIdx is wrong (for originalIndexes)");
		}
	}
}

- (void)checkeDeletedIndexes:(NSUInteger)originalIdx
{
	NSAssert(originalIdx != NSNotFound, @"Calculated originalIdx is wrong (for deletedIndexes)");
	
	for (id key in deletedIndexes)
	{
		NSNumber *existing = deletedIndexes[key];
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

- (void)enumerateKeysUsingBlock:(void (^)(id key, NSUInteger idx, BOOL *stop))block
{
	[order enumerateObjectsUsingBlock:block];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, NSUInteger idx, BOOL *stop))block
{
	[order enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
		
		block(key, self->dict[key], idx, stop);
	}];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len
{
	return [order countByEnumeratingWithState:state objects:buffer count:len];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Equality
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isEqual:(nullable id)another
{
	if ([another isKindOfClass:[ZDCOrderedDictionary class]]) {
		return [self isEqualToOrderedDictionary:(ZDCOrderedDictionary *)another];
	}
	else {
		return NO;
	}
}

- (BOOL)isEqualToOrderedDictionary:(nullable ZDCOrderedDictionary *)another
{
	if (another == nil) return NO; // null dereference crash ahead
	
	if (![dict isEqualToDictionary:another->dict]) return NO;
	if (![order isEqualToArray:another->order]) return NO;
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark ZDCObject Overrides
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)makeImmutable
{
	[super makeImmutable];
	
	for (id obj in [dict objectEnumerator])
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
	
	if (originalValues.count  > 0 ||
	    originalIndexes.count > 0 ||
	    deletedIndexes.count  > 0  ) return YES;
	
	for (id obj in [dict objectEnumerator])
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
	
	[originalValues removeAllObjects];
	[originalIndexes removeAllObjects];
	[deletedIndexes removeAllObjects];
	
	for (id obj in [dict objectEnumerator])
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
	
	// changeset: {
	//   refs: {
	//     key: changeset, ...
	//   },
	//   ...
	// }
	
	__block NSMutableDictionary *refs = nil;
	
	void (^AddRef)(id, NSDictionary*) = ^(id key, NSDictionary *obj_changeset) {
		
		if (refs == nil) {
			refs = [[NSMutableDictionary alloc] init];
			changeset[kChangeset_refs] = refs;
		}
		
		refs[key] = obj_changeset;
	};
	
	[dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		
		if ([obj conformsToProtocol:@protocol(ZDCSyncable)])
		{
			id originalValue = self->originalValues[key];
			
			// Several possibilities:
			//
			// - If obj was added, then originalValue will be ZDCNull.
			//   If this is the case, we should not add to refs.
			//
			// - If obj was swapped out, then originalValue will be some other obj.
			//   If this is the case, we should not add to refs.
			//
			// - If obj was simply modified, then originalValue wll be the same as obj.
			//   And only then should we add a changeset to refs.
			
			BOOL wasAdded = (originalValue == [ZDCNull null]);
			BOOL wasSwapped = originalValue && (originalValue != obj);
			
			if (!wasAdded && !wasSwapped)
			{
				NSDictionary *obj_changeset = [(id<ZDCSyncable>)obj peakChangeset];
				if (obj_changeset == nil)
				{
					BOOL wasModified = originalValue != nil;
					if (wasModified) {
						obj_changeset = @{};
					}
				}
				
				if (obj_changeset) {
					AddRef(key, obj_changeset);
				}
			}
		}
	}];
	
	if (originalValues.count > 0)
	{
		// changeset: {
		//   values: {
		//     key: oldValue, ...
		//   },
		//   ...
		// }
		
		NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity:originalValues.count];
		
		[originalValues enumerateKeysAndObjectsUsingBlock:^(id key, id originalValue, BOOL *stop) {
			
			if (refs[key]) {
				values[key] = [ZDCRef ref];
			}
			else if ([originalValue conformsToProtocol:@protocol(NSCopying)]) {
				values[key] = [originalValue copy];
			}
			else {
				values[key] = originalValue;
			}
		}];
		
		changeset[kChangeset_values] = values;
	}
	
	if (originalIndexes.count > 0)
	{
		// changeset: {
		//   indexes: {
		//     key: oldIndex, ...
		//   },
		//   ...
		// }
		
		NSMutableDictionary *changeset_indexes = [NSMutableDictionary dictionaryWithCapacity:originalIndexes.count];
		
		[originalIndexes enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *oldIndex, BOOL *stop) {
			
			NSUInteger newIndex = [self indexForKey:key];
			if (newIndex != NSNotFound) {
				changeset_indexes[key] = oldIndex;
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
		//     key: oldIndex, ...
		//   },
		//   ...
		// }
		
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
	
	// changeset: {
	//   refs: {
	//     <key: Any> : <changeset: NSDictionary>, ...
	//   },
	//   values: {
	//     <key: Any> : <oldValue: ZDCNull|ZDCRef|Any>, ...
	//   },
	//   indexes: {
	//     <key: Any> : <oldIndex: NSNumber>, ...
	//   },
	//   deleted: {
	//     <key: Any> : <oldIndex: NSNumber>, ...
	//   }
	// }
	
	{ // refs
		
		NSDictionary *changeset_refs = changeset[kChangeset_refs];
		if (changeset_refs)
		{
			if (![changeset_refs isKindOfClass:[NSDictionary class]]) {
				return YES;
			}
			
			for (id obj in [(NSDictionary *)changeset_refs objectEnumerator])
			{
				if (![obj isKindOfClass:[NSDictionary class]]) {
					return YES;
				}
			}
		}
	}
	{ // values
		
		NSDictionary *changeset_values = changeset[kChangeset_values];
		if (changeset_values)
		{
			if (![changeset_values isKindOfClass:[NSDictionary class]]) {
				return YES;
			}
		}
	}
	{ // indexes
		
		NSDictionary *changeset_indexes = changeset[kChangeset_indexes];
		if (changeset_indexes)
		{
			if (![changeset_indexes isKindOfClass:[NSDictionary class]]) {
				return YES;
			}
	
			// All values must be numbers.
	
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
	{ // deleted
		
		NSDictionary *changeset_deleted = changeset[kChangeset_deleted];
		if (changeset_deleted)
		{
			if (![changeset_deleted isKindOfClass:[NSDictionary class]]) {
				return YES;
			}
			
			// All values must be numbers.
			
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
	// - Changed items
	//
	//     For each item that was changed (within the changeset period),
	//     we have the 'key', an 'oldValue', and a 'newValue'.
	//
	//     If an item was added, then the 'oldValue' will be ZDCNull.
	//     If an item was deleted, the new 'newValue' will be ZDCNull.
	//
	// - Moved items
	//
	//     For each item that was moved (within the change-period),
	//     we have the 'key' and 'oldIndex'.
	//
	// - Deleted items
	//
	//     For each item that was deleted (within the change period),
	//     we have the 'key' and 'oldIndex'.
	//
	//     Recall that the 'oldValue' can be found within the 'Changed items' section.
	//
	//
	// In order for the algorithm to work, the 3 sources of information MUST be
	// applied 1-at-a-time, and in a specific order. Moving backwards,
	// from [current state] to [previous state] the order is:
	//
	//                       direction    <=       this      <=     in      <=      read
	// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
	
	// Step 1 of 4:
	//
	// Undo changes to objects that conform to ZDCSyncable protocol
	
	NSDictionary *changeset_refs = changeset[kChangeset_refs];
	if (changeset_refs.count > 0)
	{
		for (id key in changeset_refs)
		{
			NSDictionary *obj_changeset = changeset_refs[key];
			
			id obj = dict[key];
			
			if ([obj conformsToProtocol:@protocol(ZDCSyncable)])
			{
				NSError *error = [obj performUndo:obj_changeset];
				if (error)
				{
					return error;
				}
			}
			else
			{
				return [self mismatchedChangeset];
			}
		}
	}
	
	// Step 2 of 4:
	//
	// Undo added objects & restore previous values.
	
	NSDictionary *changeset_values = changeset[kChangeset_values];
	if (changeset_values.count > 0)
	{
		for (id key in changeset_values)
		{
			if ([self containsKey:key])
			{
				id oldValue = changeset_values[key];
				if (oldValue == [ZDCNull null]) {
					[self removeObjectForKey:key];
				}
				else {
					[self setObject:oldValue forKey:key];
				}
			}
		}
	}
	
	// Step 3 of 4:
	//
	// Undo move operations
	
	NSDictionary *changeset_moves = changeset[kChangeset_indexes];
	if (changeset_moves.count > 0)
	{
		// We have a list of keys, and their originalIndexes.
		// So for each key, we need to:
		// - remove it from it's currentIndex
		// - add it back in it's originalIndex
		//
		// And we need to keep track of the changeset (originalIndexes) as we're doing this.
		
		if (originalIndexes == nil) {
			originalIndexes = [[NSMutableDictionary alloc] init];
		}
		
		NSMutableArray<id> *keys = [NSMutableArray arrayWithCapacity:changeset_moves.count];
		NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
		
		for (id key in changeset_moves)
		{
			NSUInteger idx = [self indexForKey:key];
			if (idx != NSNotFound) // shouldn't happen; sanity check
			{
				if (isSimpleUndo)
				{
				#ifndef NS_BLOCK_ASSERTIONS
					[self checkOriginalIndexes:idx];
				#endif
					
					originalIndexes[key] = @(idx);
				}
				
				[keys addObject:key];
				[indexes addIndex:idx];
			}
		}
		
		if (!isSimpleUndo)
		{
			NSMutableArray<id> *originalOrder = [NSMutableArray arrayWithCapacity:order.count];
			
			for (id key in order)
			{
				if ((originalIndexes[key] == nil) && (originalValues[key] != [ZDCNull null]))
				{
					[originalOrder addObject:key];
				}
			}
			
			NSArray<id> *sortedKeys = [originalIndexes keysSortedByValueUsingComparator:
				^NSComparisonResult(NSNumber *num1, NSNumber *num2)
			{
				return [num1 compare:num2];
			}];
			
			for (id key in sortedKeys)
			{
				NSUInteger prvIdx = [originalIndexes[key] unsignedIntegerValue];
				[originalOrder insertObject:key atIndex:prvIdx];
			}
			
			for (id key in keys)
			{
				if (originalIndexes[key] == nil)
				{
					NSUInteger originalIdx = [originalOrder indexOfObject:key];
					if (originalIdx != NSNotFound)
					{
					#ifndef NS_BLOCK_ASSERTIONS
						[self checkOriginalIndexes:originalIdx];
					#endif
						originalIndexes[key] = @(originalIdx);
					}
					else
					{
						// Might be the case during an `importChanges::` operation,
						// where an item was added in changeset_A, and moved in changeset_B.
					}
				}
			}
		}
		
		[order removeObjectsAtIndexes:indexes];
	
		// Sort keys by targetIdx (originalIdx).
		// We want to add them from lowest idx to highest idx.
		[keys sortUsingComparator:^NSComparisonResult(id key1, id key2) {
			
			NSNumber *idx1 = changeset_moves[key1];
			NSNumber *idx2 = changeset_moves[key2];
			
			return [idx1 compare:idx2];
		}];
		
		for (id key in keys)
		{
			NSUInteger idx = [changeset_moves[key] unsignedIntegerValue];
			if (idx > order.count) {
				return [self mismatchedChangeset];
			}
			[order insertObject:key atIndex:idx];
		}
	}
	
	// Step 4 of 4:
	//
	// Undo deleted objects.
	
	NSDictionary *changeset_deleted = changeset[kChangeset_deleted];
	if (changeset_deleted.count > 0)
	{
		NSMutableArray<id> *sortedKeys = [[changeset_deleted allKeys] mutableCopy];
		
		[sortedKeys sortUsingComparator:^NSComparisonResult(id key1, id key2) {
			
			NSNumber *idx1 = changeset_deleted[key1];
			NSNumber *idx2 = changeset_deleted[key2];
			
			return [idx1 compare:idx2];
		}];
		
		for (id key in sortedKeys)
		{
			NSUInteger index = [(NSNumber *)changeset_deleted[key] unsignedIntegerValue];
			
			id oldValue = changeset_values[key];
			if (oldValue && oldValue != [ZDCNull null]) {
				[self insertObject:oldValue forKey:key atIndex:index];
			}
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
		// All of this code comes from the `_undo:` method.
		// But it's been changed to include only stuff that affects the order.
		
		// Step 1 of 3:
		//
		// Undo added keys
		
		NSDictionary *changeset_values = changeset[kChangeset_values];
		if (changeset_values.count > 0)
		{
			for (id key in changeset_values)
			{
				id oldValue = changeset_values[key];
				if (oldValue == [ZDCNull null])
				{
					NSUInteger idx = [order indexOfObject:key];
					if (idx != NSNotFound)
					{
						[order removeObjectAtIndex:idx];
					}
				}
			}
		}
		
		// Step 2 of 3:
		//
		// Undo moved keys
		
		NSDictionary *changeset_moves = changeset[kChangeset_indexes];
		if (changeset_moves.count > 0)
		{
			// We have a list of keys, and their originalIndexes.
			// So for each key, we need to:
			// - remove it from it's currentIndex
			// - add it back in it's originalIndex
	
			NSMutableArray<id> *keys = [NSMutableArray arrayWithCapacity:changeset_moves.count];
			NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
	
			for (id key in changeset_moves)
			{
				NSUInteger idx = [order indexOfObject:key];
				if (idx != NSNotFound) // shouldn't happen; sanity check
				{
					[keys addObject:key];
					[indexes addIndex:idx];
				}
			}
			
			[order removeObjectsAtIndexes:indexes];
	
			// Sort keys by targetIdx (originalIdx).
			// We want to add them from lowest idx to highest idx.
			[keys sortUsingComparator:^NSComparisonResult(id key1, id key2) {
			
				NSNumber *idx1 = changeset_moves[key1];
				NSNumber *idx2 = changeset_moves[key2];
			
				return [idx1 compare:idx2];
			}];
	
			for (id key in keys)
			{
				NSUInteger idx = [changeset_moves[key] unsignedIntegerValue];
				if (idx > order.count)
				{
					return nil;
				}
				[order insertObject:key atIndex:idx];
			}
		}
		
		// Step 3 of 3:
		//
		// Undo deleted objects
		
		NSDictionary *changeset_deleted = changeset[kChangeset_deleted];
		if (changeset_deleted.count > 0)
		{
			NSMutableArray<id> *sortedKeys = [[changeset_deleted allKeys] mutableCopy];
			
			[sortedKeys sortUsingComparator:^NSComparisonResult(id key1, id key2) {
				
				NSNumber *idx1 = changeset_deleted[key1];
				NSNumber *idx2 = changeset_deleted[key2];
				
				return [idx1 compare:idx2];
			}];
			
			for (id key in sortedKeys)
			{
				id oldValue = changeset_values[key];
				if (oldValue && oldValue != [ZDCNull null])
				{
					NSUInteger idx = [(NSNumber *)changeset_deleted[key] unsignedIntegerValue];
					if (idx > order.count)
					{
						return nil;
					}
					[order insertObject:key atIndex:idx];
				}
			}
		}
	}
	
	return order;
}

/**
 * See ZDCSyncable.h for method description.
 */
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
	ZDCOrderedDictionary *cloudVersion = (ZDCOrderedDictionary *)inCloudVersion;
	
	// Step 1 of 8:
	//
	// If there are pending changes, calculate the original order.
	// This will be used later on during the merge process.
	//
	// Note:
	//   We don't care about the original values here.
	//   Just the original order.
	//
	// Important:
	//   We need to do this in the beginning, because we need an unmodified `order`.
	
	NSArray<id> *originalOrder = nil;
	if (pendingChangesets.count > 0)
	{
		originalOrder = [[self class] _originalOrderFrom:order pendingChangesets:pendingChangesets];
		if (originalOrder == nil)
		{
			if (errPtr) *errPtr = [self mismatchedChangeset];
			return nil;
		}
	}
	
	// Step 2 of 8:
	//
	// We need to determine which keys have been changed locally, and what the original versions were.
	// We'll need this information when comparing to the cloudVersion.
	
	NSMutableDictionary<NSString*, id> *merged_originalValues = [NSMutableDictionary dictionary];
	
	for (NSDictionary *changeset in pendingChangesets)
	{
		NSDictionary<id, id> *changeset_originalValues = changeset[kChangeset_values];
		
		[changeset_originalValues enumerateKeysAndObjectsUsingBlock:
			^(id key, id oldValue, BOOL *stop)
		{
			if (merged_originalValues[key] == nil)
			{
				merged_originalValues[key] = oldValue;
			}
		}];
	}
	
	// Step 3 of 8:
	//
	// Next, we're going to enumerate what values are in the cloud.
	// This will tell us what was added & modified by remote devices.
	
	NSMutableSet<NSString*> *movedKeys_remote = [NSMutableSet set];
	
	[cloudVersion enumerateKeysAndObjectsUsingBlock:
		^(id key, id cloudValue, NSUInteger idx, BOOL *stop)
	{
		id currentLocalValue = self->dict[key];
		id originalLocalValue = merged_originalValues[key];
		
		BOOL modifiedValueLocally = (originalLocalValue != nil);
		if (originalLocalValue == [ZDCNull null]) {
			originalLocalValue = nil;
		}
		
		if (!modifiedValueLocally &&
		    [currentLocalValue conformsToProtocol:@protocol(ZDCSyncable)] &&
		    [cloudValue conformsToProtocol:@protocol(ZDCSyncable)])
		{
			// continue - handled by refs
			return; // from block
		}
		
		BOOL mergeRemoteValue = NO;
		
		if (![cloudValue isEqual:currentLocalValue]) // remote & (current) local values differ
		{
			if (modifiedValueLocally)
			{
				if ([cloudValue isEqual:originalLocalValue]) {
					// modified by local only
				}
				else {
					mergeRemoteValue = YES; // added/modified by local & remote - remote wins
				}
			}
			else // we have not modified the value locally
			{
				mergeRemoteValue = YES; // added/modified by remote
			}
		}
		else // remote & local values match
		{
			if (modifiedValueLocally)
			{
				// Possible future optimization.
				// There's no need to push this particular change since cloud already has it.
			}
		}
		
		if (mergeRemoteValue)
		{
			self[key] = cloudValue;
			[movedKeys_remote addObject:key];
		}
	}];
	
	// Step 4 of 8:
	//
	// Next we need to determine if any values were deleted by remote devices.
	{
		NSMutableSet *baseKeys = [NSMutableSet setWithArray:[self allKeys]];
	
		[merged_originalValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
	
			if (obj == [ZDCNull null])       // Null => we added this tuple.
				[baseKeys removeObject:key]; // So it's not part of the set the cloud is expected to have.
			else
				[baseKeys addObject:key];    // For items that we may have deleted (no longer in [self allKeys])
		}];
	
		for (id key in baseKeys)
		{
			id remoteValue = cloudVersion[key];
			if (remoteValue == nil)
			{
				// The remote key/value pair was deleted
	
				[self removeObjectForKey:key];
			}
		}
	}
	
	// Step 5 of 8:
	//
	// Merge the ZDCSyncable properties
	
	NSMutableSet<id> *refs = [NSMutableSet set];
	
	for (NSDictionary *changeset in pendingChangesets)
	{
		NSDictionary<id, NSDictionary*> *changeset_refs = changeset[kChangeset_refs];
		
		for (id key in changeset_refs)
		{
			if (merged_originalValues[key] == nil)
			{
				[refs addObject:key];
			}
		}
	}
	
	NSError *err = nil;
	
	for (id key in refs)
	{
		id<ZDCSyncable> localRef = self->dict[key];
		id<ZDCSyncable> cloudRef = cloudVersion->dict[key];
		
		if ([localRef conformsToProtocol:@protocol(ZDCSyncable)] &&
		    [cloudRef conformsToProtocol:@protocol(ZDCSyncable)])
		{
			NSMutableArray *pendingChangesets_ref = [NSMutableArray arrayWithCapacity:pendingChangesets.count];
			
			for (NSDictionary *changeset in pendingChangesets)
			{
				NSDictionary<id, NSDictionary*> *changeset_refs = changeset[kChangeset_refs];
				NSDictionary *changeset_ref = changeset_refs[key];
				
				if (changeset_ref)
				{
					[pendingChangesets_ref addObject:changeset_ref];
				}
			}
			
			NSError *subMergeErr = nil;
			[localRef mergeCloudVersion: cloudRef
			      withPendingChangesets: pendingChangesets_ref
			                      error: &subMergeErr];
			
			if (subMergeErr && !err) {
				err = subMergeErr;
			}
		}
	}
	
	// Step 6 of 8:
	//
	// Prepare to merge the order.
	//
	// At this point, we've added every key/value pair that was in the cloudVersion, but not in our localVersion.
	// And we've deleted key/value pairs that have been deleted from the cloudVersion.
	//
	// Another change we need to take into consideration are key/value pairs we've deleted locally.
	//
	// Our aim here is to derive 2 arrays, one from cloudVersion->order, and another from self->order.
	// Both of these arrays will have the same count, and contain the same keys, but possibly in a different order.
	
	NSMutableArray *order_localVersion = [self->order mutableCopy];
	NSMutableArray *order_cloudVersion = [cloudVersion->order mutableCopy];
	
	{
		NSMutableSet *merged_keys = [NSMutableSet setWithArray:self->order];
		[merged_keys intersectSet:[NSSet setWithArray:cloudVersion->order]];
		
		NSUInteger i = 0;
		while (i < order_localVersion.count)
		{
			id key = order_localVersion[i];
			if ([merged_keys containsObject:key]) {
				i++;
			}
			else {
				[order_localVersion removeObjectAtIndex:i];
			}
		}
		
		i = 0;
		while (i < order_cloudVersion.count)
		{
			id key = order_cloudVersion[i];
			if ([merged_keys containsObject:key]) {
				i++;
			}
			else {
				[order_cloudVersion removeObjectAtIndex:i];
			}
		}
	}
	
	// Step 7 of 8:
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
		
	if (pendingChangesets.count == 0)
	{
		[movedKeys_remote addObjectsFromArray:cloudVersion->order];
	}
	else // if (pendingChangesets.count > 0)
	{
		NSMutableSet *merged_keys = [NSMutableSet setWithArray:originalOrder];
		[merged_keys intersectSet:[NSSet setWithArray:cloudVersion->order]];
		
		NSMutableArray *order_originalVersion = [originalOrder mutableCopy];
		NSMutableArray *order_cloudVersion = [cloudVersion->order mutableCopy];
		
		NSUInteger i = 0;
		while (i < order_originalVersion.count)
		{
			id key = order_originalVersion[i];
			if ([merged_keys containsObject:key]) {
				i++;
			}
			else {
				[order_originalVersion removeObjectAtIndex:i];
			}
		}
		
		i = 0;
		while (i < order_cloudVersion.count)
		{
			id key = order_cloudVersion[i];
			if ([merged_keys containsObject:key]) {
				i++;
			}
			else {
				[order_cloudVersion removeObjectAtIndex:i];
			}
		}
		
		NSArray *estimate =
			[ZDCOrder estimateChangesetFrom: order_originalVersion
			                            to: order_cloudVersion
			                         hints: movedKeys_remote];
		
		[movedKeys_remote addObjectsFromArray:estimate];
	}
	
	// Step 8 of 8:
	//
	// We have all the information we need to merge the order now.
	
	for (NSUInteger i = 0; i < order_cloudVersion.count; i++)
	{
		id key_remote = order_cloudVersion[i];
		id key_local = order_localVersion[i];
		
		if (![key_remote isEqual:key_local])
		{
			BOOL changed_remote = [movedKeys_remote containsObject:key_remote];
			
			if (changed_remote)
			{
				// Remote wins.
				
				id key = key_remote;
				
				// Move key into proper position (with changed_local)
				
				NSRange searchRange = NSMakeRange(i+1, order_localVersion.count-i-1);
				NSUInteger idx = [order_localVersion indexOfObject:key inRange:searchRange];
				
				[order_localVersion removeObjectAtIndex:idx];
				[order_localVersion insertObject:key atIndex:i];
				
				// Move key into proper position (within order)
				//
				// Note:
				//   We already added all the keys that were added by remote devices.
				//   And we already deleted all the key that were deleted by remote devices.
				
				NSUInteger oldIdx = [self indexForKey:key];
				NSUInteger newIdx = 0;
				if (i > 0)
				{
					NSString *prvKey_local = order_localVersion[i-1];
					newIdx = [self indexForKey:prvKey_local] + 1;
				}
				
				[self moveObjectAtIndex:oldIdx toIndex:newIdx];
			}
			else
			{
				// Local wins.
				
				id key = key_local;
				
				// Move remote into proper position (with changed_remote)
				
				NSRange searchRange = NSMakeRange(i+1, order_cloudVersion.count-i-1);
				NSUInteger idx = [order_cloudVersion indexOfObject:key inRange:searchRange];
				
				[order_cloudVersion removeObjectAtIndex:idx];
				[order_cloudVersion insertObject:key atIndex:i];
			}
		}
	}
	
	if (errPtr) *errPtr = nil;
	return ([self changeset] ?: @{});
}

@end

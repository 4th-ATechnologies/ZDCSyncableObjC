/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCSet.h"

#import "ZDCObjectSubclass.h"

// Encoding/Decoding Keys
//
static int const kCurrentVersion = 0;
#pragma unused(kCurrentVersion)

static NSString *const kCoding_version = @"version";
static NSString *const kCoding_set     = @"set";

// Changeset Keys
//
static NSString *const kChangeset_added   = @"added";
static NSString *const kChangeset_deleted = @"deleted";


@implementation ZDCSet {
@private

	NSMutableSet<id> *set;

	NSMutableSet<id> *added;
	NSMutableSet<id> *deleted;
}

@dynamic rawSet;

- (instancetype)init
{
	if ((self = [super init]))
	{
		set = [[NSMutableSet alloc] init];
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
		NSUInteger capacity = inArray ? inArray.count : 8;
		set = [[NSMutableSet alloc] initWithCapacity:capacity];
		
		for (id obj in inArray)
		{
			[set addObject:(flag ? [obj copy] : obj)];
		}
		
		added = [set mutableCopy];
	}
	return self;
}

- (instancetype)initWithSet:(NSSet<id> *)inSet
{
	return [self initWithSet:inSet copyItems:NO];
}

- (instancetype)initWithSet:(NSSet<id> *)inSet copyItems:(BOOL)flag
{
	if ((self = [super init]))
	{
		set = inSet ?
		  [[NSMutableSet alloc] initWithSet:inSet copyItems:flag] :
		  [[NSMutableSet alloc] init];
		
		added = [set mutableCopy];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCoding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		set = [decoder decodeObjectForKey:kCoding_set];
		
		if (set == nil) {
			set = [[NSMutableSet alloc] init];
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
	
	[coder encodeObject:set forKey:kCoding_set];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)copyWithZone:(NSZone *)zone
{
	ZDCSet *copy = [super copyWithZone:zone]; // [ZDCObject copyWithZone:]
	
	copy->set = [self->set mutableCopy];
	
	copy->added = [self->added mutableCopy];
	copy->deleted = [self->deleted mutableCopy];
	
	return copy;
}

/**
 * For complicated copying scenarios, such as nested deep copies.
 * This method is declared in: ZDCObjectSubclass.h
 */
- (void)copyChangeTrackingTo:(id)another
{
	if ([another isKindOfClass:[ZDCSet class]])
	{
		__unsafe_unretained ZDCSet *copy = (ZDCSet *)another;
		if (!copy.isImmutable)
		{
			copy->added = [self->added mutableCopy];
			copy->deleted = [self->deleted mutableCopy];
			
			[super copyChangeTrackingTo:another];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSSet<id> *)rawSet
{
	return [set copy];
}

- (NSUInteger)count
{
	return set.count;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)containsObject:(id)obj
{
	return [set containsObject:obj];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Writing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addObject:(id)object
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (object == nil) return;
	
	if (![self containsObject:object])
	{
		[self _willAddObject:object];
		[set addObject:object];
	}
}

- (void)removeObject:(id)object
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	if (object == nil) return;
	
	if ([self containsObject:object])
	{
		[self _willRemoveObject:object];
		[set removeObject:object];
	}
}
- (void)removeAllObjects
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	for (id object in set)
	{
		[self _willRemoveObject:object];
	}
	
	[set removeAllObjects];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Change Tracking Internals
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)_willAddObject:(id)obj
{
	NSParameterAssert(obj != nil);
	
	if (added == nil) {
		added = [[NSMutableSet alloc] init];
	}
	
	if ([deleted containsObject:obj])
	{
		// Deleted & then later re-added within same changeset.
		// The two actions cancel each other out.
		
		[deleted removeObject:obj];
	}
	else
	{
		[added addObject:obj];
	}
}

- (void)_willRemoveObject:(id)obj
{
	NSParameterAssert(obj != nil);
	
	if (deleted == nil) {
		deleted = [[NSMutableSet alloc] init];
	}
	
	if ([added containsObject:obj])
	{
		// Added & then later removed within same changeset.
		// The two actions cancel each other out.
		
		[added removeObject:obj];
	}
	else
	{
		[deleted addObject:obj];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Enumeration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, BOOL *stop))block
{
	[set enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
		block(obj, stop);
	}];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len
{
	return [set countByEnumeratingWithState:state objects:buffer count:len];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Equality
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isEqual:(nullable id)another
{
	if ([another isKindOfClass:[ZDCSet class]]) {
		return [self isEqualToSet:(ZDCSet *)another];
	}
	else {
		return NO;
	}
}

- (BOOL)isEqualToSet:(nullable ZDCSet *)another
{
	if (another == nil) return NO; // null dereference crash ahead
	
	return [set isEqualToSet:another->set];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark ZDCObject Overrides
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)makeImmutable
{
	[super makeImmutable];
	
	for (id obj in set)
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
	    deleted.count > 0  ) return YES;
	
	for (id obj in set)
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
	[deleted removeAllObjects];
	
	for (id obj in set)
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
	
	NSMutableDictionary<NSString*, id> *changeset = [NSMutableDictionary dictionaryWithCapacity:2];
	
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
	
	if (deleted.count > 0)
	{
		// changeset: {
		//   deleted: [{
		//     obj, ...
		//   }],
		//   ...
		// }
		
		NSMutableSet *changeset_deleted = [NSMutableSet setWithCapacity:deleted.count];
		
		for (id obj in deleted)
		{
			if ([obj conformsToProtocol:@protocol(NSCopying)]) {
				[changeset_deleted addObject:[obj copy]];
			}
			else {
				[changeset_deleted addObject:obj];
			}
		}
		
		changeset[kChangeset_deleted] = [changeset_deleted copy];
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
	//   added: [{
	//     <obj: Any>, ...
	//   }],
	//   deleted: [{
	//     <obj: Any>, ...
	//   }]
	// }
	
	// added
		
	NSSet *changeset_added = changeset[kChangeset_added];
	if (changeset_added)
	{
		if (![changeset_added isKindOfClass:[NSSet class]]) {
			return YES;
		}
	}
	
	// deleted
	
	NSSet *changeset_deleted = changeset[kChangeset_deleted];
	if (changeset_deleted)
	{
		if (![changeset_deleted isKindOfClass:[NSSet class]]) {
			return YES;
		}
	}
	
	// Make sure there's no overlap between added & removed.
	// That is, items in changeset_added cannot also be in changeset_removed.
	
	if (changeset_added && changeset_deleted)
	{
		if ([changeset_added intersectsSet:changeset_deleted]) {
			return YES;
		}
	}
	
	// Looks good (not malformed)
	return NO;
}

- (NSError *)_undo:(NSDictionary *)changeset
{
	// Important: `isMalformedChangeset:` must be called before invoking this method.
	
	// Step 1 of 2:
	//
	// Undo added objects.
	
	NSSet<id> *changeset_added = changeset[kChangeset_added];
	if (changeset_added.count > 0)
	{
		for (id obj in changeset_added)
		{
			[self removeObject:obj];
		}
	}
	
	// Step 2 of 2:
	//
	// Undo removed operations
	
	NSSet<id> *changeset_deleted = changeset[kChangeset_deleted];
	if (changeset_deleted.count > 0)
	{
		for (id obj in changeset_deleted)
		{
			[self addObject:obj];
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
 * See ZDCSyncable.h for method description.
 */
- (nullable NSDictionary *)mergeCloudVersion:(nonnull id)inCloudVersion
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
	ZDCSet *cloudVersion = (ZDCSet *)inCloudVersion;
	
	// Step 1 of 3:
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
	
	// Step 2 of 3:
	//
	// Add objects that were added by remote devices.
	
	for (id obj in cloudVersion->set)
	{
		if (![self->set containsObject:obj])
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
	
	// Step 3 of 3:
	//
	// Delete objects that were deleted by remote devices.
	
	NSMutableArray *deleteMe = nil;
	
	for (id obj in self->set) // enumerating self->set => cannot be modified during enumeration
	{
		if (![cloudVersion->set containsObject:obj])
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
	
	if (errPtr) *errPtr = nil;
	return ([self changeset] ?: @{});
}

@end

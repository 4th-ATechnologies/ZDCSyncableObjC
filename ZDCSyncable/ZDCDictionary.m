/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCDictionary.h"

#import "ZDCObjectSubclass.h"
#import "ZDCNull.h"
#import "ZDCRef.h"

// Encoding/Decoding Keys
//
static int const kCurrentVersion = 0;
#pragma unused(kCurrentVersion)

static NSString *const kCoding_version = @"version";
static NSString *const kCoding_dict    = @"dict";

// Changeset Keys
//
static NSString *const kChangeset_refs   = @"refs";
static NSString *const kChangeset_values = @"values";


@implementation ZDCDictionary {
@private
	
	NSMutableDictionary *dict;
	
	NSMutableDictionary<id, id> *originalValues;
}

@dynamic rawDictionary;
@dynamic count;

- (instancetype)init
{
	return [self initWithDictionary:nil copyItems:NO];
}

- (instancetype)initWithDictionary:(nullable NSDictionary *)inRaw
{
	return [self initWithDictionary:inRaw copyItems:NO];
}

- (instancetype)initWithDictionary:(nullable NSDictionary *)inRaw copyItems:(BOOL)flag
{
	if ((self = [super init]))
	{
		dict = inRaw ?
		  [[NSMutableDictionary alloc] initWithDictionary:inRaw copyItems:flag] :
		  [[NSMutableDictionary alloc] init];
		
		if (dict.count > 0)
		{
			originalValues = [[NSMutableDictionary alloc] init];
			
			for (id key in dict)
			{
				originalValues[key] = [ZDCNull null];
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
		dict = [decoder decodeObjectForKey:kCoding_dict];
		
		if (dict == nil) {
			dict = [[NSMutableDictionary alloc] init];
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
	
	// Note: ephemeral properties (i.e. for change tracking) are not serialized
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)copyWithZone:(NSZone *)zone
{
	ZDCDictionary *copy = [super copyWithZone:zone]; // [ZDCObject copyWithZone:]
	
	copy->dict = [self->dict mutableCopy];
	copy->originalValues = [self->originalValues mutableCopy];
	
	return copy;
}

/**
 * For complicated copying scenarios, such as nested deep copies.
 * This method is declared in: ZDCObjectSubclass.h
 */
- (void)copyChangeTrackingTo:(id)another
{
	if ([another isKindOfClass:[ZDCDictionary class]])
	{
		__unsafe_unretained ZDCDictionary *copy = (ZDCDictionary *)another;
		if (!copy.isImmutable)
		{
			copy->originalValues = [self->originalValues mutableCopy];
			
			[super copyChangeTrackingTo:another];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Raw
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSDictionary *)rawDictionary
{
	return [dict copy];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)count
{
	return dict.count;
}

- (NSArray *)allKeys
{
	return [dict allKeys];
}

- (BOOL)containsKey:(id)key
{
	if (key)
		return CFDictionaryContainsKey((CFDictionaryRef)dict, (const void *)key);
	else
		return NO;
}

- (id)objectForKey:(id)key
{
	return [dict objectForKey:key];
}

- (id)objectForKeyedSubscript:(id)key
{
	return [self objectForKey:key];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Writing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
		[self _willUpdateObjectForKey:key];
		dict[key] = object;
	}
	else
	{
		[self _willInsertObjectForKey:key];
		dict[key] = object;
	}
}

- (void)setObject:(nullable id)object forKeyedSubscript:(id)key
{
	[self setObject:object forKey:key];
}

- (void)removeObjectForKey:(id)key
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if ([self containsKey:key])
	{
		[self _willRemoveObjectForKey:key];
		dict[key] = nil;
	}
}

- (void)removeObjectsForKeys:(NSArray<id> *)keys
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	if (keys.count == 0) return;
	
	for (id key in keys)
	{
		if ([self containsKey:key])
		{
			[self _willRemoveObjectForKey:key];
			dict[key] = nil;
		}
	}
}

- (void)removeAllObjects
{
	if (self.isImmutable) {
		@throw [self immutableException];
	}
	
	for (id key in [dict allKeys])
	{
		[self _willRemoveObjectForKey:key];
		dict[key] = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Change Tracking Internals
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)_willUpdateObjectForKey:(NSString *const)key
{
	NSParameterAssert(key != nil);
	
	if (originalValues == nil) {
		originalValues = [[NSMutableDictionary alloc] init];
	}
	
	if (originalValues[key] == nil) {
		originalValues[key] = dict[key];
	}
}

- (void)_willInsertObjectForKey:(NSString *const)key
{
	NSParameterAssert(key != nil);
	
	if (originalValues == nil) {
		originalValues = [[NSMutableDictionary alloc] init];
	}
	
	if (originalValues[key] == nil) {
		originalValues[key] = [ZDCNull null];
	}
}

- (void)_willRemoveObjectForKey:(NSString *const)key
{
	NSParameterAssert(key != nil);
	
	if (originalValues == nil) {
		originalValues = [[NSMutableDictionary alloc] init];
	}
	
	id originalValue = originalValues[key];
	if (originalValue == nil)
	{
		originalValues[key] = dict[key];
	}
	else if (originalValue == [ZDCNull null])
	{
		// Value was added within snapshot, and is now being removed
		originalValues[key] = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Enumeration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)enumerateKeysUsingBlock:(void (^)(id key, BOOL *stop))block
{
	BOOL stop = NO;
	
	for (NSString *key in dict)
	{
		block(key, &stop);
		
		if (stop) {
			break;
		}
	}
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block
{
	[dict enumerateKeysAndObjectsUsingBlock:block];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len
{
	return [dict countByEnumeratingWithState:state objects:buffer count:len];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Equality
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isEqual:(nullable id)another
{
	if ([another isKindOfClass:[ZDCDictionary class]]) {
		return [self isEqualToDictionary:(ZDCDictionary *)another];
	} else {
		return NO;
	}
}

- (BOOL)isEqualToDictionary:(nullable ZDCDictionary *)another
{
	if (another == nil) return NO; // null dereference crash ahead
	
	return [dict isEqualToDictionary:another->dict];
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
	
	if (originalValues.count  > 0) return YES;
	
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
	
	NSMutableDictionary *changeset = [NSMutableDictionary dictionaryWithCapacity:2];
	
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
	
	// Looks good (not malformed)
	return NO;
}

- (NSError *)_undo:(NSDictionary *)changeset
{
	// Important: `isMalformedChangeset:` must be called before invoking this method.
	
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
	
	NSDictionary *changeset_values = changeset[kChangeset_values];
	if (changeset_values.count > 0)
	{
		for (id key in changeset_values)
		{
			id oldValue = changeset_values[key];
			
			if (oldValue == [ZDCNull null]) {
				[self removeObjectForKey:key];
			}
			else if (oldValue != [ZDCRef ref]) {
				[self setObject:oldValue forKey:key];
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
	ZDCDictionary *cloudVersion = (ZDCDictionary *)inCloudVersion;
	
	// Step 1 of 4:
	//
	// We need to determine which keys have been changed locally, and what the original versions were.
	// We'll need this information when comparing to the cloudVersion.
	
	NSMutableDictionary<NSString*, id> *merged_originalValues = [NSMutableDictionary dictionary];
	
	for (NSDictionary *changeset in pendingChangesets)
	{
		NSDictionary<NSString*, NSArray*> *changeset_originalValues = changeset[kChangeset_values];
		
		[changeset_originalValues enumerateKeysAndObjectsUsingBlock:
			^(NSString *key, id oldValue, BOOL *stop)
		{
			if (merged_originalValues[key] == nil)
			{
				merged_originalValues[key] = oldValue;
			}
		}];
	}
	
	// Step 2 of 4:
	//
	// Next, we're going to enumerate what values are in the cloud.
	// This will tell us what was added & modified by remote devices.
	
	[cloudVersion enumerateKeysAndObjectsUsingBlock:^(id key, id cloudValue, BOOL *stop){
		
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
		}
	}];
	
	// Step 3 of 4:
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
	
		for (NSString *key in baseKeys)
		{
			id remoteValue = cloudVersion[key];
			if (remoteValue == nil)
			{
				// The remote key/value pair was deleted
	
				[self removeObjectForKey:key];
			}
		}
	}
	
	// Step 4 of 4:
	//
	// Merge the ZDCSyncable properties
	
	NSMutableSet<id> *refs = [NSMutableSet set];
	
	for (NSDictionary *changeset in pendingChangesets)
	{
		NSDictionary<id, NSDictionary*> *changeset_refs = changeset[kChangeset_refs];
		
		for (id key in changeset_refs)
		{
			id originalValue = merged_originalValues[key];
			if ((originalValue == nil) || (originalValue == [ZDCRef ref]))
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
	
	if (errPtr) *errPtr = nil;
	return ([self changeset] ?: @{});
}

@end

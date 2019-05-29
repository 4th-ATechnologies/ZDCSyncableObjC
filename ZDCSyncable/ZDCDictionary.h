/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCObject.h"
#import "ZDCSyncable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * ZDCDictionary tracks changes to a dictionary.
 *
 * It's designed to act like a drop-in replacement for a mutable dictionary.
 *
 * In addition to its core functionality, it also provides the following set of features:
 * - it can be made immutable (via `-[ZDCObject makeImmutable]` method)
 * - it implements the ZDCSyncable protocol and thus:
 * - it tracks all changes to the dictionary, and can provide a changeset (which encodes the changes info)
 * - it supports undo & redo
 * - it supports merge operations
 */
NS_SWIFT_NAME(ZDCDictionary_ObjC)
@interface ZDCDictionary<KeyType, ObjectType> : ZDCObject <NSCoding, NSCopying, NSFastEnumeration, ZDCSyncable>

/**
 * Creates an empty dictionary.
 */
- (instancetype)init;

/**
 * Creates a dictionary that contains the {key, value} tuples from the given input.
 *
 * @note To initialize from another ZDCDictionary, you can either copy the original,
 *       or use this method combined with `-[ZDCDictionary rawSet]` to provide the parameter.
 *
 * @param raw
 *   The {key,value} tuples will be stored in the created ZDCDictionary.
 */
- (instancetype)initWithDictionary:(nullable NSDictionary<KeyType, ObjectType> *)raw;

/**
 * Creates a dictionary that continas the {key, value} tuples from the given input.
 *
 * @note To initialize from another ZDCDictionary, you can either copy the original,
 *       or use this method combined with `-[ZDCDictionary rawSet]` to provide the parameter.
 *
 * @param raw
 *   The {key,value} tuples will be stored in the created ZDCDictionary.
 *
 * @param copyItems
 *   If set to YES, the values will be copied when storing in the ZDCDictionary.
 *   This means the values will need to support the NSCopying protocol.
 */
- (instancetype)initWithDictionary:(nullable NSDictionary<KeyType, ObjectType> *)raw copyItems:(BOOL)copyItems;

#pragma mark Raw

/**
 * Returns a reference to the underlying NSDictionary that the ZDCDictionary instance is wrapping.
 *
 * @note The returned value is a copy of the underlying NSMutableDictionary.
 *       Thus changes to the ZDCDictionary will not be reflected in the returned value.
 */
@property (nonatomic, copy, readonly) NSDictionary *rawDictionary;

#pragma mark Reading

/**
 * The number of items stored in the dictionary.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 * Returns the array of keys stored in the dictionary.
 */
- (NSArray<KeyType> *)allKeys;

/**
 * Returns YES if there's a value stored in the dictionary for the given key.
 * This method is faster than calling `objectForKey:`, and then checking to see if the returned object is non-nil.
 */
- (BOOL)containsKey:(KeyType)key;

/**
 * Returns the stored object for the given key.
 */
- (nullable ObjectType)objectForKey:(KeyType)key;

/**
 * Returns the stored object for the given key.
 *
 * Allows you to use syntax:
 * ```
 * value = zdcDict[key]
 * ```
 */
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;

#pragma mark Writing

/**
 * Stores the {key, value} tuple in the dictionary.
 * If there's already a value stored for the given key, the old value is replaced with the new value.
 */
- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key;

/**
 * Stores the {key, value} tuple in the dictionary.
 * If there's already a value stored for the given key, the old value is replaced with the new value.
 *
 * Allows you to use syntax:
 * ```
 * zdcDict[key] = value
 * ```
 */
- (void)setObject:(nullable ObjectType)object forKeyedSubscript:(KeyType)key;

/**
 * Removes the {key, value} tuple from the dictionary if the key exists.
 * If the key doesn't exist, no changes are made.
 */
- (void)removeObjectForKey:(KeyType)key;

/**
 * Removes all items from the dictionary matching the given list of keys.
 */
- (void)removeObjectsForKeys:(NSArray<KeyType> *)keys;

/**
 * Removes all {key, value} tuples from the dictionary.
 */
- (void)removeAllObjects;

#pragma mark Enumeration

/**
 * Enumerates all keys in the dictionary with the given block.
 */
- (void)enumerateKeysUsingBlock:(void (^)(KeyType key, BOOL *stop))block;

/**
 * Enumerates all {key, value} tuples in the dictionary with the given block.
 */
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(KeyType key, ObjectType obj, BOOL *stop))block;

#pragma mark Equality

/**
 * Returns YES if `another` is of class ZDCOrderedDictionary,
 * and the receiver & another contain the same set of {key, value} tuples.
 *
 * This method corresponds to `[NSDictionary isEqualToDictionary:]`.
 *
 * @note It does NOT take into account the changeset of either ZDCDictionary instance.
 */
- (BOOL)isEqual:(nullable id)another;

/**
 * Returns YES if the receiver and `another` contain the same set of {key, value} tuples.
 * 
 * This method corresponds to `[NSDictionary isEqualToDictionary:]`.
 *
 * @note It does NOT take into account the changeset of either ZDCDictionary instance.
 */
- (BOOL)isEqualToDictionary:(nullable ZDCDictionary *)another;

@end

NS_ASSUME_NONNULL_END

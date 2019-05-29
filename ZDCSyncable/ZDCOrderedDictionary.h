/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCObject.h"
#import "ZDCSyncable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * ZDCOrderedDictionary tracks changes made to an ordered dictionary.
 *
 * An ordered dictionary is a combination between a dictionary & an array.
 * That is, it provides an ordered set of {key, value} pairs.
 *
 * In addition to its core functionality, it also provides the following set of features:
 * - it can be made immutable (via `-[ZDCObject makeImmutable]` method)
 * - it implements the ZDCSyncable protocol and thus:
 * - it tracks all changes and can provide a changeset (which encodes the change info)
 * - it supports undo & redo
 * - it supports merge operations
 */
@interface ZDCOrderedDictionary<KeyType, ObjectType> : ZDCObject <NSCoding, NSCopying, NSFastEnumeration, ZDCSyncable>

/**
 * Creates an empty orderedDictionary.
 */
- (instancetype)init;

/**
 * Creates a dictionary that contains the {key, value} tuples from the given input.
 * There's no particular order associated with the items.
 *
 * @param raw
 *   The {key,value} tuples will be stored in the created orderedDictionary.
 */
- (instancetype)initWithDictionary:(nullable NSDictionary<KeyType, ObjectType> *)raw;

/**
 * Creates a dictionary that contains the {key, value} tuples from the given input.
 * There's no particular order associated with the items.
 *
 * @param raw
 *   The {key,value} tuples will be stored in the created orderedDictionary.
 *
 * @param copyItems
 *   If set to YES, the values will be copied when storing in the ZDCDictionary.
 *   This means the values will need to support the NSCopying protocol.
 */
- (instancetype)initWithDictionary:(nullable NSDictionary<KeyType, ObjectType> *)raw copyItems:(BOOL)copyItems;

/**
 * Creates a new orderedDictionary by copying to given one.
 *
 * @param another
 *   The source orderedDictionary to copy. Both the tuples & order are copied.
 */
- (instancetype)initWithOrderedDictionary:(nullable ZDCOrderedDictionary<KeyType, ObjectType> *)another;

/**
 * Creates a new orderedDictionary by copying to given one.
 *
 * @param another
 *   The source orderedDictionary to copy. Both the tuples & order are copied.
 *
 * @param flag
 *   If set to YES, the values will be copied when storing in the ZDCDictionary.
 *   This means the values will need to support the NSCopying protocol.
 */
- (instancetype)initWithOrderedDictionary:(nullable ZDCOrderedDictionary<KeyType, ObjectType> *)another
                                copyItems:(BOOL)flag;

#pragma mark Raw

/**
 * Returns a reference to the underlying NSDictionary that the ZDCOrderedDictionary instance is wrapping.
 *
 * @note The returned value is a copy of the underlying NSMutableDictionary.
 *       Thus changes to the ZDCOrderedDictionary will not be reflected in the returned value.
 */
@property (nonatomic, copy, readonly) NSDictionary<KeyType, ObjectType> *rawDictionary;

/**
 * Returns a reference to the underlying NSArray that the ZDCDictionary instance is wrapping.
 *
 * @note The returned value is a copy of the underlying NSMutableArray.
 *       Thus changes to the ZDCOrderedDictionary will not be reflected in the returned value.
 */
@property (nonatomic, copy, readonly) NSArray<KeyType> *rawOrder;

#pragma mark Reading

/**
 * The number of items stored in the ordered dictionary.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 * Returns the first item in the orderedDictionary.
 * If the orderedDictionary is empty, returns nil.
 *
 * @note This method returns the value component of the {key, value} tuple.
 */
@property (nonatomic, readonly, nullable) ObjectType firstObject;

/**
 * Returns the last item in the orderedDictionary.
 * If the orderedDictionary is empty, returns nil.
 *
 * @note This method returns the value component of the {key, value} tuple.
 */
@property (nonatomic, readonly, nullable) ObjectType lastObject;

/**
 * Returns the (ordered) array of keys stored in the dictionary.
 *
 * @note This method is equivalent to the `rawOrder` method.
 */
- (NSArray<KeyType> *)allKeys;

/**
 * Returns YES if there's a value stored in the dictionary for the given key.
 * This method is faster than calling `objectForKey:`, and then checking to see if the returned object is non-nil.
 */
- (BOOL)containsKey:(KeyType)key;

/**
 * Returns the index of key within the orderedDictionary.
 * If the key isn't present, returns NSNotFound.
 */
- (NSUInteger)indexForKey:(KeyType)key;

/**
 * Returns the stored object for the given key.
 */
- (nullable ObjectType)objectForKey:(KeyType)key;

/**
 * Returns the key at the given index.
 * Throws an exception if the given index is out-of-bounds.
 */
- (KeyType)keyAtIndex:(NSUInteger)idx;

/**
 * Returns the object at the given index.
 * Throws an exception if the given index is out-of-bounds.
 */
- (ObjectType)objectAtIndex:(NSUInteger)idx;

/**
 * Returns the stored object for the given key.
 *
 * Allows you to use code syntax:
 * ```
 * value = orderedDictionary[key]
 * ```
 */
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;

/**
 * Allows you to use code syntax:
 * ```
 * value = orderedDictionary[index]
 * ```
 *
 * @note This method returns the value component of the {key, value} tuple.
 */
- (nullable ObjectType)objectAtIndexedSubscript:(NSUInteger)idx;

#pragma mark Writing

/**
 * Sets the value for the key, replacing any previous value that may have existed.
 * If the item is being added, it's automatically added to the end of the array.
 */
- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key;

/**
 * Sets the value for the key, replacing any previous value that may have existed.
 * If the item is being added, it's automatically added to the end of the array.
 *
 * Allows you to use code syntax:
 * ```
 * orderedDictionary[key] = value
 * ```
 */
- (void)setObject:(nullable ObjectType)object forKeyedSubscript:(KeyType)key;

/**
 * This method works the same as `setObject:forKey:`, except that it will return the index of the object.
 * If the object was added, it will return `count-1`, since the item was added to the end of the array.
 * If the key already existed, it will return its current index in the array (old value is replaced with new value).
 *
 * Returns NSNotFound if you attempt an illegal operation such as passing a nil object or a nil key.
**/
- (NSUInteger)addObject:(ObjectType)object forKey:(KeyType)key;

/**
 * This method works similarly to a `setObject:forKey:` operation with one difference:
 * - If the object was added (did NOT previously exist) it will be inserted at the given index,
 *   and that index is returned.
 * - If the item already existed, it will return its current index in the array.
 *
 * If the given index is out-of-bounds, it will be ignored, and the item will be added at the end of the array.
 * Returns NSNotFound if you attempt an illegal operation such as passing a nil object or a nil key.
 */
- (NSUInteger)insertObject:(ObjectType)object forKey:(KeyType)key atIndex:(NSUInteger)index;

/**
 * Use this method when you only need to change an item's index.
 *
 * @param oldIndex
 *   The current index of the item.
 *
 * @param newIndex
 *   The index to use AFTER the index has been removed:
 *   - Step 1: `[array removeObjectAtIndex:oldIndex]`
 *   - Step 2: `[array insertObject:obj atIndex:<newIndexGoesHere>]`
 *
 * First, this method is faster than removing the item & then re-adding it.
 * Second, this method will properly track the change (i.e. the intent to change the item's index).
 * Thus you'll benefit from proper syncing of this action.
 */
- (void)moveObjectAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex;

/**
 * Removes the {key, value} tuple from the orderedDictionary if the key exists.
 * If the key doesn't exist, no changes are made.
 */
- (void)removeObjectForKey:(KeyType)key;

/**
 * Removes all items from the dictionary matching the given list of keys.
 */
- (void)removeObjectsForKeys:(NSArray<KeyType> *)keys;

/**
 * Removes the {key, value} tuple at the given index.
 * Does nothing if the index is out-of-bounds (no exception is thrown).
 */
- (void)removeObjectAtIndex:(NSUInteger)idx;

#pragma mark Enumeration

/**
 * Enumerates the keys in the ordered dictionary.
 * The enumeration is done in order, from first (index 0) to last.
 */
- (void)enumerateKeysUsingBlock:(void (^)(KeyType key, NSUInteger idx, BOOL *stop))block;

/**
 * Enumerates the {key, value} tuples in the ordered dictionary.
 * The enumeration is done in order, from first (index 0) to last.
 */
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(KeyType key, ObjectType obj, NSUInteger idx, BOOL *stop))block;

#pragma mark Equality

/**
 * Returns YES if `another` is of class ZDCOrderedDictionary,
 * and receiver & another contain the same {key, value} tuples in the same order.
 *
 * @note It does NOT take into account the changeset of either ZDCDictionary instance.
 */
- (BOOL)isEqual:(nullable id)another;

/**
 * Returns YES if receiver & another contain the same {key, value} tuples in the same order.
 *
 * @note It does NOT take into account the changeset of either ZDCDictionary instance.
 */
- (BOOL)isEqualToOrderedDictionary:(nullable ZDCOrderedDictionary *)another;

@end

NS_ASSUME_NONNULL_END

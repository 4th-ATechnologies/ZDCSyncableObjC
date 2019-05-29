/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCObject.h"
#import "ZDCSyncable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * ZDCArray tracks changes to an array.
 *
 * It's designed act like a drop-in replacement for a mutable array.
 *
 * In addition to its core functionality, it also provides the following set of features:
 * - it can be made immutable (via `-[ZDCObject makeImmutable]` method)
 * - it implements the ZDCSyncable protocol and thus:
 * - it tracks all changes made to the dictionary, and can provide a changeset (which encodes the change info)
 * - it supports undo & redo
 * - it supports merge operations
 */
NS_SWIFT_NAME(ZDCArray_ObjC)
@interface ZDCArray<ObjectType> : ZDCObject <NSCoding, NSCopying, NSFastEnumeration, ZDCSyncable>

/**
 * Creates an empty array.
 */
- (instancetype)init;

/**
 * Creates a ZDCArray initialized by copying the given array.
 *
 * @note To initialize from another ZDCArray, you can either copy the original,
 *       or use this method combined with `-[ZDCArray rawArray]` to provide the parameter.
 */
- (instancetype)initWithArray:(nullable NSArray<ObjectType> *)array;

/**
 * Creates a ZDCArray initialized by copying the given array.
 *
 * @note To initialize from another ZDCArray, you can either copy the original,
 *       or use this method combined with `-[ZDCArray rawArray]` to provide the parameter.
 *
 * @param array
 *   The set to copy.
 *
 * @param copyItems
 *   If set to YES, the values will be copied when storing in the ZDCArray.
 *   This means the values will need to support the NSCopying protocol.
 */
- (instancetype)initWithArray:(nullable NSArray<ObjectType> *)array copyItems:(BOOL)copyItems;

#pragma mark Raw

/**
 * Returns a reference to the underlying NSArray that the ZDCArray instance is wrapping.
 *
 * @note The returned value is a copy of the underlying NSMutableArray.
 *       Thus changes to the ZDCArray will not be reflected in the returned value.
 */
@property (nonatomic, copy, readonly) NSArray<ObjectType> *rawArray;

#pragma mark Reading

/**
 * The number of items stored in the set.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 * Returns the object stored at the given index.
 *
 * @important Raises an NSRangeException if index is out-of-bounds.
 */
- (ObjectType)objectAtIndex:(NSUInteger)idx;

/**
 * Returns the object stored at the given index.
 *
 * Allows you to use syntax:
 * ```
 * value = zdcArray[index]
 * ```
 *
 * @important Raises an NSRangeException if index is out-of-bounds.
 */
- (ObjectType)objectAtIndexedSubscript:(NSUInteger)idx;

/**
 * Returns YES if the object is contained in the array.
 *
 * Starting at index 0, each element of the array is checked for equality with anObject
 * until a match is found or the end of the array is reached.
 * Objects are considered equal if isEqual: returns YES.
 */
- (BOOL)containsObject:(ObjectType)anObject;

/**
 * Returns the index of the object within the array.
 * If not found in the array, returns NSNotFound.
 *
 * Starting at index 0, each element of the array is checked for equality with anObject
 * until a match is found or the end of the array is reached.
 * Objects are considered equal if isEqual: returns YES.
 */
- (NSUInteger)indexOfObject:(ObjectType)anObject;

#pragma mark Writing

/**
 * Adds the object to the end of the array.
 *
 * @important Raises an NSInvalidArgument exception if the object is nil.
 */
- (void)addObject:(ObjectType)object;

/**
 * Inserts the object within the array at the given index.
 *
 * @important Raises an NSInvalidArgument exception if the object is nil.
 * @important Raises an NSRangeException if index is greater than the number of elements in the array.
 */
- (void)insertObject:(ObjectType)object atIndex:(NSUInteger)idx;

/**
 * Inserts the object within the array at the given index.
 *
 * Allows you to use code syntax:
 * ```
 * zdcArray[index] = value
 * ```
 */
- (void)setObject:(ObjectType)obj atIndexedSubscript:(NSUInteger)idx;

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
 * Removes all occurrences in the array of a given object.
 *
 * This method determines a match by comparing anObject to the objects
 * in the receiver using the isEqual: method. If the array does not
 * contain anObject, the method has no effect (although it does incur
 * the overhead of searching the contents).
 */
- (void)removeObject:(ObjectType)object;

/**
 * Removes the object from the array currently at the given index.
 */
- (void)removeObjectAtIndex:(NSUInteger)idx;

/**
 * Removes all objects from the array.
 * Afterwards the array will be empty.
 */
- (void)removeAllObjects;

#pragma mark Enumeration

/**
 * Enumerates all objects in the array,
 * starting from index 0 and ending with the largest index in the array.
 */
- (void)enumerateObjectsUsingBlock:(void (^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;

/**
 * An enumerator object that lets you access each object in the array,
 * in order, from the element at the lowest index upwards.
 *
 * @note It is more efficient to use the fast enumeration protocol.
 */
- (NSEnumerator<ObjectType> *)objectEnumerator;

/**
 * Returns an enumerator that can be used to enumerate the objects in reverse order.
 */
- (NSEnumerator<ObjectType> *)reverseObjectEnumerator;

#pragma mark Equality

/**
 * Returns YES if `another` is of class ZDCArray.
 * and the receiver & another contain the same objects in the same order.
 *
 * This method corresponds to `[NSArray isEqualToArray:]`.
 *
 * @note It does NOT take into account the changeset of either ZDCArray instance.
 */
- (BOOL)isEqual:(nullable id)another;

/**
 * Returns YES if the receiver and `another` contain the same objects in the same order.
 *
 * This method corresponds to `[NSArray isEqualToArray:]`.
 *
 * @note It does NOT take into account the changeset of either ZDCArray instance.
 */
- (BOOL)isEqualToArray:(nullable ZDCArray *)another;

@end

NS_ASSUME_NONNULL_END

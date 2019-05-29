/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCObject.h"
#import "ZDCSyncable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * ZDCOrderedSet tracks changes made to an ordered set.
 *
 * It's designed to act like a drop-in replacement for NSOrderedSet.
 *
 * In addition to its core functionality, it also provides the following set of features:
 * - instances can be made immutable (via `-[ZDCObject makeImmutable]` method)
 * - it implements the ZDCSyncable protocol and thus:
 * - it tracks all changes and can provide a changeset (which encodes the changes)
 * - it supports undo & redo
 * - it supports merge operations
**/
NS_SWIFT_NAME(ZDCOrderedSet_ObjC)
@interface ZDCOrderedSet<ObjectType> : ZDCObject <NSCoding, NSCopying, NSFastEnumeration, ZDCSyncable>

/**
 * Creates an empty ordered set.
 */
- (instancetype)init;

/**
 * Creates an ordered set initialized from the given array.
 */
- (instancetype)initWithArray:(nullable NSArray<ObjectType> *)array;

/**
 * Creates an ordered set initialized from the given array.
 *
 * @param array
 *   The array to initialize the set with.
 *
 * @param copyItems
 *   If set to YES, the values will be copied when storing in the ZDCOrderedSet.
 *   This means the values will need to support the NSCopying protocol.
 */
- (instancetype)initWithArray:(nullable NSArray<ObjectType> *)array copyItems:(BOOL)copyItems;

/**
 * Creates an ordered set initialized from the given set.
 * The order is indeterminate.
 */
- (instancetype)initWithSet:(nullable NSSet<ObjectType> *)set;

/**
 * Creates an ordered set initialized from the given set.
 * The order is indeterminate.
 *
 * @param set
 *   The source to initialize the ordered set with.
 *
 * @param copyItems
 *   If set to YES, the values will be copied when storing in the ZDCOrderedSet.
 *   This means the values will need to support the NSCopying protocol.
 */
- (instancetype)initWithSet:(nullable NSSet<ObjectType> *)set copyItems:(BOOL)copyItems;

/**
 * Creates a ZDCOrderedSet instance initialized by copying the given NSOrderedSet.
 */
- (instancetype)initWithOrderedSet:(nullable NSOrderedSet<ObjectType> *)orderedSet;

/**
 * Creates a ZDCOrderedSet instance initialized by copying the given NSOrderedSet.
 *
 * @param orderedSet
 *   The source to initialize the ZDCOrderedSet with.
 *
 * @param copyItems
 *   If set to YES, the values will be copied when storing in the ZDCOrderedSet.
 *   This means the values will need to support the NSCopying protocol.
 */
- (instancetype)initWithOrderedSet:(nullable NSOrderedSet<ObjectType> *)orderedSet copyItems:(BOOL)copyItems;

#pragma mark Raw

/**
 * Returns a reference to the underlying NSOrderedSet that the ZDCOrderedSet instance is wrapping.
 *
 * @note The returned value is a copy of the underlying NSMutableOrderedSet.
 *       Thus changes to the ZDCOrderedSet will not be reflected in the returned value.
 */
@property (nonatomic, copy, readonly) NSOrderedSet<ObjectType> *rawOrderedSet;

#pragma mark Reading

/**
 * The number of items stored in the set.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 * Returns the first item (at index 0) in the orderedSet.
 * If the orderedSet is empty, returns nil.
 */
@property (nonatomic, readonly, nullable) ObjectType firstObject;

/**
 * Returns the last item (with largest index) in the orderedSet.
 * If the orderedSet is empty, returns nil.
 */
@property (nonatomic, readonly, nullable) ObjectType lastObject;

/**
 * Returns a Boolean value that indicates whether a given object is present in the ordered set.
 */
- (BOOL)containsObject:(ObjectType)object;

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
 * Returns the index of the object within the array.
 * If not found in the array, returns NSNotFound.
 */
- (NSUInteger)indexOfObject:(ObjectType)object;

#pragma mark Writing

/**
 * Appends a given object to the end of the mutable ordered set, if it is not already a member.
 */
- (void)addObject:(ObjectType)object;

/**
 * Inserts the given object at the specified index of the mutable ordered set, if it is not already a member.
 *
 * @important Raises an NSRangeException if idx is greater than the number of elements in the mutable ordered set.
 */
- (void)insertObject:(ObjectType)object atIndex:(NSUInteger)idx;

/**
 * Replaces the given object at the specified index of the mutable ordered set.
 *
 * @important Raises an NSRangeException if idx is greater than the number of elements in the mutable ordered set.
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
 * Removes a given object from the mutable ordered set (if it exists).
 */
- (void)removeObject:(ObjectType)object;

/**
 * Removes a the object at the specified index from the mutable ordered set.
 */
- (void)removeObjectAtIndex:(NSUInteger)idx;

/**
 * Removes all objects from the ordered set.
 * Afterwards the set will be empty.
 */
- (void)removeAllObjects;

#pragma mark Enumeration

/**
 * Enumerates all objects in the ordered set,
 * starting from index 0 and ending with the largest index.
 */
- (void)enumerateObjectsUsingBlock:(void (^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;

/**
 * An enumerator object that lets you access each object in the ordered set,
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
 * Returns YES if `another` is of class ZDCOrderedSet,
 * and the receiver & another contain the same objects in the same order.
 *
 * This method corresponds to `[NSOrderedSet isEqualToOrderedSet:]`.
 *
 * @note It does NOT take into account the changeset of either ZDCOrderedSet instance.
 */
- (BOOL)isEqual:(nullable id)another;

/**
 * Returns YES if the receiver and `another` contain the same objects in the same order.
 *
 * This method corresponds to `[NSOrderedSet isEqualToOrderedSet:]`.
 *
 * @note It does NOT take into account the changeset of either ZDCOrderedSet instance.
 */
- (BOOL)isEqualToOrderedSet:(nullable ZDCOrderedSet *)another;

@end

NS_ASSUME_NONNULL_END

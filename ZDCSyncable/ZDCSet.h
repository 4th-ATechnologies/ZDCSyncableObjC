/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCObject.h"
#import "ZDCSyncable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * ZDCSet tracks changes to a set.
 *
 * It's designed act like a mutable set.
 *
 * In addition to its core functionality, it also provides the following set of features:
 * - it can be made immutable (via `-[ZDCObject makeImmutable]` method)
 * - it implements the ZDCSyncable protocol and thus:
 * - it tracks all changes and can provide a changeset (which encodes the changes info)
 * - it supports undo & redo
 * - it supports merge operations
 */
NS_SWIFT_NAME(ZDCSet_ObjC)
@interface ZDCSet<ObjectType> : ZDCObject <NSCoding, NSCopying, NSFastEnumeration, ZDCSyncable>

/**
 * Creates an empty set
 */
- (instancetype)init;

/**
 * Creates a set initialized with the elements from the given array.
 */
- (instancetype)initWithArray:(nullable NSArray<ObjectType> *)array;

/**
 * Creates a set initialized with the elements from the given array.
 *
 * @param array
 *   The array to initialize the set with.
 *
 * @param copyItems
 *   If set to YES, the values will be copied when storing in the ZDCDictionary.
 *   This means the values will need to support the NSCopying protocol.
 */
- (instancetype)initWithArray:(nullable NSArray<ObjectType> *)array copyItems:(BOOL)copyItems;

/**
 * Creates a new set by copying the given set.
 *
 * @note To initialize from another ZDCSet, you can either copy the original,
 *       or use this method combined with `-[ZDCSet rawSet]` to provide the parameter.
 */
- (instancetype)initWithSet:(nullable NSSet<ObjectType> *)set;

/**
 * Creates a new set by copying the given set.
 *
 * @note To initialize from another ZDCSet, you can either copy the original,
 *       or use this method combined with `-[ZDCSet rawSet]` to provide the parameter.
 *
 * @param set
 *   The set to copy.
 *
 * @param copyItems
 *   If set to YES, the values will be copied when storing in the ZDCDictionary.
 *   This means the values will need to support the NSCopying protocol.
 */
- (instancetype)initWithSet:(nullable NSSet<ObjectType> *)set copyItems:(BOOL)copyItems;

#pragma mark Raw

/**
 * Returns a reference to the underlying NSSet that the ZDCSet instance is wrapping.
 *
 * @note The returned value is a copy of the underlying NSMutableSet.
 *       Thus changes to the ZDCSet will not be reflected in the returned value.
 */
@property (nonatomic, copy, readonly) NSSet<ObjectType> *rawSet;

#pragma mark Reading

/**
 * The number of items stored in the set.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 * Returns YES if the object is included in the set.
 */
- (BOOL)containsObject:(ObjectType)anObject;

#pragma mark Writing

/**
 * Adds the given object to the set (if it's not already included).
 */
- (void)addObject:(ObjectType)object;

/**
 * Removes the given object from the set (if it's currently included).
 */
- (void)removeObject:(ObjectType)object;

/**
 * Removes all objects from the set.
 * Afterwards the set will be empty.
 */
- (void)removeAllObjects;

#pragma mark Enumeration

/**
 * Enumerates the objects within the set.
 * The enumeration is performed in no particular order.
 */
- (void)enumerateObjectsUsingBlock:(void (^)(ObjectType obj, BOOL *stop))block;

#pragma mark Equality

/**
 * Returns YES if `another` is of class ZDCSet,
 * and the receiver & another contain the same objects.
 *
 * This method corresponds to `[NSSet isEqualToSet:]`.
 *
 * @note It does NOT take into account the changeset of either ZDCSet instance.
 */
- (BOOL)isEqual:(nullable id)another;

/**
 * Returns YES if the receiver and `another` contain the same objects.
 *
 * This method corresponds to `[NSSet isEqualToSet:]`.
 *
 * @note It does NOT take into account the changeset of either ZDCSet instance.
 */
- (BOOL)isEqualToSet:(nullable ZDCSet *)another;

@end

NS_ASSUME_NONNULL_END

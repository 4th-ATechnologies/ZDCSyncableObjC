/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * ZDCNull is used internally to represent nil/null.
 * Do NOT use it directly. If you want to store null, then you should use NSNull.
 *
 * Why:
 *   We needed our own special version because we needed a way to differentiate from NSNull.
 *
 * Where it's used:
 *   In changeset dictionaries, ZDCNull is used as a placeholder to represent the absence of value.
 *   For example, if the originalValue of an object is ZDCNull, this would mean the object was added.
 *
 * Notes:
 *   ZDCNull is a singleton, so you can use `==` to do comparisons: if (obj == [ZDCNull null]) {...}
 *   You cannot alloc/init an ZDCNull instance. (You can try, but it will throw an exception.)
 *   This is true: [ZDCNull null] == [[ZDCNull null] copy].
 *   Also, deserialzing an ZDCNull will properly return the singleton.
**/
NS_SWIFT_NAME(ZDCNull_ObjC)
@interface ZDCNull : NSObject <NSCoding, NSCopying>

+ (id)null;

@end

NS_ASSUME_NONNULL_END

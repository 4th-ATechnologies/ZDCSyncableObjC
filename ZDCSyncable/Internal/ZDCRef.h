/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ZDCRef is used within changesets.
 *
 * Where it's used:
 *   In changeset dictionaries, ZDCRef is used as a placeholder to indicate the referenced
 *   object conforms to the ZDCSyncable protocol, and has its own changeset.
 *
 * Notes:
 *   ZDCRef is a singleton, so you can use `==` to do comparisons: if (obj == [ZDCRef ref]) {...}
 *   You cannot alloc/init an ZDCRef instance. (You can try, but it will throw an exception.)
 *   This is true: [ZDCRef ref] == [[ZDCRef ref] copy].
 *   Also, deserialzing an ZDCRef will properly return the singleton.
**/
@interface ZDCRef : NSObject <NSCoding, NSCopying>

+ (id)ref;

@end

NS_ASSUME_NONNULL_END

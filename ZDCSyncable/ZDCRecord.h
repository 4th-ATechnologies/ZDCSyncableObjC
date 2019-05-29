/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCObject.h"
#import "ZDCSyncable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The ZDCRecord class is designed to be subclassed.
 *
 * It provides the following set of features for your subclass:
 * - instances can be made immutable (via `-[ZDCObject makeImmutable]` method)
 * - it implements the ZDCSyncable protocol and thus:
 * - it tracks all changes and can provide a changeset (which encodes the changes info)
 * - it supports undo & redo
 * - it supports merge operations
 */
NS_SWIFT_NAME(ZDCRecord_ObjC)
@interface ZDCRecord : ZDCObject <ZDCSyncable>

//
// SUBCLASS ME !
//

@end

NS_ASSUME_NONNULL_END

/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCRecord.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Sample class - used for unit testing.
 *
 * Goal: test a simple subclass of ZDCRecord.
 */
@interface SimpleRecord : ZDCRecord <NSCopying>

@property (nonatomic, copy, readwrite, nullable) NSString *someString;
@property (nonatomic, assign, readwrite) NSInteger someInteger;

- (BOOL)isEqualToSimpleRecord:(SimpleRecord *)another;

@end

NS_ASSUME_NONNULL_END

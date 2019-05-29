/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCRecord.h"
#import "ZDCDictionary.h"
#import "ZDCSet.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Sample class - used for unit testing.
 *
 * Goal: Test a subclass of ZDCRecord with a bit more complexity.
 *       Here we have a record that also contains an ZDCDictionary & ZDCSet.
 *       So changes to these objects should also be included in `changeset`, etc.
 */
@interface ComplexRecord : ZDCRecord

@property (nonatomic, copy, readwrite) NSString *someString;
@property (nonatomic, assign, readwrite) NSInteger someInteger;

@property (nonatomic, readonly) ZDCDictionary<NSString*, NSString*> *dict;
@property (nonatomic, readonly) ZDCSet<NSString*> *set;

- (BOOL)isEqualToComplexRecord:(ComplexRecord *)another;

@end

NS_ASSUME_NONNULL_END

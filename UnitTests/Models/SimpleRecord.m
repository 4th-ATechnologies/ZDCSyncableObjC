/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "SimpleRecord.h"

@implementation SimpleRecord

@synthesize someString = someString;
@synthesize someInteger = someInteger;

- (id)copyWithZone:(NSZone *)zone
{
	SimpleRecord *copy = [super copyWithZone:zone]; // [ZDCRecord copyWithZone:]
	
	copy->someString = self->someString;
	copy->someInteger = self->someInteger;
	
	return copy;
}

- (BOOL)isEqualToSimpleRecord:(SimpleRecord *)another
{
	if (![self->someString isEqualToString:another->someString]) return NO;
	if (self->someInteger != another->someInteger) return NO;
	
	return YES;
}

@end

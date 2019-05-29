#import "ComplexRecord.h"

@implementation ComplexRecord

@synthesize someString = someString;
@synthesize someInteger = someInteger;

@synthesize dict = dict;
@synthesize set = set;

- (instancetype)init
{
	if ((self = [super init]))
	{
		dict = [[ZDCDictionary alloc] init];
		set = [[ZDCSet alloc] init];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	ComplexRecord *copy = [super copyWithZone:zone]; // [ZDCRecord copyWithZone:]
	
	copy->someString = self->someString;
	copy->someInteger = self->someInteger;
	
	copy->dict = [self->dict copy];
	copy->set = [self->set copy];
	
	return copy;
}

- (BOOL)isEqualToComplexRecord:(ComplexRecord *)another
{
	if (![self->someString isEqualToString:another->someString]) return NO;
	if (self->someInteger != another->someInteger) return NO;
	
	if (![self->dict isEqualToDictionary:another->dict]) return NO;
	if (![self->set isEqualToSet:another->set]) return NO;
	
	return YES;
}

@end

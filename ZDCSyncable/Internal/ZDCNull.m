/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCNull.h"


@implementation ZDCNull

static ZDCNull *singleton;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized)
	{
		initialized = YES;
		singleton = [[ZDCNull alloc] init];
	}
}

+ (id)null
{
	return singleton;
}

- (instancetype)init
{
	if (singleton != nil)
	{
		@throw [NSException exceptionWithName:@"ZDCNull" reason:@"Must use singleton via [ZDCNull null]" userInfo:nil];
	}
	
	self = [super init];
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	return [ZDCNull null];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	// Nothing internal to encode.
	// NSCoder will record the class (ZDCNull) automatically.
}

- (id)copyWithZone:(NSZone *)zone
{
	return self; // immutable singleton
}

- (NSString *)description
{
	return @"<ZDCNull>";
}

@end

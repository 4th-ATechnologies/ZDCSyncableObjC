/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCRef.h"

@implementation ZDCRef

static ZDCRef *singleton;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized)
	{
		initialized = YES;
		singleton = [[ZDCRef alloc] init];
	}
}

+ (id)ref
{
	return singleton;
}

- (instancetype)init
{
	if (singleton != nil)
	{
		@throw [NSException exceptionWithName:@"ZDCRef" reason:@"Must use singleton via [ZDCRef ref]" userInfo:nil];
	}
	
	self = [super init];
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	return [ZDCRef ref];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	// Nothing internal to encode.
	// NSCoder will record the class (ZDCRef) automatically.
}

- (id)copyWithZone:(NSZone *)zone
{
	return self; // immutable singleton
}

- (NSString *)description
{
	return @"<ZDCRef>";
}

@end

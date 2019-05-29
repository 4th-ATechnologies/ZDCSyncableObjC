/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCObject.h"
#import "ZDCObjectSubclass.h"

#import <objc/runtime.h>


@implementation ZDCObject {
@private
	
	void *observerContext;
	BOOL isImmutable;
	BOOL hasChanges;
}

/**
 * Make sure all your subclasses call this method ([super init]).
 */
- (instancetype)init
{
	if ((self = [super init]))
	{
		// Turn on KVO for object.
		// We do this so we can get notified if the user is about to make changes to one of the object's properties.
		//
		// Don't worry, this doesn't create a retain cycle.
		//
		// Note: It's important use a unique observer context.
		// In the past, we saw crashes in iOS 11.
		//
		// https://forums.developer.apple.com/thread/70097
		// https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOBasics.html
	
		observerContext = &observerContext;
		[self addObserver:self forKeyPath:@"isImmutable" options:0 context:observerContext];
	}
	return self;
}

- (void)dealloc
{
	if (observerContext) {
		[self removeObserver:self forKeyPath:@"isImmutable" context:observerContext];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * In this example, all copies are automatically mutable.
 * So all you have to do in your code is something like this:
 * 
 * [databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction]{
 * 
 *     Car *car = [transaction objectForKey:carId inCollection:@"cars"];
 *     car = [car copy]; // make mutable copy
 *     car.speed = newSpeed;
 *     
 *     [transaction setObject:car forKey:carId inCollection:@"cars"];
 * }];
 * 
 * Which means all you have to do is implement the copyWithZone method in your model classes.
**/
- (id)copyWithZone:(NSZone *)zone
{
	// Subclasses should call this method via [super copyWithZone:zone].
	// For example:
	//
	//   MySubclass *copy = [super copyWithZone:zone];
	//   copy->ivar1 = [ivar1 copy];
	//   copy->ivar2 = ivar2;
	//   return copy;
	
	ZDCObject *copy = [[[self class] alloc] init];
	copy->isImmutable = NO;
	copy->hasChanges = self->hasChanges;
	
	return copy;
}

/**
 * For complicated copying scenarios, such as nested deep copies.
 * This method is declared in: ZDCObjectSubclass.h
 */
- (void)copyChangeTrackingTo:(id)another
{
	if ([another isKindOfClass:[ZDCObject class]])
	{
		__unsafe_unretained ZDCObject *copy = (ZDCObject *)another;
		if (!copy->isImmutable)
		{
			copy->hasChanges = self->hasChanges;
		}
	}
}

/**
 * There's no need to override this method.
 * Just override copyWithZone: like usual for the NSCopying protocol.
**/
- (instancetype)immutableCopy
{
	typeof(self) copy = [self copy];
	
	// This code is wrong:
//	copy->isImmutable = YES;
	//
	// Because the `makeImmutable` method may be overriden by subclasses,
	// and we need to go through this method for proper immutability.
	// 
	[copy makeImmutable];
	
	return copy;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Immutability
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize isImmutable = isImmutable;

/**
 * See header file for description.
 */
- (void)makeImmutable
{
	if (!isImmutable)
	{
		// Set immutable flag
		isImmutable = YES;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Monitoring
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * See header file for description.
 */
- (BOOL)hasChanges
{
	return hasChanges;
}

/**
 * See header file for description.
 */
- (void)clearChangeTracking
{
	hasChanges = NO;
	
	// Implementation Thoughts:
	//
	// There are 2 possibilities here:
	// A.) [changedProperties removeAllObjects]
	// B.) changedProperties = nil
	//
	// If the object has been made immutable, then changedProperties shouldn't be needed anymore.
	//
//	if (isImmutable) {
//		changedProperties = nil;
//	}
//	else {
//		[changedProperties removeAllObjects];
//	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCoding Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static NSString *const kPlistKey_Version        = @"version";
static NSString *const kPlistKey_BookmarkData   = @"bookmarkData";
static NSString *const kPlistKey_PathComponents = @"pathComponents";

/**
 * See header file for description.
 */
- (NSData *)serializeFileURL:(NSURL *)fileURL
{
	if (fileURL == nil) return nil;
	
	NSData *bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
	                         includingResourceValuesForKeys:nil
	                                          relativeToURL:nil
	                                                  error:NULL];
	
	if (bookmarkData) {
		return bookmarkData;
	}
	
	// Failed to create bookmark data.
	// This is usually because the file doesn't exist.
	// As a backup plan, we're going to get a bookmark of the closest parent directory that does exist.
	// And combine it with the relative path after that point.
	
	if (!fileURL.isFileURL) {
		return nil;
	}
	
	NSMutableArray *pathComponents = [NSMutableArray arrayWithCapacity:2];
	
	NSString *lastPathComponent = nil;
	NSURL *lastURL = nil;
	NSURL *parentURL = nil;
	
	lastURL = fileURL;
	
	lastPathComponent = [lastURL lastPathComponent];
	if (lastPathComponent)
		[pathComponents addObject:lastPathComponent];
	
	parentURL = [lastURL URLByDeletingLastPathComponent];
	
	while (![parentURL isEqual:lastURL])
	{
		bookmarkData = [parentURL bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
		                   includingResourceValuesForKeys:nil
		                                    relativeToURL:nil
		                                            error:NULL];
		
		if (bookmarkData) {
			break;
		}
		else
		{
			lastURL = parentURL;
			
			lastPathComponent = [lastURL lastPathComponent];
			if (lastPathComponent)
				[pathComponents insertObject:lastPathComponent atIndex:0];
			
			parentURL = [lastURL URLByDeletingLastPathComponent];
		}
	}
	
	if (bookmarkData)
	{
		NSDictionary *plistDict = @{
		  kPlistKey_Version: @(1),
		  kPlistKey_BookmarkData: bookmarkData,
		  kPlistKey_PathComponents: pathComponents
		};
		
		NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plistDict
		                                                               format:NSPropertyListBinaryFormat_v1_0
		                                                              options:0
		                                                                error:NULL];
		return plistData;
	}
	
	return nil;
}

/**
 * See header file for description.
 */
- (NSURL *)deserializeFileURL:(NSData *)data
{
	if (data.length == 0) return nil;
	
	const void *bytes = data.bytes;
	
	BOOL isBookmarkData = NO;
	BOOL isPlistData = NO;
	
	{
		NSData *magic = [@"book" dataUsingEncoding:NSASCIIStringEncoding];
		if (data.length > magic.length)
		{
			isBookmarkData = (memcmp(bytes, magic.bytes, magic.length) == 0);
		}
	}
	
	if (!isBookmarkData)
	{
		NSData *magic = [@"bplist" dataUsingEncoding:NSASCIIStringEncoding];
		if (data.length > magic.length)
		{
			isPlistData = (memcmp(bytes, magic.bytes, magic.length) == 0);
		}
	}
	
	BOOL isUnknown = !isBookmarkData && !isPlistData;
	
	if (isBookmarkData || isUnknown)
	{
		NSURL *url =
		  [NSURL URLByResolvingBookmarkData:data
		                            options:NSURLBookmarkResolutionWithoutUI
		                      relativeToURL:nil
		                bookmarkDataIsStale:NULL
		                              error:NULL];
		
		if (url) {
			return url;
		}
	}
	
	if (isPlistData || isUnknown)
	{
		id plistObj = [NSPropertyListSerialization propertyListWithData:data
		                                                        options:NSPropertyListImmutable
		                                                         format:NULL
		                                                          error:NULL];
		if ([plistObj isKindOfClass:[NSDictionary class]])
		{
			NSDictionary *plistDict = (NSDictionary *)plistObj;
			
			id data = plistDict[kPlistKey_BookmarkData];
			id comp = plistDict[kPlistKey_PathComponents];
			
			if ([data isKindOfClass:[NSData class]] && [comp isKindOfClass:[NSArray class]])
			{
				NSData *bookmarkData = (NSData *)data;
				NSArray *pathComponents = (NSArray *)comp;
				
				NSURL *url = [NSURL URLByResolvingBookmarkData:bookmarkData
				                                       options:NSURLBookmarkResolutionWithoutUI
				                                 relativeToURL:nil
				                           bookmarkDataIsStale:NULL
				                                         error:NULL];
				if (url)
				{
					NSString *path = [pathComponents componentsJoinedByString:@"/"];
					
					return [[NSURL URLWithString:path relativeToURL:url] absoluteURL];
				}
			}
		}
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method returns a list of all (known/static) properties that should be monitored.
 * That is, properties that should be considered immutable once the makeImmutable method has been invoked.
 *
 * It is designed to include all `@property` variables included in all subclasses.
 * Thus this method returns a list of all properties in each subclass in the hierarchy leading to "[self class]".
 *
 * However, this is not always exactly what you want.
 * For example, you may have properties which are simply used for caching:
 *
 * @property (nonatomic, strong, readwrite) UIImage *avatarImage;
 * @property (nonatomic, strong, readwrite) UIImage *cachedTransformedAvatarImage;
 *
 * In this example, you store the user's plain avatar image.
 * However, your code transforms the avatar in various ways for display in the UI.
 * So to reduce overhead, you'd like to cache these transformed images in the user object.
 * Thus the 'cachedTransformedAvatarImage' property doesn't actually mutate the user object. It's just a temp cache.
 *
 * So your subclass would override this method like so:
 *
 * + (NSMutableSet *)monitoredProperties
 * {
 *     NSMutableSet *monitoredProperties = [super monitoredProperties];
 *     [monitoredProperties removeObject:NSStringFromSelector(@selector(cachedTransformedAvatarImage))];
 *
 *     return monitoredProperties;
 * }
**/
+ (NSMutableSet<NSString*> *)monitoredProperties
{
	// Steps to override me (if needed):
	//
	// - Invoke [super monitoredProperties]
	// - Modify resulting mutable set
	// - Return modified set
	
	NSMutableSet<NSString*> *properties = nil;
	
	Class rootClass = [ZDCObject class];
	Class subClass = [self class];
	
	while (subClass != rootClass)
	{
		unsigned int count = 0;
		objc_property_t *propertyList = class_copyPropertyList(subClass, &count);
		if (propertyList)
		{
			if (properties == nil)
				properties = [NSMutableSet setWithCapacity:count];
			
			for (unsigned int i = 0; i < count; i++)
			{
				const char *name = property_getName(propertyList[i]);
				NSString *property = [NSString stringWithUTF8String:name];
				
				[properties addObject:property];
			}
			
			free(propertyList);
		}
		
		subClass = [subClass superclass];
	}
	
	// For some reason, we have to remove common NSObject stuff.
	// Even though, theoretically, these should only be listed within the NSObject subClass...
	// For some bizarre reason, objc is including them in other classes.
	//
	// So now we have to manually remove them.
	
	NSArray *fixup_NSObject = @[
		@"superclass", @"hash", @"description", @"debugDescription"
	];
	
	for (NSString *property in fixup_NSObject)
	{
		[properties removeObject:property];
	}
	
	// We also need to remove common ZDCObject stuff.
	// Again, these should be only listed in ZDCObject.
	// But again, objc confuses us, and will list them in other classes.
	
	NSArray *fixup_ZDCObject = @[
		@"isImmutable", @"hasChanges"
	];
	
	for (NSString *property in fixup_ZDCObject)
	{
		[properties removeObject:property];
	}
	
	if (properties)
		return properties;
	else
		return [NSMutableSet setWithCapacity:0];
}

/**
 * Generally you should NOT override this method.
 * Just override the class version of this method (above).
**/
- (NSSet *)monitoredProperties
{
	NSSet *cached = objc_getAssociatedObject([self class], _cmd);
	if (cached) return cached;
	
	NSSet *monitoredProperties = [[[self class] monitoredProperties] copy];
	
	objc_setAssociatedObject([self class], _cmd, monitoredProperties, OBJC_ASSOCIATION_RETAIN);
	return monitoredProperties;
}

/**
 * Override this method if your class includes 'dynamic' monitored properties.
 * That is, properties that should be monitored, but don't have dedicated '@property' declarations.
 *
 * Important:
 *   If a property (localKey) is not included in the 'monitoredProperties' set,
 *   then the class will be unable to automatically register for KVO notifications concerning the value.
 *   This means that you MUST manually invoke [self willChangeValueForKey:] & [self didChangeValueForKey:],
 *   in order to run the code for the corresponding methods in this class.
**/
- (BOOL)isMonitoredProperty:(NSString *)localKey
{
	return [self.monitoredProperties containsObject:localKey];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark KVO
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	if ([key isEqualToString:@"isImmutable"])
		return YES;
	else
		return [super automaticallyNotifiesObserversForKey:key];
}

+ (NSSet *)keyPathsForValuesAffectingIsImmutable
{
	// In order for the KVO magic to work, we specify that the isImmutable property is dependent
	// upon all other properties in the class that should become immutable.
	//
	// The code below ** attempts ** to do this automatically.
	// It does so by creating a list of all the properties in the class.
	//
	// Obviously this will not work for every situation.
	// In particular:
	//
	// - if you have custom setter methods that aren't specified as properties
	// - if you have other custom methods that modify the object
	//
	// To cover these edge cases, simply add code like the following at the beginning of such methods:
	//
	// - (void)recalculateFoo
	// {
	//     NSString *const key = NSStringFromSelector(@selector(foo));
	//     [self willChangeValueForKey:key];
	//
	//     ... normal code that modifies `foo` ivar ...
	//
	//     [self didChangeValueForKey:key];
	// }
	
	return [self monitoredProperties];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	// Nothing to do (but method is required to exist)
}

- (void)willChangeValueForKey:(NSString *)key
{
	if ([self isMonitoredProperty:key])
	{
		if (isImmutable)
		{
			@throw [self immutableExceptionForKey:key];
		}
		
		[self _willChangeValueForKey:key];
	}
	
	[super willChangeValueForKey:key];
}

- (void)_willChangeValueForKey:(NSString *)key
{
	// Subclass hook
}

- (void)didChangeValueForKey:(NSString *)key
{
	if ([self isMonitoredProperty:key])
	{
		if (!hasChanges) {
			hasChanges = YES;
		}
		
		[self _didChangeValueForKey:key];
	}
	
	[super didChangeValueForKey:key];
}

- (void)_didChangeValueForKey:(NSString *)key
{
	// Subclass hook
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Exceptions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSException *)immutableException
{
	return [self immutableExceptionForKey:nil];
}

- (NSException *)immutableExceptionForKey:(nullable NSString *)key
{
	NSString *reason;
	if (key) {
		reason = [NSString stringWithFormat:
		    @"Attempting to mutate immutable object. Class = %@, property = %@", NSStringFromClass([self class]), key];
	}
	else {
		reason = [NSString stringWithFormat:
		    @"Attempting to mutate immutable object. Class = %@", NSStringFromClass([self class])];
	}
	
	NSDictionary *userInfo = @{ NSLocalizedRecoverySuggestionErrorKey:
		@"To make modifications you should create a copy via [object copy]."
		@" You may then make changes to the copy."};
	
	return [NSException exceptionWithName:@"ZDCObjectException" reason:reason userInfo:userInfo];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Errors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSError *)hasChangesError
{
	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey:
			@"The object has unsaved changes, and the requested operation only works on a clean object."
	};
	
	return [NSError errorWithDomain:NSStringFromClass([self class]) code:100 userInfo:userInfo];
}

- (NSError *)malformedChangesetError
{
	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey:
			@"The changeset is malformed. "
	};
	
	return [NSError errorWithDomain:NSStringFromClass([self class]) code:101 userInfo:userInfo];
}

- (NSError *)mismatchedChangeset
{
	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey:
			@"The changeset appears to be mismatched."
			@" It does not line-up properly with the current state of the object."
	};
	
	return [NSError errorWithDomain:NSStringFromClass([self class]) code:102 userInfo:userInfo];
}

- (NSError *)incorrectObjectClass
{
	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey:
			[NSString stringWithFormat:
				@"Unable to merge cloudVersion. Not proper class. Expected: %@", NSStringFromClass([self class])]
	};
	
	return [NSError errorWithDomain:NSStringFromClass([self class]) code:103 userInfo:userInfo];
}

@end

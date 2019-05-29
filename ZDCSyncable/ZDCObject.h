/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * ZDCObject is a simple base class with a small, but very useful, set of functionality:
 *
 * - an object can be made immutable, via the `makeImmutable` method
 * - once immutable, attempts to change properties on the object will throw an exception
 *
 * You may even find it useful outside the context of syncing.
 *
 * A note on copying & mutability/immutability:
 *
 *   Apple's container classes in objective-c implement a strict immutable/mutable separation.
 *   For example, there is NSArray & NSMutableArray.
 *   For our puposes, it is often inconvenient to follow the same design.
 *   Additionally, doing so would make subclassing much more difficult.
 *   For example, if we had a base class of `Car`, and a sub-class of `Tesla`, this would imply
 *   we would have to create both `MutableCar` & `MutableTesla`.
 *   The purpose of this class is to add optional immutability to mutable-by-default classes.
 *   As such, it turns the copy/mutablCopy design on its head - instead we have copy/immutableCopy.
 *   That is, since our classes are mutable-by-default, a copy returns a mutable version.
 *   You can get an immutable version via immutableCopy.
 *   And we purposefully do not implement mutableCopy to avoid confusion.
 */
@interface ZDCObject : NSObject <NSCopying>

#pragma mark Immutability

/**
 * Returns whether or not the object has been marked immutable.
 * Once immutable, attempts to alter the object will throw an exception.
 */
@property (nonatomic, readonly) BOOL isImmutable;

/**
 * Marks the object as immutable.
 * Once immutable, attempts to alter the object will throw an exception.
 */
- (void)makeImmutable;

/**
 * Shorthand for: [[obj copy] makeImmutable]
 *
 * It turns these 2 lines:
 * copy = [obj copy];
 * [copy makeImmutable];
 *
 * Into this one-liner:
 * copy = [obj immutableCopy];
 */
- (instancetype)immutableCopy;


#pragma mark Change Tracking

/**
 * Returns whether or not there are any changes to the object.
 */
@property (nonatomic, readonly) BOOL hasChanges;

/**
 * Resets the hasChanges property to false.
 * Use this to wipe the slate, and restart change tracking from the current state.
 */
- (void)clearChangeTracking;

#pragma mark NSCoding Utilities

/**
 * Apple strongly encourages you to use NSURL objects for storing local file references,
 * but encoding/decoding a fileURL is kinda broken.
 * 
 * That is, code like this will appear to work, but will end up breaking things:
 * ```
 *   [coder encodeObject:myFileURL forKey:@"myFileURL"]     // does NOT work! Broken! :(
 *   myFileURL = [decoder decodeObjectForKey:@"myFileURL"]; // does NOT work! Broken! :(
 * ```
 *
 * And this is because that file might get moved.
 * This is especially troublesome on iOS, where everytime your app is updated, iOS moves your app's root folder.
 * Which, in turn, breaks every single NSURL you encoded using the above technique.
 * 
 * The solution is to use Apple's bookmark capability.
 * From their documentation on the topic: https://goo.gl/0Uqn5J
 *
 *   If you want to save the location of a file persistently, use the bookmark capabilities of NSURL.
 *   A bookmark is an opaque data structure, enclosed in an NSData object, that describes the location of a file.
 *   Whereas path and file reference URLs are potentially fragile between launches of your app,
 *   a bookmark can usually be used to re-create a URL to a file even in cases where the file was moved or renamed.
 *
 * These methods will "do the right thing" for you automatically.
 * They will first attempt to use the bookmark capabilities of NSURL.
 * If this fails because the file doesn't exist, the serializer will fallback to a hybrid binary plist system.
 * It will look for a parent directory that does exist, generate a bookmark of that,
 * and store the remainder as a relative path.
 *
 * Long story short, you can fix the problem by simply writing this instead:
 * ```
 *   [coder encodeObject:[self serializeFileURL:myFileURL] forKey:@"myFileURL"];      // works :)
 *   myFileURL = [self deserializeFileURL:[decoder decodeObjectForKey:@"myFileURL"]]; // works :)
 * ```
 */
- (nullable NSData *)serializeFileURL:(NSURL *)fileURL;

/**
 * Performs the inverse of `serializeFileURL:`. See that method for more documentation.
 */
- (nullable NSURL *)deserializeFileURL:(NSData *)fileURLData;

@end

NS_ASSUME_NONNULL_END

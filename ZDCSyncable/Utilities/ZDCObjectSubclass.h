/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCObject.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Includes useful methods for subclasses.
 *
 * This includes method that subclasses may wish to override,
 * as well as common shared methods for creating errors or exceptions.
 */
@interface ZDCObject ()

#pragma mark Class configuration

/**
 * Returns the set of properties that are "monitored" for changes.
 *
 * If a property is monitored, then:
 * - instances are configured to listen for changes to the property via KVO (key value observing)
 * - if the instance is marked as immutable, and a 'willChangeValueForKey:' notification is received,
 *   then the instance will throw an exception
 *
 * By default, all properties are monitored for changes.
 * This includes all properties in the top-level class, and also all properties in subclasses.
 *
 * Subclasses may override this method if certain proprties don't need to be monitored.
 * For examples, if a property simply acts as a cached value (and doesn't therefore infer a mutation),
 * then the subclass may wish to override this method, and remove that property from the list.
 */
+ (NSMutableSet<NSString *> *)monitoredProperties;

/**
 * Returns the list of properties that are being monitored.
 * The default implementation caches the class configuration.
 */
- (NSSet<NSString*> *)monitoredProperties;

/**
 * Returns YES if the given property is being monitored.
 *
 * Recall that if a property is being monitored:
 * - instances are configured to listen for changes to the property via KVO (key value observing)
 * - if the instance is marked as immutable, and a 'willChangeValueForKey' notification is received,
 *   then the instance will throw an exception
 */
- (BOOL)isMonitoredProperty:(NSString *)localKey;

#pragma make Copying

/**
 * For complicated copying scenarios, such a nested deep copies.
 */
- (void)copyChangeTrackingTo:(id)another;

#pragma mark Hooks

/**
 * Subclasses can override this method to get notified of changes.
 *
 * @note This method is only called for monitoredProperties.
 */
- (void)_willChangeValueForKey:(NSString *)key;

/**
 * Subclasses can override this method to get notified of changes.
 *
 * @note This method is only called for monitoredProperties.
 */
- (void)_didChangeValueForKey:(NSString *)key;

#pragma mark Exceptions

/**
 * Subclasses can use this method as a standard way of throwing immutable exceptions.
 */
- (NSException *)immutableException;

/**
 * Subclasses can use this method as a standard way of throwing immutable exceptions.
 */
- (NSException *)immutableExceptionForKey:(nullable NSString *)key;

#pragma mark Errors

/**
 * Subclasses can use this method as a standard way of generating common errors.
 */
- (NSError *)hasChangesError;

/**
 * Subclasses can use this method as a standard way of generating common errors.
 */
- (NSError *)malformedChangesetError;

/**
 * Subclasses can use this method as a standard way of generating common errors.
 */
- (NSError *)mismatchedChangeset;

/**
 * Subclasses can use this method as a standard way of generating common errors.
 */
- (NSError *)incorrectObjectClass;

@end

NS_ASSUME_NONNULL_END

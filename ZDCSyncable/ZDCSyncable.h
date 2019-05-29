/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * The ZDCSyncable protocol defines the common methods for:
 * - tracking changes
 * - performing undo & redo
 * - merging changes from external sources
 */
@protocol ZDCSyncable <NSObject>

/**
 * Returns whether or not there are any changes to the object.
 */
@property (nonatomic, readonly) BOOL hasChanges;

/**
 * Resets the hasChanges property to false, and clears all internal change tracking information.
 * Use this to wipe the slate, and restart change tracking from the current state.
 */
- (void)clearChangeTracking;

/**
 * Returns a changeset that contains information about changes that were made to the object.
 *
 * This changeset can then be used to undo the changes (via the `undo::` method).
 * If syncing the object to the cloud, this changeset may be needed to properly merge local & remote changes.
 *
 * The changeset will inclue all changes since the last time either
 * `changeset` or `[ZDCObject clearChangeTracking]` was called.
 *
 * @note
 *   This method is the equivalent of calling `peakChangeset`
 *   followed by `[ZDCObject clearChangeTracking]`.
 *
 * @note
 *   If you simply want to know if an object has changes, use the `[ZDCObject hasChanges]` property.
 *
 * @return
 *   A changeset dictionary, or nil if there are no changes.
 */
- (nullable NSDictionary *)changeset;

/**
 * Returns the current changeset without clearing the changes from the object.
 * This is primarily used for debugging.
 *
 * @note
 *   If you simply want to know if an object has changes, use the `[ZDCObject hasChanges]` property.
 *
 * @return
 *   A changeset dictionary, or nil if there are no changes.
 */
- (nullable NSDictionary *)peakChangeset;

/**
 * Moves the state of the object backwards in time, undoing the changes represented in the changeset.
 *
 * If an error occurs when attempting to undo the changes, then the undo attempt is aborted,
 * and the previous state of the object will be restored.
 *
 * @note
 *   This method is the equivalent of calling `performUndo:`
 *   followed by `changeset`, and returning that changeset.
 *
 * @param changeset
 *   A valid changeset previously returned via the `changeset` method.
 *
 * @param errPtr
 *   If an error occurs, the error can be returned via this parameter.
 *
 * @return
 *   A changeset dictionary if the undo was successful (which can be used to redo the changes).
 *   Otherwise returns nil, and sets the errPtr to an error object explaining what went wrong.
 */
- (nullable NSDictionary *)undo:(NSDictionary *)changeset error:(NSError *_Nullable *_Nullable)errPtr;

/**
 * Moves the state of the object backwards in time, undoing the changes represented in the changeset.
 *
 * If an error occurs when attempting to undo the changes, then the undo attempt is aborted,
 * and the previous state of the object will be restored.
 *
 * @param changeset
 *   A valid changeset previously returned via the `changeset` method.
 *
 * @return
 *   Returns nil on success, otherwise returns an error explaining what went wrong.
 */
- (nullable NSError *)performUndo:(NSDictionary *)changeset;

/**
 * Performs an undo for all changes that have occurred since the last time either
 * `changeset` or `[ZDCObject clearChangeTracking]` was called.
 */
- (void)rollback;

/**
 * This method is used to merge multiple changesets.
 *
 * You pass in an ordered list of changesets, and when the method completes:
 * - the state of the object is the same as it was before
 * - a changeset is returned which represents a consolidated version of the given list
 *
 * @note
 *   This method is the equivalent of calling `importChangesets:`
 *   followed by `changeset`, and returning that changeset.
 *
 * @param orderedChangesets
 *   An ordered list of changesets, with oldest at index 0.
 *
 * @param errPtr
 *   If an error occurs, the error can be returned via this parameter.
 *
 * @return
 *   On success, returns a changeset dictionary which represents a consolidated version of the given list.
 *   Otherwise returns nil, and sets the errPtr to an error object explaining what went wrong.
 */
- (nullable NSDictionary *)mergeChangesets:(NSArray<NSDictionary*> *)orderedChangesets
                                     error:(NSError *_Nullable *_Nullable)errPtr;

/**
 * This method is used to merge multiple changesets.
 *
 * You pass in an ordered list of changesets, and when the method completes:
 * - the state of the object is the same as it was before
 * - but calling `hasChanges` will now return YES
 * - and calling `changeset` will now return a merged changeset
 *
 * @param orderedChangesets
 *   An ordered list of changesets, with oldest at index 0.
 */
- (nullable NSError *)importChangesets:(NSArray<NSDictionary*> *)orderedChangesets;

/**
 * @return
 *   On success, returns a changeset dictionary that can be used to undo the changes.
 *   On failure, returns nil and sets the errPtr.
 */
- (nullable NSDictionary *)mergeCloudVersion:(id)cloudVersion
                       withPendingChangesets:(nullable NSArray<NSDictionary*> *)pendingChangesets
                                       error:(NSError *_Nullable *_Nullable)errPtr;

@end

NS_ASSUME_NONNULL_END

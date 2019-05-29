/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility methods for estimating the changes made to an array.
 */
@interface ZDCOrder : NSObject

/**
 * The ZDCSyncable protocol is focused on syncing changes with the cloud.
 * This gives us a focused set of constraints.
 * In particular, the cloud does NOT store an ordered list of every change that ever modified an object.
 * Instead it simply stores the current version of the object.
 *
 * This can be seen as a tradeoff. It minimizes cloud storage & bandwidth,
 * in exchange for losing a small degree of information concerning changes to an object.
 *
 * One difficulty we see with this tradeoff has to do with changes made to an ordered list.
 * For example, if a list is re-ordered, we don't know the exact items that were moved.
 * And it's not possible to calculate the information,
 * as multiple sets of changes could lead to the same end result.
 *
 * So our workaround is to estimate the changeset as best as possible.
 * This method performs that task using a simple deterministic algorithm
 * to arrive at a close-to-minimal changeset.
 *
 * @note The changeset is generally close-to-minimal, but not guaranteed to be the minimum.
 *       If you're a math genius, you're welcome to try your hand at solving this problem.
 */
+ (NSArray<id> *)estimateChangesetFrom:(NSArray<id> *)src
                                    to:(NSArray<id> *)dst
                                 hints:(nullable NSSet<id> *)hints;

@end

NS_ASSUME_NONNULL_END

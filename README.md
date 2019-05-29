# ZDCSyncable (objective-c version)

Undo, redo & merge capabilities for plain objects in Objective-C.

(There's a Swift version available [here](https://github.com/4th-ATechnologies/ZDCSyncable).)

By: [ZeroDark.cloud](https://www.zerodark.cloud): A secure sync & messaging framework for your app, built on blockchain & AWS.

&nbsp;

## Undo & Redo

Example #1

```objective-c
@interface FooBar: ZDCRecord // < Just extend ZDCRecord

// add your properties as usual
@property (nonatomic, copy, readwrite) NSString *someString; 
@property (nonatomic, readwrite) NSUInteger someInt;

@end // That's it !

// And now you get undo & redo support (for free!)

FooBar *foobar = [[FooBar alloc] init];
foobar.someString = @"init";
foobar.someInt = 1;
[foobar clearChangeTracking]; // starting point

foobar.someString = @"modified";
foobar.someInt = 2;

NSDictionary *changeset = [foobar changeset]; // changes since starting point

NSDictionary *redo = [foobar undo:changeset error:nil]; // revert to starting point

// Current state:
// foobar.someString == "init"
// foobar.someInt == 1

[foobar undo:redo error:nil]; // redo == (undo an undo)

// Current state:
// foobar.someString == "modified"
// foobar.someInt == 2
```

Complex objects are supported  via container classes:

- ZDCDictionary
- ZDCOrderedDictionary
- ZDCSet
- ZDCOrderedSet
- ZDCArray

Example #2

```objective-c
@interface FooBuzz: ZDCRecord // < Just extend ZDCRecord

// add your properties as usual
@property (nonatomic, readwrite) NSUInteger someInt;

// or use smart containers!
@property (nonatomic, readonly) ZDCDictionary *dict;

@end

FooBuzz *foobuzz = [[FooBuzz alloc] init];
foobuzz.someInt = 1;
foobuzz.dict[@"foo"] = @"buzz";
[foobuzz clearChangeTracking]; // starting point

foobuzz.someInt = 2;
foobuzz.dict[@"foo"] = @"modified";

NSDictionary *undo = [foobuzz changeset]; // changes since starting point

NSDictionary *redo = [foobuzz undo:undo error:nil]; // revert to starting point
  
// Current state:
// foobuzz.someInt == 1
// foobuzz.dict["foo"] == "buzz"

[foobuzz undo:redo error:nil]; // redo == (undo an undo)

// Current state:
// foobuzz.someInt == 2
// foobuzz.dict["foo"] == "modified"
```

&nbsp;

## Merge

You can also merge changes ! (i.e. from the cloud)

```objective-c
FooBuzz *local = [[FooBuzz alloc] init];
local.someInt = 1;
local.dict[@"foo"] = @"buzz";
[local clearChangeTracking]; // starting point

FooBuzz *cloud = [local copy];
NSMutableArray<NSDictionary*> *changesets = [NSMutableArray array];
	
// local modifications
	
local.someInt = 2;
local.dict[@"foo"] = @"modified";

[changesets addObject:[local changeset]];
// ^ pending local changes (not yet pushed to cloud)

// cloud modifications
			
cloud.dict[@"duck"]  = @"quack";
		
// Now merge cloud version into local.
// Automatically take into account our pending local changes.

[local mergeCloudVersion:cloud withPendingChangesets:changesets error:nil];
	
// Merged state:
// local.someInt == 2
// local.dict["foo"] == "modified"
// local.dict["duck"] == "quack"
```

&nbsp;

## Motivation

**Syncing data with the cloud requires the ability to properly merge changes. And properly merging changes requires knowing what's been changed.**

It's a topic that's often glossed over in tutorials, and so people tend to forget about it... until it's actually time to code. And then all hell breaks loose!

Syncing objects with the cloud means knowing how to merge changes from multiple devices. And this is harder than expected, because by default, this is the only information you have to perform the merge:

1. the current version of the object, as it appears in the cloud
2. the current version of the object, as it sits in your database

But something is missing. If property `someInt` is different between the two versions, that could mean:

- it was changed only by a remote device
- it was changed only by the local device
- it was changed by both devices

In order to properly perform the merge, you need to know the answer to this question.

What's missing is a list of changes that have been made to the LOCAL object. That is, changes that have been made, but haven't yet been pushed to the cloud. With that information, we can perform a proper merge. Because now we know:

1. the current version of the object, as it appears in the cloud
2. the current version of the object, as it sits in your database
3. a list of changes that have been made to the local object, including changed keys, and their original values

So if you want to merge changes properly, you're going to need to track this information. You can do it the hard way (manually), or the easy way (using some base class that provides the tracking for you automatically). Either way, you're not out of the woods yet!

It's somewhat trivial to track the changes to a simple record. That is, an object with just a few key/value pairs. And where all the values are primitive (numbers, booleans, strings). But what about when your app gets more advanced, and you need more complex objects?

What if one of your properties is an array? Or a dictionary? Or a set?

Truth be told, it's not THAT hard to code this stuff. It's not rocket science. But it does require **a TON of unit testing** to get all the little edge-cases correct. Which means you could spend all that time writing those unit tests yourself, or you could use an open-source version that's already been battle-tested by the community. (And then spend your extra time making your app awesome.)

&nbsp;

## Getting Started

ZDCSyncableObjcC is available via CocoaPods.

#### CocoaPods

Add the following to your Podfile:

```
pod 'ZDCSyncableObjC'
```

Then just run `pod install` as usual. And then you can import it via:

```objective-c
// using module-style imports:
@import ZDCSyncableObjC;

// or you can use classic-style imports:
#import <ZDCSyncableObjC/ZDCSyncableObjC.h>
```

&nbsp;

## Bonus Feature: Immutability

All ZDCObject subclasses can be made immutable. This includes all the container classes (such as ZDCDictionary), as well as any custom subclasses of ZDCRecord that you make.

```
myCustomSwiftObject.makeImmutable() // Boom! Cannot be modified now!
```

This is similar in concept to having separate NSDictionary/NSMutableDictionary classes. But this technique is even easier to use. 

(If you're wondering how this works: The change tracking already monitors the objects for changes. So once you mark an object as immutable, attempts to modify the object will throw an exception. If you want to make changes, you just copy the object, and then modify the copy.)


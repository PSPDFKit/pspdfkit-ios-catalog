//
//  Copyright © 2013-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <Foundation/Foundation.h>

// rdar://21290730
NS_ASSUME_NONNULL_BEGIN
@interface NSArray <ObjectType> (PSCArrayCreation)
+ (instancetype)arrayWithArray:(nullable NSArray<ObjectType> *)array;
@end

@interface NSDictionary <KeyType, ObjectType> (PSCDictionaryCreation)
+ (instancetype)dictionaryWithDictionary:(nullable NSDictionary<KeyType, ObjectType> *)dict;
@end

@interface NSSet <ObjectType> (PSCSetCreation)
- (instancetype)initWithSet:(nullable NSSet<ObjectType> *)set;
@end

@interface NSString (PSCStringCreation)
+ (instancetype)stringWithString:(nullable NSString *)string;
@end
NS_ASSUME_NONNULL_END

#define PSCCAssert(condition, description, ...) _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wnullable-to-nonnull-conversion\"") NSCAssert(condition, description, ##__VA_ARGS__) _Pragma("clang diagnostic pop")

#define PSC_NOT_DESIGNATED_INITIALIZER() PSC_NOT_DESIGNATED_INITIALIZER_CUSTOM(init)
#define PSC_NOT_DESIGNATED_INITIALIZER_WITH_STYLE() PSC_NOT_DESIGNATED_INITIALIZER_CUSTOM(initWithStyle : (UITableViewStyle)style)

#define PSC_NOT_DESIGNATED_INITIALIZER_CUSTOM(initName)                                                                                             \
    _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wobjc-designated-initializers\"") - (instancetype)initName {              \
        do {                                                                                                                                        \
            NSAssert2(NO, @"%@ is not the designated initializer for instances of %@.", NSStringFromSelector(_cmd), NSStringFromClass(self.class)); \
            return nil;                                                                                                                             \
        } while (0);                                                                                                                                \
    }                                                                                                                                               \
    _Pragma("clang diagnostic pop")

// Allow auto-boxing of common structs used in Foundation, CoreGraphics and UIKit.
// https://pspdfkit.com/blog/2017/even-swiftier-objective-c/
typedef struct __attribute__((objc_boxable)) CGPoint CGPoint;
typedef struct __attribute__((objc_boxable)) CGSize CGSize;
typedef struct __attribute__((objc_boxable)) CGRect CGRect;
typedef struct __attribute__((objc_boxable)) CGVector CGVector;
typedef struct __attribute__((objc_boxable)) CGAffineTransform CGAffineTransform;
typedef struct __attribute__((objc_boxable)) UIEdgeInsets UIEdgeInsets;
typedef struct __attribute__((objc_boxable)) _NSRange NSRange;


// Compiler-checked selectors and performance optimized at runtime.
#if DEBUG
#define PROPERTY(property) NSStringFromSelector(@selector(property))
#else
#define PROPERTY(property) @ #property
#endif

// Logging
#define kPSCLogEnabled
#ifdef kPSCLogEnabled
#define PSCLog(fmt, ...) NSLog((@"%s/%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define PSCLog(...)
#endif

// Availability Macros
#define PSCIsIPad() (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)

#define PSC_SWITCH_NOWARN(expression) _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wswitch-enum\"") switch (expression) _Pragma("clang diagnostic pop")

// This is because the deployment target is iOS 12 but Catalyst acts like the deployment target is iOS 13.
// This can be removed when the deployment target is increased to iOS 13.
#if TARGET_OS_MACCATALYST
#define PSC_CATALYST_DEPRECATED_NOWARN(expression) _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"") expression _Pragma("clang diagnostic pop")
#else
#define PSC_CATALYST_DEPRECATED_NOWARN(expression) expression
#endif

#define PSC_SILENCE_CALL_TO_UNKNOWN_SELECTOR(expression) _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") expression _Pragma("clang diagnostic pop")

#define PSCWeakifyAs(object, weakName) typeof(object) __weak weakName = object

#define PSCCast(object, className) ([object isKindOfClass:className.class] ? (className *)object : nil)

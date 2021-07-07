//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCExampleLookup.h"
#import "PSCExample.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns a list of classes encountered when walking the class hierarchy from subclass to superclass.
/// Returns `nil`, if subclass is not a subclass of superclass.
NS_INLINE  NSArray<Class> * _Nullable PSCClassHierarchy(Class subclass, Class superclass) {
    // Do not use -[NSObject isSubclassOfClass:] in order to avoid calling +initialize on all classes.
    for (Class class = class_getSuperclass(subclass); class != Nil; class = class_getSuperclass(class)) {
        if (class == superclass) {
            // We walk the hierarchy again instead of temporarily storing all encountered classes
            // to avoid triggering +initialize and potentially hitting threading checks on system classes.
            NSMutableArray<Class> *encounteredClasses = [NSMutableArray<Class> new];
            for (Class c = class_getSuperclass(subclass); c != superclass; c = class_getSuperclass(c)) {
                [encounteredClasses addObject:c];
            }
            return [encounteredClasses copy];
        }
    }
    return nil;
}

NSArray<Class> *PSCGetAllExampleSubclasses(void) {
    NSMutableArray<Class> *classes = [NSMutableArray<Class> new];
    NSMutableSet<Class> *intermediaryClasses = [NSMutableSet<Class> new];
    unsigned int count = 0;
    Class *classList = objc_copyClassList(&count);
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
    dispatch_apply(count, queue, ^(size_t idx) {
        __unsafe_unretained Class class = classList[idx];
        NSArray<Class> *encounteredClasses = PSCClassHierarchy(class, PSCExample.class);
        if (encounteredClasses != nil) {
            @synchronized(classes) {
                [classes addObject:class];
                [intermediaryClasses addObjectsFromArray:encounteredClasses];
            }
        }
    });
    // We're just interested in the leaf example classes, and not
    // in any intermediary subclasses in the subclass chain.
    [classes removeObjectsInArray:intermediaryClasses.allObjects];
    free(classList);
    return classes;
}

NS_ASSUME_NONNULL_END

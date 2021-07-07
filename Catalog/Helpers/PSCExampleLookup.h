//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <Foundation/Foundation.h>

@class PSCExample;

NS_ASSUME_NONNULL_BEGIN

/// Returns all leaf Example classes (without intermediary subclasses in the subclass chain).
///
/// @note This is an expensive call since it iterates over all runtime classes. Use sparingly and cache results.
NSArray<Class> *PSCGetAllExampleSubclasses(void);

NS_ASSUME_NONNULL_END

//
//  Copyright © 2012-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns all leaf Example classes (without intermediary subclasses in the subclass chain).
///
/// > Note: This is an expensive call since it iterates over all runtime classes. Use sparingly and cache results.
NSArray<Class> *PSCGetAllExampleSubclasses(void);

NS_ASSUME_NONNULL_END

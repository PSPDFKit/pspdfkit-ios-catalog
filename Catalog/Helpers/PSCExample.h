//
//  Copyright © 2012-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Allows you to customize the navigation controller to your heart’s content.
typedef void (^PSCExamplePresentationCustomizations)(UINavigationController *container);

NS_SWIFT_NAME(ExampleRunnerDelegate) NS_SWIFT_UI_ACTOR
@protocol PSCExampleRunnerDelegate <NSObject>

@property (nonatomic, readonly, nullable) UIViewController *currentViewController;

@end

typedef NS_ENUM(NSInteger, PSCExampleCategory) {
    PSCExampleCategoryIndustryExamples,
    PSCExampleCategoryTop,
    PSCExampleCategoryCollaboration,
    PSCExampleCategorySwiftUI,
    PSCExampleCategoryMultimedia,
    PSCExampleCategoryAnnotations,
    PSCExampleCategoryAnnotationProviders,
    PSCExampleCategoryForms,
    PSCExampleCategoryBarButtons,
    PSCExampleCategoryViewCustomization,
    PSCExampleCategoryControllerCustomization,
    PSCExampleCategoryMiscellaneous,
    PSCExampleCategoryTextExtraction,
    PSCExampleCategoryDocumentEditing,
    PSCExampleCategoryDocumentProcessing,
    PSCExampleCategoryDocumentGeneration,
    PSCExampleCategoryStoryboards,
    PSCExampleCategoryDocumentDataProvider,
    PSCExampleCategorySecurity,
    PSCExampleCategorySubclassing,
    PSCExampleCategorySharing,
    PSCExampleCategoryComponentsExamples,
    PSCExampleCategoryAnalyticsClient,
    PSCExampleCategoryTests
} NS_SWIFT_NAME(Example.Category);

typedef NS_OPTIONS(NSInteger, PSCExampleTargetDeviceMask) {
    PSCExampleTargetDeviceMaskPhone = 1 << 0,
    PSCExampleTargetDeviceMaskPad = 1 << 1,
    PSCExampleTargetDeviceMaskVision = 1 << 2
};

/// Base class for the catalog examples.
NS_SWIFT_NAME(Example) NS_SWIFT_UI_ACTOR
@interface PSCExample : NSObject

/// The example title. Mandatory. It is used as an identifier to match Swift and Objective-C examples.
@property (nonatomic, copy) NSString *title;

/// The example title with optional text attributes. Used for final display.
/// Defaults to `title` with no custom attributes.
@property (nonatomic, readonly) NSAttributedString *attributedTitle;

/// Defines a preview image for the cell.
@property (nonatomic, copy, nullable) UIImage *image;

/// The example description. Optional.
@property (nonatomic, copy, nullable) NSString *contentDescription;

/// The category for this example.
@property (nonatomic) PSCExampleCategory category;

/// Target device. Defaults to `[.pad, .phone]`.
@property (nonatomic) PSCExampleTargetDeviceMask targetDevice;

/// The priority of this example.
@property (nonatomic) NSInteger priority;

/// Presents the example modally when set. Defaults to `false`.
@property (nonatomic) BOOL wantsModalPresentation;

/// Sets up the navigation bar to have a large title. Defaults to `true`.
@property (nonatomic) BOOL prefersLargeTitles;

/// Will automatically wrap the controller in a `UINavigationController`.
/// Only relevant when `wantsModalPresentation` is set to `true`. Defaults to `true`.
@property (nonatomic) BOOL embedModalInNavigationController;

/// Allows you to set all kinds of presentation options and so forth.
@property (nullable, nonatomic, strong) PSCExamplePresentationCustomizations customizations;

/// Builds the sample and returns a new view controller that will then be pushed.
- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

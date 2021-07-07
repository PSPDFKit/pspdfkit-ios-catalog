//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import PSPDFKit
import PSPDFKitUI

private class PageViewController: UIPageViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // This is somewhat of a hack to work around the inflexible UIPageViewController
        // This will extend the content to include the page control indicator.
        for view in self.view.subviews {
            if view is UIScrollView {
                view.frame = self.view.frame
            } else if view is UIPageControl {
                self.view.bringSubviewToFront(view)
                view.backgroundColor = UIColor.clear
            }
        }
    }
}

class PageViewControllerExample: Example {

    var controller: [UIViewController] = []
    var pageViewController: UIPageViewController?
    var pageIndex: Int {
        didSet {
            updateTitle()
        }
    }

    override init() {
        pageIndex = 0
        super.init()
        title = "UIPageViewController Example"
        contentDescription = "Use UIPageViewController to cycle through PDFs"
        category = .viewCustomization
        priority = 11
        prefersLargeTitles = false
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // prepare list of documents you want to present
        let assetNames: [AssetName] = [.quickStart, .about, .web, .JKHF, .annualReport]
        let documents = assetNames.map { assetName in
            return AssetLoader.document(for: assetName)
        }
        // allocating many PDFViewController instances is memory intensive
        // if you have many documents, you should switch to a on-demand solution and re-use controllers.
        controller = documents.map { document in
            let pdfController = PDFViewController(document: document) {
                $0.pageTransition = .scrollContinuous
                $0.scrollDirection = .vertical
                $0.useParentNavigationBar = true
                $0.userInterfaceViewMode = .automaticNoFirstLastPage
                // the scrubber wouldn't work well when we expect horizontal movements to scroll content
                $0.thumbnailBarMode = .none
                // background is defined by the page view controller already
                $0.backgroundColor = UIColor.clear
            }
            pdfController.navigationItem.rightBarButtonItems = [pdfController.thumbnailsButtonItem, pdfController.outlineButtonItem, pdfController.searchButtonItem, pdfController.annotationButtonItem]
            return pdfController
        }

        // set up the page view controller
        let pageController = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: 10])
        pageController.dataSource = self
        pageController.delegate = self
        pageController.setViewControllers([controller[0]], direction: .forward, animated: false, completion: nil)
        pageController.view.backgroundColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        pageViewController = pageController
        pageIndex = 0

        // styling as we customize the page indicator to overlay
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: ([PageViewController.self]))
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.darkGray
        UserInterfaceView.appearance(whenContainedInInstancesOf: ([PageViewController.self])).pageLabelInsets = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)

        return pageController
    }

    func updateTitle() {
        // Title is set a bit later in PDFViewController initialization, so we use it from the
        // document directly. Aternatively, title could be KVO ovserved.
        guard let pdfController = controller[pageIndex] as? PDFViewController else { return }
        pageViewController?.title = pdfController.document?.title

        // Since we forward the navigationitem from the hosted view controller, we need to explicly update
        pdfController.updateToolbar(animated: false)
    }
}

extension PageViewControllerExample: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
            let currentVisibleController = pageViewController.viewControllers?.first,
            let index = controller.firstIndex(of: currentVisibleController) else { return }
        // update page index after it updated successfully
        pageIndex = index
    }
}

extension PageViewControllerExample: UIPageViewControllerDataSource {

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = controller.firstIndex(of: viewController), index > 0 else { return nil }
        return controller[index - 1]
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = controller.firstIndex(of: viewController), index + 1 < controller.count else { return nil }
        return controller[index + 1]
    }

    // The number of items reflected in the page indicator.
    public func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return controller.count
    }

    // The selected item reflected in the page indicator.
    public func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return pageIndex
    }
}

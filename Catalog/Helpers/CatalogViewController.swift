//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// A view controller that displays examples in a list.
///
/// This view controller will attempt to invoke the last opened example through
/// state restoration. To disable this behavior, launch the app with
/// `--skip-state-restoration` argument or set the "Reset on Next Launch" user
/// default to `true`.
open class CatalogViewController: BaseTableViewController {

    /// Show programming language indicators for examples as well as a preferred example language switch. Defaults to true.
    public var languageSelectionEnabled: Bool

    /// Determines if all sections should be shown in a single list. Defaults to false.
    public var shouldCombineSections: Bool

    /// Adds a Debug button in the navigation bar. Defaults to true.
    public var showDebugButton: Bool

    private var sections = [SectionDescriptor]()
    private var searchContent = [Content]()
    private var searchController: UISearchController?

    // MARK: - Lifecycle

    public init() {
        languageSelectionEnabled = true
        shouldCombineSections = false
        showDebugButton = true
        super.init(style: .insetGrouped)
        title = "Nutrient Catalog"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Catalog", style: .plain, target: nil, action: nil)
        self.addKeyCommand(UIKeyCommand(title: "Search", action: #selector(beginSearch(_:)), input: "f", modifierFlags: .command, discoverabilityTitle: "Search"))
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func restoreUserActivityState(_ activity: NSUserActivity) {
        guard activity.isOpenExampleActivity else { return }
        guard let indexPath = activity.indexPath else { return }

        if shouldSkipStateRestoration {
            UserDefaults.standard.removeObject(forKey: "psc_reset")
            return
        }

        if indexPath.section > 1 {
            let sectionHeaderIndexPath = IndexPath(row: 0, section: indexPath.section)
            tableView.selectRow(at: sectionHeaderIndexPath, animated: false, scrollPosition: .middle)
            tableView(tableView, didSelectRowAt: sectionHeaderIndexPath)
        }

        // Restore session but fail gracefully
        if tableView.numberOfSections > indexPath.section, tableView.numberOfRows(inSection: indexPath.section) > indexPath.row {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            tableView(tableView, didSelectRowAt: indexPath)
        }
    }

    // MARK: - Content Creation

    func createTableContent() {
        var sectionDescriptors: [SectionDescriptor] = []

        // Add examples and map categories to sections.
        var currentCategory: Example.Category?
        var currentSection: SectionDescriptor?
        for example in Examples.all {
            if currentCategory != example.category {
                if let lastSection = currentSection, !lastSection.contentDescriptors.isEmpty {
                    sectionDescriptors.append(lastSection)
                }

                let category = example.category
                var section = SectionDescriptor(title: Example.headerForExampleCategory(category), footer: Example.footerForExampleCategory(category))

                // Add the main header to the first section.
                if currentCategory == nil {
                    section.headerView = CatalogHeaderView()
                }

                if category == .industryExamples || category == .top {
                    section.isCollapsed = false
                }

                if category != .industryExamples {
                    section.add(content: Content(title: NSAttributedString(string: Example.headerForExampleCategory(category)), category: category))
                }

                currentCategory = category
                currentSection = section
            }

            let exampleContent = Content(title: example.attributedTitle, image: example.image, description: example.contentDescription)
            exampleContent.example = example
            currentSection?.add(content: exampleContent)
        }

        if let currentSection, currentSection.contentDescriptors.isEmpty == false {
            sectionDescriptors.append(currentSection)
        }

        if shouldCombineSections {
            let combinedContent = sectionDescriptors
                .flatMap { $0.contentDescriptors }
                .filter { !$0.isSectionHeader }
            var combinedSection = sectionDescriptors[0]
            combinedSection.contentDescriptors = combinedContent
            sections = [combinedSection]
        } else {
            sections = sectionDescriptors
        }
    }

    // MARK: - UIViewController

    open override func viewDidLoad() {
        super.viewDidLoad()

        if showDebugButton {
            addDebugButton()
        }

        createTableContent()

        func configureTableView(_ tableView: UITableView) {
            let isRootTableView = tableView == self.tableView
            tableView.delegate = self
            tableView.dataSource = self
            // We're not using headers for the search table view
            tableView.estimatedSectionHeaderHeight = isRootTableView ? 30 : 0

            tableView.cellLayoutMarginsFollowReadableWidth = true

            tableView.register(CatalogCell.self, forCellReuseIdentifier: String(describing: CatalogCell.self))
        }

        navigationItem.largeTitleDisplayMode = .always

        let tableView = self.tableView!
        configureTableView(tableView)
        // Make sure that we can preserve the selection in state restoration
        tableView.restorationIdentifier = "Samples Table"

        // Present the search display controller on this view controller
        definesPresentationContext = true

        let resultsController = UITableViewController(style: .plain)
        configureTableView(resultsController.tableView)

        let searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = self
        self.searchController = searchController

        // Enables workarounds for rdar://352525 and rdar://32630657.
        searchController.pspdf_installWorkarounds(on: self)
        navigationItem.searchController = searchController
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let tableView = self.tableView
        let tableViewIndexPath = tableView?.indexPathForSelectedRow
        if let tableViewIndexPath {
            tableView?.deselectRow(at: tableViewIndexPath, animated: true)
        }

        navigationController?.setToolbarHidden(true, animated: animated)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        clearUserActivity()
    }

    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Open Examples

    func open(_ example: Example, at indexPath: IndexPath?, in tableView: UITableView) {
        guard let controller = example.invoke(with: self) else {
            // No controller returned, maybe the example just presented an alert controller.
            if let indexPath {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            return
        }

        if example.wantsModalPresentation {
            var navController: UINavigationController?
            if controller is UINavigationController {
                navController = controller as? UINavigationController
            } else {
                if example.embedModalInNavigationController {
                    let navigationController = PDFNavigationController(rootViewController: controller)
                    example.customizations?(navigationController)
                    navController = navigationController
                }

                let sourceView: UIView
                if let indexPath {
                    sourceView = tableView.cellForRow(at: indexPath) ?? tableView
                } else {
                    sourceView = tableView
                }
                navController?.popoverPresentationController?.sourceView = sourceView
            }
            navController?.presentationController?.delegate = self
            navController?.navigationBar.prefersLargeTitles = example.prefersLargeTitles
            let controllerToPresent = navController ?? controller
            present(controllerToPresent, animated: true)

            if let indexPath {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        } else {
            let controllerToPresent = (controller as? UINavigationController)?.topViewController ?? controller
            navigationController?.presentationController?.delegate = self
            navigationController?.navigationBar.prefersLargeTitles = example.prefersLargeTitles
            navigationController?.pushViewController(controllerToPresent, animated: true)
        }
    }

    // MARK: - Key Commands

    @IBAction func beginSearch(_ sender: Any) {
        searchController?.searchBar.becomeFirstResponder()
    }

    // MARK: - Private

    func isValidIndexPath(_ indexPath: IndexPath, forContent content: [SectionDescriptor]) -> Bool {
        let numberOfSections = content.count
        if indexPath.section < numberOfSections {
            let numberOfRowsInSection = content[indexPath.section].contentDescriptors.count
            if indexPath.row < numberOfRowsInSection {
                return true
            }
        }
        return false
    }

    func contentDescriptor(for indexPath: IndexPath, tableView: UITableView) -> Content {
        // Get correct content descriptor
        let contentDescriptor: Content
        if tableView == self.tableView {
            assert(isValidIndexPath(indexPath, forContent: sections), "Index path must be valid")
            contentDescriptor = sections[indexPath.section].contentDescriptors[indexPath.row]
        } else {
            assert(indexPath.row >= 0 && indexPath.row < searchContent.count, "Index path must be valid")
            contentDescriptor = searchContent[indexPath.row]
        }
        return contentDescriptor
    }

    func clearUserActivity() {
        view.window?.windowScene?.userActivity = nil
        view.window?.windowScene?.title = "Nutrient Catalog"
        view.window?.windowScene?.session.stateRestorationActivity = nil
    }

    private var shouldSkipStateRestoration: Bool {
        let launchArgument = ProcessInfo.processInfo.arguments.contains("--skip-state-restoration")
        let userDefault = UserDefaults.standard.bool(forKey: "psc_reset")
        return launchArgument || userDefault
    }

    // MARK: - UITableViewDataSource

    open override func numberOfSections(in tableView: UITableView) -> Int {
        tableView == self.tableView ? sections.count : 1
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == self.tableView ? (sections[section].isCollapsed ? 1 : sections[section].contentDescriptors.count) : searchContent.count
    }

    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableView == self.tableView ? sections[section].headerView : nil
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CatalogCell.self)) as! CatalogCell
        let contentDescriptor = self.contentDescriptor(for: indexPath, tableView: tableView)

        if contentDescriptor.isSectionHeader {
            let collapsed = self.sections[indexPath.section].isCollapsed
            cell.setupSectionHeader(with: contentDescriptor, collapsed: collapsed)
        } else {
            cell.setup(with: contentDescriptor)
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contentDescriptor = self.contentDescriptor(for: indexPath, tableView: tableView)

        let example = contentDescriptor.example

        var unfilteredIndexPath: IndexPath?
        if tableView == self.tableView {
            // Expand/collapse section
            if indexPath.section > 0 && indexPath.row == 0 {
                sections[indexPath.section].isCollapsed.toggle()
                tableView.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
                return
            }
            unfilteredIndexPath = indexPath
        } else {
            // Find original index path so we can persist.
            for (sectionIndex, section) in sections.enumerated() {
                for (contentIndex, sectionContentDescriptor) in section.contentDescriptors.enumerated() where sectionContentDescriptor == contentDescriptor {
                    unfilteredIndexPath = IndexPath(row: contentIndex, section: sectionIndex)
                    break
                }
            }
        }

        let activity = NSUserActivity.openExampleActivity(at: unfilteredIndexPath!)
        view.window?.windowScene?.userActivity = activity
        view.window?.windowScene?.title = example?.title
        view.window?.windowScene?.session.stateRestorationActivity = activity

        if let example {
            open(example, at: indexPath, in: tableView)
        }
    }

    // MARK: - Debug Helper

    func addDebugButton() {
        let debugButton = UIBarButtonItem(title: "Debug", style: .plain, target: self, action: #selector(didTapDebugButtonItem(_:)))
        navigationItem.rightBarButtonItem = debugButton
    }

    @objc func didTapDebugButtonItem(_ sender: UIBarButtonItem) {
        let memoryAction = UIAlertAction(title: "Raise Memory Warning", style: .default) { _ in
            self.debugCreateLowMemoryWarning()
        }

        let cacheAction = UIAlertAction(title: "Clear Cache", style: .default) { _ in
            self.debugClearCache()
        }

        let instantAction = UIAlertAction(title: "Clear Instant Cache", style: .default) { _ in
            self.debugClearInstantCache()
        }

        let debugSheet = UIAlertController(title: "Debug Menu", message: nil, preferredStyle: .actionSheet)
        debugSheet.addAction(memoryAction)
        debugSheet.addAction(cacheAction)
        debugSheet.addAction(instantAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        debugSheet.addAction(cancelAction)

        debugSheet.popoverPresentationController?.barButtonItem = sender
        present(debugSheet, animated: true)
    }

    // Only for debugging - this will get you rejected on the App Store!
    func debugCreateLowMemoryWarning() {
        UIApplication.shared.perform(NSSelectorFromString("_\("performMemory")Warning"))
    }

    func debugClearCache() {
        SDK.shared.renderManager.renderQueue.cancelAllTasks()
        SDK.shared.cache.clear()
    }

    func debugClearInstantCache() {
        UserDefaults.standard.removeObject(forKey: InstantExampleLastViewedDocumentInfoKey)
        UserDefaults.standard.removeObject(forKey: MultiUserInstantExampleLastViewedDocumentInfoKey)
        do {
            try InstantDocumentManager.shared.clearAllLocalStorage()
        } catch {
            showAlert(withTitle: "Failed to Clear Instant Cache", message: error.localizedDescription)
        }
    }
}

extension CatalogViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContent(forSearchText: searchBar.text ?? "")
    }

    func filterContent(forSearchText searchText: String) {
        lazy var predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Content.title.string), searchText),
                NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Content.exampleClassForSearch), searchText)
            ]),
            NSPredicate(format: "%K = NO", #keyPath(Content.isSectionHeader))
        ])

        searchContent = searchText.isEmpty ? [] : sections.flatMap { $0.contentDescriptors.filtered(using: predicate) }

        (searchController?.searchResultsController as? UITableViewController)?.tableView.reloadData()
    }
}

extension CatalogViewController: UIAdaptivePresentationControllerDelegate {
    // This is called when dismissing non-fullscreen presentations.
    // Presentations that don't cover the full screen, don't call the underlying controllers
    // viewDidDisappear and viewDidAppear on dismissal.
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        clearUserActivity()
    }
}

extension CatalogViewController: ExampleRunnerDelegate {
    public var currentViewController: UIViewController? {
        return self
    }
}

private extension Content {
    /// Returns a stringified `example` class name that can be used in the search
    @objc var exampleClassForSearch: String? {
        guard let example else { return nil }
        return String(describing: type(of: example))
    }
}

private extension Array {
    /// Represents a wrapper around the `NSArray.filtered(using:)` method
    func filtered(using predicate: NSPredicate) -> [Element] {
        let array = self as NSArray
        return array.filtered(using: predicate) as? [Element] ?? []
    }
}

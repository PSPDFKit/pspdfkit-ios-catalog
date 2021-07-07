//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// Controller that displays examples in a list.
open class CatalogViewController: BaseTableViewController {

    /// Show programming language indicators for examples as well as a preferred example language switch. Defaults to true.
    public var languageSelectionEnabled: Bool

    /// Determines if all sections should be shown in a single list. Defaults to false.
    public var shouldCombineSections: Bool

    /// Adds a Debug button in the navigation bar. Defaults to true.
    public var showDebugButton: Bool

    /// A reference to the key window used for appearance styling.
    weak var window: UIWindow? {
        didSet {
            applyCatalogAppearance()
        }
    }

    private var sections = [SectionDescriptor]()

    private var preferredExampleLanguage: ExampleLanguage {
        didSet {
            UserDefaults.standard.set(preferredExampleLanguage.rawValue, forKey: String(describing: ExampleLanguage.self))
            if isViewLoaded {
                createTableContent()
                tableView.reloadData()
            }
        }
    }

    private var searchContent = [Content]()
    private var searchController: UISearchController?
    private var clearCacheNeeded = false

    // MARK: - Lifecycle

    public override init(style: UITableView.Style) {
        preferredExampleLanguage = .swift
        languageSelectionEnabled = true
        shouldCombineSections = false
        showDebugButton = true
        super.init(style: style)
        title = "PSPDFKit Catalog"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Catalog", style: .plain, target: nil, action: nil)

        restorePreferredExampleLanguage()
        self.addKeyCommand(UIKeyCommand(title: "Search", action: #selector(beginSearch(_:)), input: "f", modifierFlags: .command, discoverabilityTitle: "Search"))
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func restoreUserActivityState(_ activity: NSUserActivity) {
        guard activity.isOpenExampleActivity else { return }
        preferredExampleLanguage = activity.preferredExampleLanguage
        guard let indexPath = activity.indexPath else { return }

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
        let examples = ExampleManager.default.examples(forPreferredLanguage: preferredExampleLanguage)

        // Add examples and map categories to sections.
        var currentCategory: Example.Category?
        var currentSection: SectionDescriptor?
        for example in examples {
            if currentCategory != example.category {
                if let lastSection = currentSection, !lastSection.contentDescriptors.isEmpty {
                    sectionDescriptors.append(lastSection)
                }

                let category = example.category
                var section = SectionDescriptor(title: Example.headerForExampleCategory(category), footer: Example.footerForExampleCategory(category))

                // Add the main header to the first section.
                if currentCategory == nil {
                    section.headerView = CatalogHeaderView(selectedLanguage: languageSelectionEnabled ? preferredExampleLanguage : nil) { selectedLanguage in
                        self.preferredExampleLanguage = selectedLanguage
                    }
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

        if let currentSection = currentSection, currentSection.contentDescriptors.isEmpty == false {
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
        if ProcessInfo.processInfo.arguments.contains("--clear-all-caches") {
            clearCacheNeeded = true
        }

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
        if let tableViewIndexPath = tableViewIndexPath {
            tableView?.deselectRow(at: tableViewIndexPath, animated: true)
        }

        navigationController?.setToolbarHidden(true, animated: animated)

        // clear cache (for night mode)
        if clearCacheNeeded {
            clearCacheNeeded = false
            SDK.shared.cache.clear()
        }
    }

    // Restore last selected example if appropriate with support for reset from settings:
    static let viewDidAppearPSCResetKey = "psc_reset"

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let defaults = UserDefaults.standard
        if defaults.bool(forKey: CatalogViewController.viewDidAppearPSCResetKey) || shouldReset(forArguments: ProcessInfo.processInfo.arguments) {
            // the launch argument SHOULD override the user defaults, however it does not when launched through an XCUIApplication launch.
            defaults.removeObject(forKey: CatalogViewController.viewDidAppearPSCResetKey)
        }

        clearWindowScene()
    }

    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Open Examples

    /// Open a specific example with a given example type from the Catalog.
    /// Returns true if opening the example succeeded, false otherwise.
    func openExample(withType exampleType: String) -> Bool {
        let examples = ExampleManager.default.allExamples
        for example in examples where example.type == exampleType {
            open(example, at: nil, in: tableView)
            return true
        }
        return false
    }

    func open(_ example: Example, at indexPath: IndexPath?, in tableView: UITableView) {
        guard let controller = example.invoke(with: self) else {
            // No controller returned, maybe the example just presented an alert controller.
            if let indexPath = indexPath {
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
                if let indexPath = indexPath {
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

            if let indexPath = indexPath {
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

    func restorePreferredExampleLanguage() {
        let storedExampleLanguage = UserDefaults.standard.integer(forKey: String(describing: ExampleLanguage.self))
        if let exampleLanguage = ExampleLanguage(rawValue: UInt(storedExampleLanguage)) {
            preferredExampleLanguage = exampleLanguage
        }
    }

    func clearWindowScene() {
        let windowScene = window?.windowScene
        windowScene?.userActivity = nil
        windowScene?.title = "PSPDFKit Catalog"
        windowScene?.session.stateRestorationActivity = nil
    }

    func shouldReset(forArguments processArguments: [String]) -> Bool {
        let optionalResetParameter = processArguments.firstIndex { argument in
            return argument.hasSuffix("psc_reset")
        }

        guard let resetParameter = optionalResetParameter, resetParameter != NSNotFound else {
            return false
        }

        // Assume we should reset if no argument is given to the parameter
        if resetParameter == processArguments.count - 1 {
            return true
        }

        // Otherwise, use the bool value of the succeeding argument
        return (processArguments[resetParameter + 1] as NSString).boolValue
    }

    // MARK: - Appearance

    func applyCatalogAppearance() {
        let catalogTintColor = UIColor.catalogTint

        // Global (the window reference should be set by the application delegate early in the app lifecycle)
        window?.tintColor = catalogTintColor

        // The accessory view lives on the keyboard window, so it doesn't auto inherit the window tint color
        FreeTextAccessoryView.appearance().tintColor = catalogTintColor
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
            cell.setup(with: contentDescriptor, showLanguageBadge: languageSelectionEnabled)
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

        let activity = NSUserActivity.openExampleActivity(withPreferredExampleLanguage: preferredExampleLanguage, indexPath: unfilteredIndexPath!)
        let windowScene = window?.windowScene
        windowScene?.userActivity = activity
        windowScene?.title = example?.title
        windowScene?.session.stateRestorationActivity = activity

        if let example = example {
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
        // Clear any reference of items that would retain controllers/pages.
        UIMenuController.shared.menuItems = nil
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
        var filteredContent: [Content] = []

        if searchText.isEmpty == false {
            let predicate = NSPredicate(format: "%K CONTAINS[cd] %@ AND self.isSectionHeader = NO", #keyPath(Content.title.string), searchText)
            for section in sections {
                if let filtered = (section.contentDescriptors as NSArray?)?.filtered(using: predicate) as? [Content] {
                    filteredContent.append(contentsOf: filtered)
                }
            }
        }
        searchContent = filteredContent

        (searchController?.searchResultsController as? UITableViewController)?.tableView.reloadData()
    }
}

extension CatalogViewController: UIAdaptivePresentationControllerDelegate {
    // This is called when dismissing non-fullscreen presentations.
    // On iOS 13, presentations that don't cover the full screen, don't call the underlying controllers
    // viewDidDisappear and viewDidAppear on dismissal.
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        clearWindowScene()
    }
}

extension CatalogViewController: ExampleRunnerDelegate {
    public var currentViewController: UIViewController? {
        return self
    }
}

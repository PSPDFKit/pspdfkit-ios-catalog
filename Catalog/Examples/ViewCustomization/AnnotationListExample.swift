//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

class AnnotationListExample: Example {
    override init() {
        super.init()
        title = "Customizing the Annotation List"
        contentDescription = "Customize the annotation cell in AnnotationTableViewController."
        category = .viewCustomization
        priority = 70
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let guide = AssetLoader.document(for: .quickStart)
        let controller = PDFViewController(document: guide) { builder in
            builder.overrideClass(AnnotationCell.self, with: CustomAnnotationCell.self)
            builder.overrideClass(AnnotationTableViewController.self, with: AnnotationListController.self)
        }
        controller.documentInfoCoordinator.availableControllerOptions = [.annotations]

        // Simulate tapping on the outline button.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            controller.documentInfoCoordinator.present(
                to: controller,
                options: nil,
                sender: controller.outlineButtonItem,
                animated: true,
                completion: nil
            )
        }

        return controller
    }
}

private class CustomAnnotationCell: AnnotationCell {
    var isShared: Bool {
        didSet {
            sharingStateLabel.text = isShared ? "Shared" : "Not Shared"
            // Ensure the size and placement are up to date
            sharingStateLabel.sizeToFit()
            setNeedsLayout()
        }
    }

    // Note: This isn’t the greatest UI. A smaller sharing indicator would be nicer.
    private var sharingStateLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        isShared = false
        sharingStateLabel = UILabel()
        sharingStateLabel.textColor = .psc_secondaryLabel

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView = sharingStateLabel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented and isn’t needed")
    }
}

private class AnnotationListController: AnnotationTableViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let anyCell = super.tableView(tableView, cellForRowAt: indexPath)
        guard let cell = anyCell as? CustomAnnotationCell else {
            return anyCell
        }

        // Our superclass sets the annotation on the cell, so we know we may force unwrap.
        let annotation = cell.annotation!
        cell.isShared = sharedState(for: annotation)

        return cell
    }

    private var sharedStateByAnnotationID: [String: Bool] = [:]
    private func sharedState(for annotation: Annotation) -> Bool {
        sharedStateByAnnotationID[annotation.id] ?? false
    }

    private func toggleSharedState(for annotation: Annotation) -> Bool {
        let desiredState = !sharedState(for: annotation)
        sharedStateByAnnotationID[annotation.id] = desiredState

        return desiredState
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) as? CustomAnnotationCell else {
            return super.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: indexPath)
        }

        let action = UIContextualAction(
            style: .normal,
            title: cell.isShared ? "Unshare" : "Share"
        ) { [weak cell, weak self] _, _, completion in
            guard let cell = cell, let self = self else {
                return completion(false)
            }
            cell.isShared = self.sharedState(for: cell.annotation!)

            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [action])
    }
}

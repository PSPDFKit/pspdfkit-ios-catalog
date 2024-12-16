//
//  Copyright © 2022-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

extension UIMenu {

    /// A result of filtering a menu inside a menu.
    private enum MenuPredicateResult {

        /// Keep the menu in its entirety, don't filter its children.
        case keep

        /// Reject the menu in its entirety, don't filter its children.
        case reject

        /// Proceed to filter the menu's children.
        case filter

    }

    /// Filter the children of this menu recursively.
    private func filter(menus menuPredicate: (UIMenu.Identifier) -> MenuPredicateResult, actions actionPredicate: (UIAction.Identifier) -> Bool) -> UIMenu {
        replacingChildren(children.compactMap { element in
            if let menu = element as? UIMenu {
                switch menuPredicate(menu.identifier) {
                case .keep: return menu
                case .reject: return nil
                case .filter: return menu.filter(menus: menuPredicate, actions: actionPredicate)
                }
            } else if let action = element as? UIAction {
                switch actionPredicate(action.identifier) {
                case true: return action
                case false: return nil
                }
            } else {
                return nil
            }
        })
    }

    /// Filter the children of this menu by keeping menus in their entirety if
    /// their identifiers are in the given `menus` set, and actions if their
    /// identifiers are in the given `actions` set.
    func keep(menus: Set<UIMenu.Identifier> = [], actions: Set<UIAction.Identifier>) -> UIMenu {
        filter(menus: { menus.contains($0) ? .keep : .filter }, actions: { actions.contains($0) })
    }

    /// Filter the children of this menu by removing menus in their entirety if
    /// their identifiers are in the given `menus` set, and actions if their
    /// identifiers are in the given `actions` set.
    func reject(menus: Set<UIMenu.Identifier> = [], actions: Set<UIAction.Identifier>) -> UIMenu {
        filter(menus: { menus.contains($0) ? .reject : .filter }, actions: { !actions.contains($0) })
    }

    /// Find and replace the action with the given identifier in this menu with
    /// a different menu element.
    func replace(action id: UIAction.Identifier, with replacement: UIMenuElement) -> UIMenu {
        replacingChildren(children.compactMap { element in
            if let menu = element as? UIMenu {
                return menu.replace(action: id, with: replacement)
            } else if let action = element as? UIAction, action.identifier == id {
                return replacement
            } else {
                return element
            }
        })
    }

    /// Insert the given menu elements at the beginning of this menu.
    func prepend<Elements>(_ elements: Elements) -> UIMenu where Elements: Sequence, Elements.Element == UIMenuElement {
        replacingChildren(Array(elements) + children)
    }

}

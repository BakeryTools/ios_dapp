// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit

/// Useful because there's some boilerplate code to create a wrapper class around a target class (such as a button or image view) which has a rounded corner + shadow. Rounded corners (and has clipped views) + shadows requires a wrapper parent class
class ContainerViewWithShadow<T: UIView>: UIView {
    let childView: T

    init(aroundView childView: T) {
        self.childView = childView
        super.init(frame: .zero)

        childView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(childView)

        NSLayoutConstraint.activate([
            childView.anchorsConstraint(to: self),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowPath()
    }

    private func updateShadowPath() {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }

    func configureShadow(color: UIColor, offset: CGSize, opacity: Float, radius: CGFloat, cornerRadius: CGFloat) {
        layer.cornerRadius = cornerRadius
        childView.cornerRadius = cornerRadius

        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        updateShadowPath()
    }
}

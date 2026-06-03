//
//  HoverButtonStyle.swift
//  TimeViewer
//
//  Flat button with a subtle rounded highlight on hover and press — the
//  standard affordance for clickable controls inside a popover.
//

import SwiftUI

struct HoverButtonStyle: ButtonStyle {
    var padding = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    var cornerRadius: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        HoverButton(configuration: configuration, padding: padding, cornerRadius: cornerRadius)
    }

    private struct HoverButton: View {
        let configuration: ButtonStyleConfiguration
        let padding: EdgeInsets
        let cornerRadius: CGFloat

        @Environment(\.isEnabled) private var isEnabled
        @State private var isHovering = false

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            configuration.label
                .padding(padding)
                .background(shape.fill(Color.primary.opacity(highlight)))
                .contentShape(shape)
                .opacity(isEnabled ? 1 : 0.4)
                .onHover { isHovering = isEnabled && $0 }
        }

        private var highlight: Double {
            if configuration.isPressed { return 0.16 }
            if isHovering { return 0.09 }
            return 0
        }
    }
}

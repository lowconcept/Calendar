//
//  TimelineScrollView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 18.01.26.
//

import SwiftUI
import UIKit

final class TimelineScrollController {  // ✅ KEIN ObservableObject nötig
    private(set) weak var scrollView: UIScrollView?

    func attach(_ sv: UIScrollView) {
        self.scrollView = sv
    }

    func setUserScrollEnabled(_ enabled: Bool) {
        scrollView?.isScrollEnabled = enabled
    }

    func scrollTo(y: CGFloat, animated: Bool) {
        guard let sv = scrollView else { return }
        let maxY = max(0, sv.contentSize.height - sv.bounds.height + sv.adjustedContentInset.bottom)
        let clamped = min(max(y, -sv.adjustedContentInset.top), maxY)
        sv.setContentOffset(CGPoint(x: 0, y: clamped), animated: animated)
    }

    func scrollBy(dy: CGFloat) {
        guard let sv = scrollView else { return }
        scrollTo(y: sv.contentOffset.y + dy, animated: false)
    }
}

struct TimelineScrollView<Content: View>: UIViewRepresentable {

    let controller: TimelineScrollController
    @Binding var offsetY: CGFloat
    let contentHeight: CGFloat
    let content: () -> Content

    init(
        controller: TimelineScrollController,
        offsetY: Binding<CGFloat>,
        contentHeight: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.controller = controller
        self._offsetY = offsetY
        self.contentHeight = contentHeight
        self.content = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = .clear
        sv.delegate = context.coordinator

        // ✅ Gesture-Konfiguration für saubere Interaktion
        sv.delaysContentTouches = true
        sv.canCancelContentTouches = true
        sv.panGestureRecognizer.cancelsTouchesInView = false

        let host = UIHostingController(rootView: content())
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.isUserInteractionEnabled = true

        sv.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: sv.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: sv.contentLayoutGuide.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: sv.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: sv.contentLayoutGuide.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: sv.frameLayoutGuide.widthAnchor),
            host.view.heightAnchor.constraint(equalToConstant: contentHeight)
        ])

        context.coordinator.hostingController = host
        controller.attach(sv)
        return sv
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content()
        controller.attach(uiView)

        // Offset nur synchronisieren wenn User NICHT scrollt
        guard !uiView.isTracking,
              !uiView.isDragging,
              !uiView.isDecelerating else { return }

        if abs(uiView.contentOffset.y - offsetY) > 1 {
            uiView.contentOffset.y = offsetY
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: TimelineScrollView
        weak var hostingController: UIHostingController<Content>?

        init(_ parent: TimelineScrollView) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.offsetY = scrollView.contentOffset.y
        }
    }
}

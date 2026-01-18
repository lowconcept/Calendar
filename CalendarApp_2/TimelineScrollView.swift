//
//  TimelineScrollView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI
import UIKit
import Combine

final class TimelineScrollController: ObservableObject {
    fileprivate weak var scrollView: UIScrollView?
    private var displayLink: CADisplayLink?
    private var autoScrollDirection: CGFloat = 0

    func attach(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }

    func scrollTo(y: CGFloat, animated: Bool) {
        guard let scrollView else { return }
        let maxOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        let clamped = min(max(y, 0), maxOffset)
        scrollView.setContentOffset(CGPoint(x: 0, y: clamped), animated: animated)
    }

    func startAutoScroll(direction: CGFloat) {
        autoScrollDirection = direction
        if displayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(step))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
    }

    var visibleHeight: CGFloat {
        scrollView?.bounds.height ?? 0
    }

    func stopAutoScroll() {
        displayLink?.invalidate()
        displayLink = nil
        autoScrollDirection = 0
    }

    @objc private func step() {
        guard let scrollView else { return }
        let delta = autoScrollDirection * 4
        let maxOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        let newOffset = min(max(scrollView.contentOffset.y + delta, 0), maxOffset)
        scrollView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
    }

    deinit {
        stopAutoScroll()
    }
}

struct TimelineScrollView<Content: View>: UIViewRepresentable {
    @ObservedObject var controller: TimelineScrollController
    var isScrollEnabled: Bool
    var showsIndicators: Bool
    let content: Content

    init(
        controller: TimelineScrollController,
        isScrollEnabled: Bool,
        showsIndicators: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.controller = controller
        self.isScrollEnabled = isScrollEnabled
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = showsIndicators
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear

        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hosting.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        context.coordinator.hostingController = hosting
        controller.attach(scrollView: scrollView)
        scrollView.isScrollEnabled = isScrollEnabled
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        uiView.isScrollEnabled = isScrollEnabled
        context.coordinator.hostingController?.rootView = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var hostingController: UIHostingController<Content>?
    }
}

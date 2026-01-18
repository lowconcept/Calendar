//
//  EventBlock.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct EventBlock: View {

    enum DragMode { case move, resizeTop, resizeBottom }

    let title: String
    let timeText: String
    let color: Color
    let isSelected: Bool

    let onSelect: () -> Void
    let onOpenEditor: () -> Void

    // mode, deltaY, fingerGlobalY
    let onBeginInteraction: (DragMode) -> Void
    let onChangeInteraction: (DragMode, CGFloat, CGFloat) -> Void
    let onEndInteraction: (DragMode) -> Void

    @State private var lock: DragMode? = nil
    @State private var suppressNextTap = false
    @State private var longPressMoveArmed = false

    var body: some View {
        GeometryReader { proxy in
            let h = proxy.size.height

            let showTime = h >= 34
            let titleSize: CGFloat = h < 34 ? 12 : 14
            let timeSize: CGFloat = h < 44 ? 10 : 12
            let vPad: CGFloat = h < 34 ? 6 : 10

            ZStack(alignment: .leading) {

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(isSelected ? 0.16 : 0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(isSelected ? 0.26 : 0.14), lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(color)
                    .frame(width: 4)
                    .padding(.leading, 8)

                VStack(alignment: .leading, spacing: showTime ? 3 : 1) {
                    Text(title.isEmpty ? "Untitled" : title)
                        .font(.system(size: titleSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(showTime ? 2 : 1)
                        .minimumScaleFactor(0.85)

                    if showTime {
                        Text(timeText)
                            .font(.system(size: timeSize, weight: .medium))
                            .foregroundStyle(.white.opacity(0.60))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .padding(.leading, 18)
                .padding(.trailing, 10)
                .padding(.vertical, vPad)

                if isSelected {
                    VStack(spacing: 0) {
                        handle(mode: .resizeTop)
                            .padding(.top, 2)

                        Spacer(minLength: 0)

                        handle(mode: .resizeBottom)
                            .padding(.bottom, 2)
                    }
                    .padding(.horizontal, 8)
                    .zIndex(50)
                    .transition(.opacity)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Tap: 1x = select, 2x = editor
            .highPriorityGesture(
                TapGesture().onEnded {
                    guard !suppressNextTap else { return }
                    if isSelected { onOpenEditor() } else { onSelect() }
                }
            )

            // LongPress: nur select, Editor nicht öffnen
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.25, maximumDistance: 12)
                    .onEnded { _ in
                        suppressNextTap = true
                        onSelect()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                            suppressNextTap = false
                        }
                    }
            )

            // LongPress + Drag: Move (auch wenn nicht selected)
            .simultaneousGesture(longPressThenMove)

            // Drag auf selektiertem Block: Move
            .simultaneousGesture(selectedMove)
        }
    }

    // MARK: - Handle

    private func handle(mode: DragMode) -> some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.28))
                .frame(width: 38, height: 6)
                .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 1))
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .highPriorityGesture(resizeGesture(mode))
    }

    private func resizeGesture(_ mode: DragMode) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { v in
                guard isSelected else { return }
                if let l = lock, l != mode { return }
                if lock == nil {
                    lock = mode
                    onBeginInteraction(mode)
                }
                onChangeInteraction(mode, v.translation.height, v.location.y)
            }
            .onEnded { _ in
                guard isSelected else { return }
                if lock == mode { onEndInteraction(mode) }
                lock = nil
            }
    }

    // MARK: - Move gestures

    private var selectedMove: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged { v in
                guard isSelected else { return }
                if let l = lock, l != .move { return }
                if lock == nil {
                    lock = .move
                    onBeginInteraction(.move)
                }
                onChangeInteraction(.move, v.translation.height, v.location.y)
            }
            .onEnded { _ in
                guard isSelected else { return }
                if lock == .move { onEndInteraction(.move) }
                lock = nil
            }
    }

    private var longPressThenMove: some Gesture {
        LongPressGesture(minimumDuration: 0.22, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                switch value {
                case .first(true):
                    longPressMoveArmed = true
                case .second(true, let drag?):
                    guard longPressMoveArmed else { return }
                    if let l = lock, l != .move { return }
                    if lock == nil {
                        onSelect()
                        lock = .move
                        onBeginInteraction(.move)
                    }
                    onChangeInteraction(.move, drag.translation.height, drag.location.y)
                default:
                    break
                }
            }
            .onEnded { _ in
                longPressMoveArmed = false
                if lock == .move { onEndInteraction(.move) }
                lock = nil
            }
    }
}

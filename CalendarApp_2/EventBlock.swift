//
//  EventBlock.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct EventBlock: View {
    let event: CalendarEventEntity
    let frame: CGRect
    let isSelected: Bool
    let color: Color
    let showsTime: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: (CGFloat) -> Void
    let onResizeChanged: (ResizeHandle, CGFloat) -> Void
    let onResizeEnded: (ResizeHandle, CGFloat) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.6), lineWidth: 1)
                )

            HStack(spacing: 8) {
                Rectangle()
                    .fill(color)
                    .frame(width: 4)
                    .cornerRadius(2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    if showsTime {
                        Text(event.start.formatted(.dateTime.hour().minute()) + " – " + event.end.formatted(.dateTime.hour().minute()))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(10)

            if isSelected {
                ResizeHandleView(position: .top)
                    .gesture(resizeGesture(for: .top))
                ResizeHandleView(position: .bottom)
                    .gesture(resizeGesture(for: .bottom))
            }
        }
        .frame(width: frame.width, height: frame.height)
        .offset(x: frame.minX, y: frame.minY)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.3)
                .onEnded { _ in onLongPress() }
        )
        .highPriorityGesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in onDragChanged(value.translation.height) }
                .onEnded { value in onDragEnded(value.translation.height) }
        )
    }

    private func resizeGesture(for handle: ResizeHandle) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in onResizeChanged(handle, value.translation.height) }
            .onEnded { value in onResizeEnded(handle, value.translation.height) }
    }
}

enum ResizeHandle {
    case top
    case bottom
}

struct ResizeHandleView: View {
    let position: ResizeHandle

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .frame(height: 18)
            .overlay(alignment: position == .top ? .top : .bottom) {
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 42, height: 4)
                    .padding(position == .top ? .top : .bottom, 4)
            }
            .frame(maxHeight: .infinity, alignment: position == .top ? .top : .bottom)
    }
}

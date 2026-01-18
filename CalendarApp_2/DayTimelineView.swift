//
//  DayTimelineView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI
import SwiftData

struct DayTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [CalendarEventEntity]

    let day: Date
    @Binding var showDebugOverlay: Bool
    let scrollToTodayTrigger: UUID

    @State private var selectedEventID: UUID?
    @State private var showEditor = false
    @State private var isScrollLocked = false
    @State private var ghostRect: CGRect?
    @State private var createStartY: CGFloat?
    @State private var createBlocked = false
    @State private var dragOffsets: [UUID: Int] = [:]
    @State private var resizeOffsets: [UUID: (top: Int, bottom: Int)] = [:]

    @StateObject private var scrollController = TimelineScrollController()

    private let calendar = Calendar.current
    private let colorPresets: [ColorPreset] = [
        ColorPreset(name: "Red", hex: "#FF453A"),
        ColorPreset(name: "Orange", hex: "#FF9F0A"),
        ColorPreset(name: "Yellow", hex: "#FFD60A"),
        ColorPreset(name: "Green", hex: "#30D158"),
        ColorPreset(name: "Blue", hex: "#0A84FF")
    ]

    init(day: Date, showDebugOverlay: Binding<Bool>, scrollToTodayTrigger: UUID) {
        let calendar = Calendar.current
        let normalizedDay = calendar.startOfDay(for: day)
        self.day = normalizedDay
        _showDebugOverlay = showDebugOverlay
        self.scrollToTodayTrigger = scrollToTodayTrigger
        let startOfDay = normalizedDay
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        _events = Query(
            filter: #Predicate<CalendarEventEntity> { $0.start >= startOfDay && $0.start < endOfDay },
            sort: [SortDescriptor(\.start)]
        )
    }

    var body: some View {
        TimelineScrollView(controller: scrollController, isScrollEnabled: !isScrollLocked) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            TimelineHourRow(hour: hour)
                        }
                    }

                    ForEach(layoutItems) { item in
                        EventBlock(
                            event: item.event,
                            frame: item.frame,
                            isSelected: selectedEventID == item.event.id,
                            color: Color(hex: item.event.colorHex),
                            showsTime: item.showsTime,
                            onTap: { handleTap(event: item.event) },
                            onLongPress: { selectedEventID = item.event.id },
                            onDragChanged: { translation in
                                handleDragChanged(event: item.event, translation: translation, locationY: item.frame.minY + translation)
                            },
                            onDragEnded: { translation in
                                handleDragEnded(event: item.event, translation: translation)
                            },
                            onResizeChanged: { handle, translation in
                                handleResizeChanged(event: item.event, handle: handle, translation: translation, anchorY: item.frame.minY)
                            },
                            onResizeEnded: { handle, translation in
                                handleResizeEnded(event: item.event, handle: handle, translation: translation)
                            }
                        )
                    }

                    if let ghostRect {
                        GhostEventBlock(rect: ghostRect)
                    }

                    NowLine(day: day)

                    if showDebugOverlay {
                        DebugOverlayView(text: "Events: \(events.count)  Selected: \(selectedEventID?.uuidString.prefix(4) ?? "nil")")
                            .offset(x: 16, y: 12)
                    }
                }
                .frame(height: CalendarConstants.hourHeight * 24)
                .coordinateSpace(name: "timeline")
                .contentShape(Rectangle())
                .gesture(backgroundTapGesture)
                .gesture(createGesture(in: geometry))
                .onAppear {
                    scrollToInitialPosition()
                }
                .onChange(of: day) { _, _ in
                    scrollToInitialPosition()
                }
                .onChange(of: scrollToTodayTrigger) { _, _ in
                    if calendar.isDateInToday(day) {
                        scrollToInitialPosition()
                    }
                }
                .onChange(of: events) { _, newEvents in
                    if let selectedID = selectedEventID, !newEvents.contains(where: { $0.id == selectedID }) {
                        selectedEventID = nil
                        showEditor = false
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showEditor) {
            if let event = events.first(where: { $0.id == selectedEventID }) {
                EventEditorSheet(event: event, presets: colorPresets)
            }
        }
    }

    private var layoutItems: [EventLayoutItem] {
        let adjusted = events.map { event in
            let offsets = resizeOffsets[event.id] ?? (top: 0, bottom: 0)
            let dragOffset = dragOffsets[event.id] ?? 0
            let start = calendar.date(byAdding: .minute, value: dragOffset + offsets.top, to: event.start) ?? event.start
            let end = calendar.date(byAdding: .minute, value: dragOffset + offsets.bottom, to: event.end) ?? event.end
            return EventLayoutData(event: event, start: start, end: max(end, start.addingTimeInterval(60 * Double(CalendarConstants.minEventMinutes))))
        }
        return layoutEvents(adjusted)
    }

    private func handleTap(event: CalendarEventEntity) {
        if selectedEventID == event.id {
            showEditor = true
        } else {
            selectedEventID = event.id
        }
    }

    private var backgroundTapGesture: some Gesture {
        TapGesture().onEnded {
            selectedEventID = nil
        }
    }

    private func createGesture(in geometry: GeometryProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("timeline")))
            .onChanged { value in
                switch value {
                case .second(true, let drag?):
                    if createBlocked {
                        return
                    }
                    if createStartY == nil {
                        if isPointOnEvent(drag.startLocation) {
                            createBlocked = true
                            return
                        }
                        createStartY = drag.startLocation.y
                    }
                    updateGhost(from: drag.startLocation.y, to: drag.location.y, width: geometry.size.width)
                    updateAutoScroll(locationY: drag.location.y)
                default:
                    break
                }
            }
            .onEnded { value in
                defer {
                    createStartY = nil
                    createBlocked = false
                    ghostRect = nil
                    scrollController.stopAutoScroll()
                    isScrollLocked = false
                }
                guard case .second(true, let drag?) = value else { return }
                guard !createBlocked, !isPointOnEvent(drag.startLocation) else { return }
                createEvent(from: drag.startLocation.y, to: drag.location.y)
            }
    }

    private func handleDragChanged(event: CalendarEventEntity, translation: CGFloat, locationY: CGFloat) {
        isScrollLocked = true
        let minutes = snapMinutes(minutesFromOffset(translation))
        dragOffsets[event.id] = minutes
        updateAutoScroll(locationY: locationY)
    }

    private func handleDragEnded(event: CalendarEventEntity, translation: CGFloat) {
        let minutes = snapMinutes(minutesFromOffset(translation))
        dragOffsets[event.id] = nil
        isScrollLocked = false
        scrollController.stopAutoScroll()
        let (newStart, newEnd) = shiftedTimes(for: event, by: minutes)
        event.start = newStart
        event.end = newEnd
    }

    private func handleResizeChanged(event: CalendarEventEntity, handle: ResizeHandle, translation: CGFloat, anchorY: CGFloat) {
        isScrollLocked = true
        let minutes = snapMinutes(minutesFromOffset(translation))
        var offsets = resizeOffsets[event.id] ?? (top: 0, bottom: 0)
        switch handle {
        case .top:
            offsets.top = minutes
        case .bottom:
            offsets.bottom = minutes
        }
        resizeOffsets[event.id] = offsets
        updateAutoScroll(locationY: anchorY + translation)
    }

    private func handleResizeEnded(event: CalendarEventEntity, handle: ResizeHandle, translation: CGFloat) {
        let minutes = snapMinutes(minutesFromOffset(translation))
        resizeOffsets[event.id] = nil
        isScrollLocked = false
        scrollController.stopAutoScroll()

        switch handle {
        case .top:
            let newStart = clampDate(event.start.addingTimeInterval(TimeInterval(minutes * 60)))
            let minEnd = newStart.addingTimeInterval(TimeInterval(CalendarConstants.minEventMinutes * 60))
            event.start = newStart
            event.end = max(event.end, minEnd)
        case .bottom:
            let newEnd = clampDate(event.end.addingTimeInterval(TimeInterval(minutes * 60)))
            let minEnd = event.start.addingTimeInterval(TimeInterval(CalendarConstants.minEventMinutes * 60))
            event.end = max(newEnd, minEnd)
        }
    }

    private func updateGhost(from start: CGFloat, to end: CGFloat, width: CGFloat) {
        isScrollLocked = true
        let minY = min(start, end)
        let maxY = max(start, end)
        let height = max(maxY - minY, CalendarConstants.minuteHeight * CGFloat(CalendarConstants.minEventMinutes))
        ghostRect = CGRect(x: CalendarConstants.timelinePaddingLeading, y: minY, width: width - CalendarConstants.timelinePaddingLeading - 16, height: height)
    }

    private func createEvent(from startY: CGFloat, to endY: CGFloat) {
        let startMinutes = minutesFromOffset(min(startY, endY))
        let endMinutes = minutesFromOffset(max(startY, endY))
        let rawDuration = endMinutes - startMinutes
        var duration = max(rawDuration, CalendarConstants.minEventMinutes)
        if rawDuration < CalendarConstants.minEventMinutes {
            duration = CalendarConstants.defaultEventMinutes
        }
        if abs(duration - 30) <= 3 {
            duration = 30
            Haptics.light()
        } else if abs(duration - 60) <= 3 {
            duration = 60
            Haptics.light()
        }
        let snappedStart = snapMinutes(startMinutes)
        let snappedEnd = snappedStart + max(duration, CalendarConstants.minEventMinutes)

        let startDate = dateBySetting(minutes: snappedStart)
        let endDate = dateBySetting(minutes: min(snappedEnd, 24 * 60))
        let newEvent = CalendarEventEntity(
            title: "New Event",
            start: startDate,
            end: endDate,
            colorHex: colorPresets.first?.hex ?? "#FF453A"
        )
        modelContext.insert(newEvent)
        selectedEventID = newEvent.id
    }

    private func isPointOnEvent(_ point: CGPoint) -> Bool {
        layoutItems.contains { $0.frame.contains(point) }
    }

    private func updateAutoScroll(locationY: CGFloat) {
        let visibleHeight = scrollController.visibleHeight
        guard visibleHeight > 0 else { return }
        let hotZone: CGFloat = 60
        if locationY < hotZone {
            scrollController.startAutoScroll(direction: -1)
        } else if locationY > visibleHeight - hotZone {
            scrollController.startAutoScroll(direction: 1)
        } else {
            scrollController.stopAutoScroll()
        }
    }

    private func scrollToInitialPosition() {
        let targetMinutes: Int
        if calendar.isDateInToday(day) {
            let now = Date()
            let minutes = calendar.dateComponents([.minute], from: calendar.startOfDay(for: day), to: now).minute ?? 0
            targetMinutes = max(minutes - 60, 0)
        } else {
            targetMinutes = 8 * 60
        }
        scrollController.scrollTo(y: CGFloat(targetMinutes) * CalendarConstants.minuteHeight, animated: false)
    }

    private func dateBySetting(minutes: Int) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: startOfDay) ?? startOfDay
    }

    private func clampDate(_ date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        return min(max(date, startOfDay), endOfDay.addingTimeInterval(-60))
    }

    private func shiftedTimes(for event: CalendarEventEntity, by minutes: Int) -> (Date, Date) {
        let newStart = clampDate(event.start.addingTimeInterval(TimeInterval(minutes * 60)))
        let duration = event.end.timeIntervalSince(event.start)
        let newEnd = clampDate(newStart.addingTimeInterval(duration))
        return (newStart, newEnd)
    }
}

struct EventLayoutData {
    let event: CalendarEventEntity
    let start: Date
    let end: Date
}

struct EventLayoutItem: Identifiable {
    let id: UUID
    let event: CalendarEventEntity
    let frame: CGRect
    let showsTime: Bool
}

private func layoutEvents(_ events: [EventLayoutData]) -> [EventLayoutItem] {
    let sorted = events.sorted { $0.start < $1.start }
    var groups: [[EventLayoutData]] = []
    var currentGroup: [EventLayoutData] = []
    var active: [EventLayoutData] = []

    for event in sorted {
        active.removeAll { $0.end <= event.start }
        if active.isEmpty, !currentGroup.isEmpty {
            groups.append(currentGroup)
            currentGroup = []
        }
        active.append(event)
        currentGroup.append(event)
    }
    if !currentGroup.isEmpty {
        groups.append(currentGroup)
    }

    var layoutItems: [EventLayoutItem] = []
    for group in groups {
        var columns: [[EventLayoutData]] = []
        for event in group {
            var placed = false
            for index in columns.indices {
                if let last = columns[index].last, last.end <= event.start {
                    columns[index].append(event)
                    placed = true
                    break
                }
            }
            if !placed {
                columns.append([event])
            }
        }
        let columnCount = max(columns.count, 1)
        let columnWidth = (UIScreen.main.bounds.width - CalendarConstants.timelinePaddingLeading - 24) / CGFloat(columnCount)

        for (columnIndex, column) in columns.enumerated() {
            for event in column {
                let startRaw = Calendar.current.dateComponents([.minute], from: Calendar.current.startOfDay(for: event.start), to: event.start).minute ?? 0
                let endRaw = Calendar.current.dateComponents([.minute], from: Calendar.current.startOfDay(for: event.end), to: event.end).minute ?? 0
                let startMinutes = max(0, min(startRaw, 24 * 60))
                let endMinutes = max(startMinutes, min(endRaw, 24 * 60))
                let minHeight = CGFloat(CalendarConstants.minEventMinutes) * CalendarConstants.minuteHeight
                let height = max(CGFloat(endMinutes - startMinutes) * CalendarConstants.minuteHeight, minHeight)
                let x = CalendarConstants.timelinePaddingLeading + CGFloat(columnIndex) * columnWidth
                let y = CGFloat(startMinutes) * CalendarConstants.minuteHeight
                let frame = CGRect(x: x, y: y, width: columnWidth - 8, height: height)
                let showsTime = height > 48
                layoutItems.append(EventLayoutItem(id: event.event.id, event: event.event, frame: frame, showsTime: showsTime))
            }
        }
    }
    return layoutItems
}

struct TimelineHourRow: View {
    let hour: Int

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(String(format: "%02d:00", hour))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 52, alignment: .trailing)
                .padding(.top, -6)

            Rectangle()
                .fill(Color.white.opacity(CalendarConstants.gridLineOpacity))
                .frame(height: 1)
                .padding(.top, 6)
        }
        .frame(height: CalendarConstants.hourHeight)
        .id(hour)
    }
}

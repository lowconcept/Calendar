//
//  DayTimelineView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct DayPagerView: View {

    private let range: ClosedRange<Int> = (-21)...(21)
    private let centerIndex: Int = 21

    @State private var pageIndex: Int = 21
    @State private var selectedDate: Date = Date()
    @State private var scrollOffsetsByPageIndex: [Int: CGFloat] = [:]

    private var baseDate: Date { Calendar.current.startOfDay(for: Date()) }

    private func dateForTag(_ tag: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: tag - centerIndex, to: baseDate)!
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $pageIndex) {
                ForEach(range, id: \.self) { tag in
                    DayTimelineView(
                        date: dateForTag(tag),
                        preservedScrollOffsetY: scrollOffsetBinding(for: tag)
                    )
                    .tag(tag)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            CalendarHeaderView(
                date: selectedDate,
                onToday: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        pageIndex = centerIndex
                    }
                }
            )
        }
        .onAppear { selectedDate = dateForTag(pageIndex) }
        .onChange(of: pageIndex) { _, newValue in
            selectedDate = dateForTag(newValue)
        }
    }

    private func scrollOffsetBinding(for index: Int) -> Binding<CGFloat> {
        Binding(
            get: { scrollOffsetsByPageIndex[index, default: 0] },
            set: { scrollOffsetsByPageIndex[index] = $0 }
        )
    }
}

import SwiftData
import UIKit

struct DayTimelineView: View {

    @Environment(\.modelContext) private var context
    @Query private var dayEvents: [CalendarEvent]

    let date: Date
    @Binding var preservedScrollOffsetY: CGFloat

    init(date: Date, preservedScrollOffsetY: Binding<CGFloat>) {
        self.date = date
        _preservedScrollOffsetY = preservedScrollOffsetY

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!

        _dayEvents = Query(
            filter: #Predicate<CalendarEvent> { ev in
                ev.start < dayEnd && ev.end > dayStart
            },
            sort: [SortDescriptor(\CalendarEvent.start, order: .forward)]
        )
    }

    // Layout
    private let hourRowHeight: CGFloat = 54
    private let leftGutter: CGFloat = 56
    private var contentHeight: CGFloat { hourRowHeight * 24 }

    // Snap
    private let snapStepMinutes: Int = 5
    private let minDurationMinutes: Int = 10
    private let defaultNewEventMinutes: Int = 60
    private let createStartThreshold: CGFloat = 10

    // Magnet
    private let magnet30Tolerance: Int = 7
    private let magnet60Tolerance: Int = 10

    // Selection + Editor
    // Wichtig: Identität NICHT über eigene UUID, sondern über das Model selbst
    @State private var activeEvent: CalendarEvent? = nil
    @State private var editingEvent: CalendarEvent? = nil

    // Interaction lock
    @State private var draggingEvent: CalendarEvent? = nil
    @State private var draggingMode: EventBlock.DragMode? = nil
    @State private var isInteracting = false
    @State private var baselineStart: Date = .distantPast
    @State private var baselineEnd: Date = .distantPast

    // Create ghost
    @State private var isCreating = false
    @State private var createStartY: CGFloat = 0
    @State private var createCurrentY: CGFloat = 0

    // Haptics
    @State private var lastSnappedCreateKey: Int? = nil
    @State private var lastMagnetDuration: Int? = nil

    // Scroll
    @State private var scrollController = TimelineScrollController()

    // Auto-scroll
    @State private var autoScrollLink: CADisplayLink? = nil
    @State private var autoScrollVelocity: CGFloat = 0
    @State private var autoScrollTarget: AutoScrollTarget? = nil

    var body: some View {

        let positioned = layoutOverlaps(dayEvents.sorted { $0.start < $1.start })

        TimelineScrollView(
            controller: scrollController,
            offsetY: $preservedScrollOffsetY,
            contentHeight: contentHeight
        ) {
            ZStack(alignment: .topLeading) {

                hourGrid
                    .allowsHitTesting(false)

                GeometryReader { geo in
                    let timelineWidth = max(geo.size.width - leftGutter - 16, 120)

                    let eventRects: [CGRect] = positioned.map { p in
                        eventRect(for: p, timelineWidth: timelineWidth)
                    }

                    ZStack(alignment: .topLeading) {

                        // Background surface (tap deselect + longpress create)
                        Color.clear
                            .frame(height: contentHeight)
                            .contentShape(Rectangle())
                            .highPriorityGesture(backgroundTapGesture)
                            .simultaneousGesture(createGesture(eventRects: eventRects, geo: geo))

                        // Now line
                        if Calendar.current.isDateInToday(date) {
                            TimelineView(.periodic(from: Date(), by: 30)) { ctx in
                                let y = yPosition(for: ctx.date, day: date)
                                NowLine(leftGutter: leftGutter, timelineWidth: timelineWidth, y: y)
                                    .allowsHitTesting(false)
                                    .zIndex(40)
                            }
                        }

                        // Events
                        ForEach(positioned) { p in
                            let event = p.event
                            let isSelected = (activeEvent == event)

                            let slotWidth = timelineWidth / CGFloat(p.totalColumns)
                            let rawWidth = slotWidth * CGFloat(p.span)
                            let inset: CGFloat = 6

                            let maxWidth = max(28, rawWidth - inset)
                            let minWidth: CGFloat = (slotWidth < 70) ? max(24, slotWidth - inset) : 52
                            let width = min(maxWidth, max(minWidth, rawWidth - inset))

                            let leftX = leftGutter + 8 + CGFloat(p.column) * slotWidth + inset / 2
                            let centerX = leftX + width / 2

                            EventBlock(
                                title: event.title,
                                timeText: timeRangeText(event.start, event.safeEnd),
                                color: Color(hex: event.colorHex),
                                isSelected: isSelected,
                                onSelect: {
                                    activeEvent = event
                                },
                                onOpenEditor: {
                                    activeEvent = event
                                    editingEvent = event
                                },
                                onBeginInteraction: { mode in
                                    beginInteraction(event: event, mode: mode)
                                },
                                onChangeInteraction: { mode, dy, fingerGlobalY in
                                    updateAutoScroll(fingerGlobalY: fingerGlobalY)
                                    applyDrag(event: event, mode: mode, deltaY: dy)
                                },
                                onEndInteraction: { _ in
                                    stopAutoScroll()
                                    endInteraction()
                                }
                            )
                            .frame(width: width, height: blockHeight(for: event, day: date))
                            .position(
                                x: centerX,
                                y: yPosition(for: event.start, day: date) + blockHeight(for: event, day: date) / 2
                            )
                            .zIndex(isSelected ? 10 : 1)
                        }

                        // Ghost
                        if isCreating {
                            let ghost = ghostRect(timelineWidth: timelineWidth)
                            GhostEventBlockDarkGlass()
                                .frame(width: ghost.width, height: ghost.height)
                                .position(x: ghost.midX, y: ghost.midY)
                                .allowsHitTesting(false)
                                .zIndex(50)
                        }
                    }
                }
                .frame(height: contentHeight)
            }
            .background(Color.black)
        }
        .onAppear {
            scrollToSuggestedTime(animated: false)
        }
        .onDisappear {
            stopAutoScroll()
            scrollController.setUserScrollEnabled(true)
        }
        .onChange(of: isInteracting) { _, newValue in
            if !newValue { scrollController.setUserScrollEnabled(true) }
        }
        .onChange(of: isCreating) { _, newValue in
            if !newValue { scrollController.setUserScrollEnabled(true) }
        }
        .sheet(item: $editingEvent) { ev in
            EventEditorSheet(event: ev, clampedToDay: date)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Suggested scroll

    private func scrollToSuggestedTime(animated: Bool) {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let nowY = yPosition(for: Date(), day: date)
            scrollController.scrollTo(y: max(0, nowY - 160), animated: animated)
        } else {
            let morning = dateAtMinute(minutes: 8 * 60, day: date)
            let y = yPosition(for: morning, day: date)
            scrollController.scrollTo(y: max(0, y - 120), animated: animated)
        }
    }

    // MARK: - Background tap

    private var backgroundTapGesture: some Gesture {
        TapGesture().onEnded {
            guard !isInteracting, !isCreating else { return }
            activeEvent = nil
        }
    }

    // MARK: - Create gesture

    private func createGesture(eventRects: [CGRect], geo: GeometryProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35, maximumDistance: 8)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { value in
                guard !isInteracting else { return }

                switch value {
                case .first(true):
                    break

                case .second(true, let drag?):

                    if !isCreating {
                        // Kein Create wenn Start auf Event
                        if eventRects.contains(where: { $0.contains(drag.startLocation) }) { return }

                        let dy = drag.translation.height
                        let dx = drag.translation.width
                        guard abs(dy) > createStartThreshold, abs(dy) > abs(dx) * 1.2 else { return }

                        isCreating = true
                        activeEvent = nil

                        // Scroll während Create blocken (nur während Create!)
                        scrollController.setUserScrollEnabled(false)

                        createStartY = clampY(drag.startLocation.y)
                        createCurrentY = clampY(drag.location.y)
                        lastSnappedCreateKey = nil
                        lastMagnetDuration = nil
                        Haptics.light()
                        return
                    }

                    createCurrentY = clampY(drag.location.y)

                    // auto-scroll while creating (nur wenn Edge)
                    let frame = geo.frame(in: .global)
                    let fingerGlobalY = frame.minY + drag.location.y
                    updateAutoScroll(fingerGlobalY: fingerGlobalY)

                    // haptics: snap + magnet
                    let topY = min(createStartY, createCurrentY)
                    let bottomY = max(createStartY, createCurrentY)

                    let startMin = snappedMinutes(forY: topY)
                    var endMin = snappedMinutes(forY: bottomY)
                    if endMin <= startMin { endMin = startMin + minDurationMinutes }

                    let snappedDuration = max(minDurationMinutes, endMin - startMin)
                    let magnetedDuration = applyMagnet(snappedDuration)

                    let key = startMin * 10_000 + (startMin + snappedDuration)
                    if lastSnappedCreateKey != key {
                        lastSnappedCreateKey = key
                        Haptics.tick()
                    }

                    if lastMagnetDuration != magnetedDuration,
                       (magnetedDuration == 30 || magnetedDuration == 60) {
                        lastMagnetDuration = magnetedDuration
                        Haptics.strong()
                    }

                default:
                    break
                }
            }
            .onEnded { value in
                guard !isInteracting else { return }
                guard isCreating else { return }

                stopAutoScroll()

                defer {
                    isCreating = false
                    lastSnappedCreateKey = nil
                    lastMagnetDuration = nil
                    scrollController.setUserScrollEnabled(true)
                }

                switch value {
                case .second(true, let drag?):
                    finalizeCreate(fromY: clampY(drag.startLocation.y), toY: clampY(drag.location.y))
                default:
                    finalizeCreate(fromY: clampY(createStartY), toY: clampY(createCurrentY))
                }
            }
    }

    private func finalizeCreate(fromY y0: CGFloat, toY y1: CGFloat) {
        let topY = min(y0, y1)
        let bottomY = max(y0, y1)

        var startMin = snappedMinutes(forY: topY)
        var endMin = snappedMinutes(forY: bottomY)

        if endMin <= startMin { endMin = startMin + defaultNewEventMinutes }

        var duration = max(minDurationMinutes, endMin - startMin)
        duration = applyMagnet(duration)

        startMin = clampMinutes(startMin)
        let endClamped = clampMinutes(startMin + duration)

        let start = dateAtMinute(minutes: startMin, day: date)
        let end = dateAtMinute(minutes: endClamped, day: date)

        let newEvent = CalendarEvent(
            title: "New Event",
            start: start,
            end: end,
            colorHex: "#22C55E"
        )

        context.insert(newEvent)
        activeEvent = newEvent
        editingEvent = nil
    }

    // MARK: - Auto scroll (edge)

    private func updateAutoScroll(
        fingerGlobalY: CGFloat,
        lockScrollDuringInteraction: Bool = false
    ) {
        guard let sv = scrollController.scrollView else { return }

        let frame = sv.convert(sv.bounds, to: nil)
        let topZone: CGFloat = 90
        let bottomZone: CGFloat = 120

        let distTop = (frame.minY + topZone) - fingerGlobalY
        let distBottom = fingerGlobalY - (frame.maxY - bottomZone)

        var v: CGFloat = 0
        if distTop > 0 {
            v = -min(18, max(2, distTop / 6))
        } else if distBottom > 0 {
            v = min(18, max(2, distBottom / 6))
        }

        if v == 0 {
            autoScrollVelocity = 0
            stopAutoScroll()
            return
        }

        if lockScrollDuringInteraction {
            scrollController.setUserScrollEnabled(false)
        }

        autoScrollVelocity = v
        startAutoScrollIfNeeded()
    }

    private func startAutoScrollIfNeeded() {
        if autoScrollLink != nil { return }

        let velocity = autoScrollVelocity
        let controller = scrollController

        let target = AutoScrollTarget {
            let v = velocity
            if v != 0, controller.scrollView != nil {
                controller.scrollBy(dy: v)
            }
        }
        autoScrollTarget = target

        let link = CADisplayLink(target: target, selector: #selector(AutoScrollTarget.tick))
        link.add(to: .main, forMode: .common)
        autoScrollLink = link
    }

    private func stopAutoScroll() {
        autoScrollLink?.invalidate()
        autoScrollLink = nil
        autoScrollVelocity = 0
        autoScrollTarget = nil
    }

    private final class AutoScrollTarget: NSObject {
        let block: () -> Void
        init(_ block: @escaping () -> Void) { self.block = block }
        @objc func tick() { block() }
    }

    // MARK: - Interaction baseline

    private func beginInteraction(event: CalendarEvent, mode: EventBlock.DragMode) {
        if draggingEvent !== event || draggingMode != mode {
            draggingEvent = event
            draggingMode = mode
            baselineStart = event.start
            baselineEnd = event.safeEnd
        }

        activeEvent = event
        isInteracting = true
        scrollController.setUserScrollEnabled(false)
    }

    private func endInteraction() {
        isInteracting = false
        draggingEvent = nil
        draggingMode = nil
        scrollController.setUserScrollEnabled(true)
    }

    private func applyDrag(event: CalendarEvent, mode: EventBlock.DragMode, deltaY: CGFloat) {
        guard draggingEvent === event else { return }
        isInteracting = true

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!

        let rawMinutes = Int(((deltaY / hourRowHeight) * 60.0).rounded())
        let snapped = snap(rawMinutes, step: snapStepMinutes)

        func clamp(_ d: Date) -> Date { min(max(d, dayStart), dayEnd) }

        switch mode {
        case .move:
            let ns = cal.date(byAdding: .minute, value: snapped, to: baselineStart) ?? baselineStart
            let ne = cal.date(byAdding: .minute, value: snapped, to: baselineEnd) ?? baselineEnd

            var s = clamp(ns)
            var e = clamp(ne)

            let dur = Int(baselineEnd.timeIntervalSince(baselineStart) / 60)
            let cur = Int(e.timeIntervalSince(s) / 60)

            if cur < dur {
                let wantedEnd = cal.date(byAdding: .minute, value: dur, to: s) ?? e
                e = min(wantedEnd, dayEnd)

                let wantedStart = cal.date(byAdding: .minute, value: -dur, to: e) ?? s
                s = max(wantedStart, dayStart)
            }

            event.start = s
            event.end = max(e, cal.date(byAdding: .minute, value: minDurationMinutes, to: s)!)

        case .resizeTop:
            let proposed = cal.date(byAdding: .minute, value: snapped, to: baselineStart) ?? baselineStart
            let s = clamp(proposed)

            let minEnd = cal.date(byAdding: .minute, value: minDurationMinutes, to: s) ?? event.safeEnd
            event.start = s
            event.end = clamp(max(event.safeEnd, minEnd))

        case .resizeBottom:
            let proposed = cal.date(byAdding: .minute, value: snapped, to: baselineEnd) ?? baselineEnd
            let e = clamp(proposed)

            let minEnd = cal.date(byAdding: .minute, value: minDurationMinutes, to: event.start) ?? e
            event.end = max(e, minEnd)
        }
    }

    // MARK: - Ghost rect

    private func ghostRect(timelineWidth: CGFloat) -> CGRect {
        let x = leftGutter + 8
        let w = timelineWidth

        let topY = min(createStartY, createCurrentY)
        let bottomY = max(createStartY, createCurrentY)

        var startMin = snappedMinutes(forY: topY)
        var endMin = snappedMinutes(forY: bottomY)
        if endMin <= startMin { endMin = startMin + minDurationMinutes }

        var duration = max(minDurationMinutes, endMin - startMin)
        duration = applyMagnet(duration)

        startMin = clampMinutes(startMin)
        let finalEndMin = clampMinutes(startMin + duration)
        let finalDuration = max(minDurationMinutes, finalEndMin - startMin)

        let y = minutesToY(startMin)
        let h = minutesToY(startMin + finalDuration) - y

        let clampedY = min(max(y, 0), contentHeight - h)
        return CGRect(x: x, y: clampedY, width: w, height: h)
    }

    // MARK: - Grid

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(spacing: 0) {
                    Text(String(format: "%02d", hour))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: leftGutter, alignment: .trailing)
                        .padding(.trailing, 10)

                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)

                    Spacer()
                }
                .frame(height: hourRowHeight)
            }
        }
    }

    // MARK: - Overlap layout

    struct PositionedEvent: Identifiable {
        let event: CalendarEvent
        let column: Int
        let totalColumns: Int
        let span: Int

        // Identität direkt über das Model
        var id: CalendarEvent { event }
    }

    private func overlaps(_ a: CalendarEvent, _ b: CalendarEvent) -> Bool {
        a.start < b.safeEnd && a.safeEnd > b.start
    }

    private func layoutOverlaps(_ events: [CalendarEvent]) -> [PositionedEvent] {
        guard !events.isEmpty else { return [] }
        let sorted = events.sorted { $0.start < $1.start }

        var clusters: [[CalendarEvent]] = []
        var cur: [CalendarEvent] = []
        var curMax: Date = .distantPast

        for e in sorted {
            if cur.isEmpty {
                cur = [e]
                curMax = e.safeEnd
            } else if e.start < curMax {
                cur.append(e)
                curMax = max(curMax, e.safeEnd)
            } else {
                clusters.append(cur)
                cur = [e]
                curMax = e.safeEnd
            }
        }
        if !cur.isEmpty { clusters.append(cur) }

        var out: [PositionedEvent] = []
        out.reserveCapacity(events.count)

        for cl in clusters {
            let cSorted = cl.sorted { $0.start < $1.start }

            var colEnd: [Date] = []
            var assigned: [(CalendarEvent, Int)] = []

            for e in cSorted {
                var placed = false
                for i in 0..<colEnd.count {
                    if e.start >= colEnd[i] {
                        colEnd[i] = e.safeEnd
                        assigned.append((e, i))
                        placed = true
                        break
                    }
                }
                if !placed {
                    colEnd.append(e.safeEnd)
                    assigned.append((e, colEnd.count - 1))
                }
            }

            let total = colEnd.count
            var perCol: [[CalendarEvent]] = Array(repeating: [], count: total)
            for (e, c) in assigned { perCol[c].append(e) }

            for (e, c) in assigned {
                var span = 1
                var next = c + 1
                while next < total {
                    if perCol[next].contains(where: { overlaps(e, $0) }) { break }
                    span += 1
                    next += 1
                }
                out.append(PositionedEvent(event: e, column: c, totalColumns: total, span: span))
            }
        }

        return out.sorted { $0.event.start < $1.event.start }
    }

    private func eventRect(for p: PositionedEvent, timelineWidth: CGFloat) -> CGRect {
        let slotWidth = timelineWidth / CGFloat(p.totalColumns)
        let rawWidth = slotWidth * CGFloat(p.span)
        let inset: CGFloat = 6

        let maxWidth = max(28, rawWidth - inset)
        let minWidth: CGFloat = (slotWidth < 70) ? max(24, slotWidth - inset) : 52
        let width = min(maxWidth, max(minWidth, rawWidth - inset))

        let x = leftGutter + 8 + CGFloat(p.column) * slotWidth + inset / 2
        let y = yPosition(for: p.event.start, day: date)
        let h = blockHeight(for: p.event, day: date)
        return CGRect(x: x, y: y, width: width, height: h)
    }

    // MARK: - Helpers

    private func minutesSinceStartOfDay(_ dt: Date, day: Date) -> CGFloat {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let diff = dt.timeIntervalSince(start) / 60
        return CGFloat(max(0, min(24 * 60, diff)))
    }

    private func yPosition(for dt: Date, day: Date) -> CGFloat {
        (minutesSinceStartOfDay(dt, day: day) / 60) * hourRowHeight
    }

    private func blockHeight(for event: CalendarEvent, day: Date) -> CGFloat {
        let s = minutesSinceStartOfDay(event.start, day: day)
        let e = minutesSinceStartOfDay(event.safeEnd, day: day)
        let dur = max(CGFloat(minDurationMinutes), e - s)
        return (dur / 60) * hourRowHeight
    }

    private func dateAtMinute(minutes: Int, day: Date) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        return cal.date(byAdding: .minute, value: minutes, to: start) ?? start
    }

    private func minutesToY(_ minutes: Int) -> CGFloat {
        (CGFloat(minutes) / 60) * hourRowHeight
    }

    private func snappedMinutes(forY y: CGFloat) -> Int {
        let raw = Int(((y / hourRowHeight) * 60.0).rounded())
        return snap(raw, step: snapStepMinutes)
    }

    private func clampY(_ y: CGFloat) -> CGFloat {
        min(max(y, 0), contentHeight)
    }

    private func clampMinutes(_ m: Int) -> Int {
        min(max(m, 0), 24 * 60)
    }

    private func applyMagnet(_ duration: Int) -> Int {
        if abs(duration - 30) <= magnet30Tolerance { return 30 }
        if abs(duration - 60) <= magnet60Tolerance { return 60 }
        return duration
    }

    private func snap(_ minutes: Int, step: Int) -> Int {
        guard step > 0 else { return minutes }
        return Int((Double(minutes) / Double(step)).rounded()) * step
    }

    private static let tf: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df
    }()

    private func timeRangeText(_ s: Date, _ e: Date) -> String {
        "\(Self.tf.string(from: s)) – \(Self.tf.string(from: e))"
    }
}

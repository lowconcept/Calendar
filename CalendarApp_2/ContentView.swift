//
//  ContentView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

struct DayPagerView: View {
    let dates: [Date]
    @State private var scrollOffsetsByDayIndex: [Int: CGFloat] = [:]
    @State private var selectedIndex: Int = 0

    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                DayTimelineView(
                    date: date,
                    preservedScrollOffsetY: scrollOffsetBinding(for: index)
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func scrollOffsetBinding(for index: Int) -> Binding<CGFloat> {
        Binding(
            get: { scrollOffsetsByDayIndex[index, default: 0] },
            set: { scrollOffsetsByDayIndex[index] = $0 }
        )
    }
}

struct DayTimelineView: View {
    let date: Date
    @Binding var preservedScrollOffsetY: CGFloat

    var body: some View {
        TimelineScrollView(offsetY: $preservedScrollOffsetY) {
            VStack(alignment: .leading, spacing: 16) {
                Text(date, style: .date)
                    .font(.headline)
                ForEach(0..<24, id: \.self) { hour in
                    HStack {
                        Text(String(format: "%02d:00", hour))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Divider()
                    }
                    .frame(height: 44)
                }
            }
            .padding()
        }
    }
}

struct TimelineScrollView<Content: View>: UIViewRepresentable {
    @Binding var offsetY: CGFloat
    private let content: Content

    init(offsetY: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        _offsetY = offsetY
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        scrollView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        context.coordinator.hostingController = hostingController
        scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let hostingController = context.coordinator.hostingController {
            hostingController.rootView = content
        }

        let currentOffset = uiView.contentOffset.y
        if abs(currentOffset - offsetY) > 1 {
            uiView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: TimelineScrollView
        var hostingController: UIHostingController<Content>?

        init(parent: TimelineScrollView) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.offsetY = scrollView.contentOffset.y
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

#Preview {
    DayPagerView(dates: [Date(), Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()])
}

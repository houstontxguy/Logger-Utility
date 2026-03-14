import Foundation
import Combine
import SwiftUI

@MainActor
final class StreamViewModel: ObservableObject {
    @Published var entries: [LogEntry] = []
    @Published var filter = LogFilter()
    @Published var isPaused = false
    @Published var isRunning = false
    @Published var errorMessage: String?
    @Published var entryCount = 0
    @Published var entriesPerSecond = 0.0
    @Published var searchText = ""
    @Published var selectedEntry: LogEntry?
    @Published var discoveredSubsystems: [(name: String, count: Int)] = []

    private var subsystemCounts: [String: Int] = [:]
    private let streamService = LogStreamService()
    private var ringBuffer = RingBuffer<LogEntry>(capacity: Constants.defaultStreamBufferCapacity)
    private var cancellables = Set<AnyCancellable>()
    private var rateCounter = 0
    private var rateTimer: Timer?

    init() {
        streamService.entryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] batch in
                self?.handleBatch(batch)
            }
            .store(in: &cancellables)

        streamService.$isRunning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRunning)

        streamService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }

    deinit {
        rateTimer?.invalidate()
    }

    func start() {
        ringBuffer.clear()
        entries = []
        entryCount = 0
        entriesPerSecond = 0
        rateCounter = 0
        isPaused = false
        selectedEntry = nil
        subsystemCounts = [:]
        discoveredSubsystems = []

        startRateTimer()
        streamService.start(filter: filter)
    }

    func stop() {
        streamService.stop()
        rateTimer?.invalidate()
        rateTimer = nil
        entriesPerSecond = 0
    }

    func togglePause() {
        isPaused.toggle()
        if !isPaused {
            rebuildFilteredEntries()
        }
    }

    func clear() {
        ringBuffer.clear()
        entries = []
        entryCount = 0
        selectedEntry = nil
    }

    private func handleBatch(_ batch: [LogEntry]) {
        ringBuffer.append(contentsOf: batch)
        entryCount = ringBuffer.count
        rateCounter += batch.count

        for entry in batch where !entry.subsystem.isEmpty {
            subsystemCounts[entry.subsystem, default: 0] += 1
        }
        // Rebuild subsystem list every 5 seconds worth of batches (throttled via rate timer)
        // or just keep it in sync — it's a dictionary sort, cheap enough
        discoveredSubsystems = subsystemCounts
            .sorted { $0.value > $1.value }
            .map { (name: $0.key, count: $0.value) }

        if !isPaused {
            rebuildFilteredEntries()
        }
    }

    private func rebuildFilteredEntries() {
        let source = ringBuffer.toArray()
        var result = source

        if !filter.selectedLevels.isEmpty && filter.selectedLevels.count < LogLevel.allCases.count {
            result = result.filter { filter.selectedLevels.contains($0.logLevel) }
        }

        if !searchText.isEmpty {
            let search = searchText
            result = result.filter {
                $0.eventMessage.localizedCaseInsensitiveContains(search) ||
                $0.processName.localizedCaseInsensitiveContains(search) ||
                $0.subsystem.localizedCaseInsensitiveContains(search) ||
                $0.category.localizedCaseInsensitiveContains(search)
            }
        }

        entries = result
    }

    private func startRateTimer() {
        rateTimer?.invalidate()
        rateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.entriesPerSecond = Double(self.rateCounter)
                self.rateCounter = 0
            }
        }
    }
}

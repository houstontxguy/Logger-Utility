# Logger Utility

A native macOS app for viewing unified system logs. Built with SwiftUI, it wraps the `log` CLI tool to provide real-time streaming, historical queries, filtering, and export — all in a performant GUI designed for Mac technicians.

## Features

- **Real-time log streaming** — Live view of system logs via `log stream` with pause/resume and auto-scroll
- **Historical queries** — Search past logs with arbitrary date ranges and quick shortcuts (5m, 15m, 1h, 24h)
- **Advanced filtering** — Filter by process, subsystem, category, sender, log level, and custom predicates
- **Visual predicate builder** — Build complex `log` predicates with a point-and-click UI (supports ==, !=, CONTAINS, BEGINSWITH, ENDSWITH, LIKE, MATCHES)
- **Subsystem presets** — Quick-select from 18 common macOS subsystems (Bluetooth, Wi-Fi, MDM, kernel, etc.)
- **High-performance table** — NSTableView handles 100K+ log entries with fixed row heights and cell reuse
- **Log detail inspector** — Side panel showing all fields for the selected log entry
- **Export** — Save logs as CSV, plain text, or .logarchive
- **Keyboard shortcuts** — Cmd+K (clear), Cmd+F (search), Cmd+E (export)

## Requirements

- macOS 13 Ventura or later
- Xcode 15+ (to build)
- Full Disk Access recommended for complete log visibility

## Building

```bash
# Clone and build
git clone https://github.com/houstontxguy/Logger-Utility.git
cd Logger-Utility
swift build

# Run
swift run

# Run tests
swift test
```

Or open `Package.swift` in Xcode and press Cmd+R.

## Architecture

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI + NSTableView (via NSViewRepresentable) |
| Data flow | MVVM + Combine |
| Log access | `Process` shelling out to `/usr/bin/log` with NDJSON parsing |
| Package | Swift Package Manager (no third-party dependencies) |

### How streaming works

1. `LogStreamService` launches `log stream --style ndjson` via `Process`
2. Stdout is read via `FileHandle.readabilityHandler` on a background queue
3. NDJSON lines are parsed with `JSONSerialization` (faster than `JSONDecoder` for flat objects)
4. Entries are batched every 100ms via Combine and published to the UI
5. A `RingBuffer` caps the in-memory store at 100,000 entries

### Project structure

```
Sources/LoggerUtility/
├── App/            — Entry point, app state
├── Models/         — LogEntry, LogLevel, LogFilter, PredicateClause, etc.
├── Services/       — LogStreamService, LogShowService, LogParser, ExportService
├── ViewModels/     — StreamViewModel, HistoricalViewModel, FilterViewModel
├── Views/          — SwiftUI views (Stream, Historical, Shared, Components)
├── Utilities/      — RingBuffer, DateFormatting, Constants
└── Extensions/     — Color+LogLevel, Process+Async, String+Predicate
```

## Usage

### Stream tab
1. Click **Start** to begin streaming logs
2. Use the **Search** field to filter visible entries
3. Click **Filters** to open the filter sidebar for subsystem/process/level filtering
4. Click any row to see full details in the inspector panel
5. **Pause** freezes the display while the buffer continues filling

### Historical tab
1. Select a time range using the quick buttons (5m, 15m, 1h, 24h) or the date pickers
2. Click **Query** to fetch logs for that period
3. Results can be searched and filtered the same as the stream tab

### Predicate builder
The filter panel includes a visual predicate builder. Add clauses with field/operator/value, choose AND/OR joining, or type a raw predicate string for full control.

## Distribution

This app requires access to system logs and **cannot run in a sandbox**. Distribute via:
- Developer ID signing (notarized for Gatekeeper)
- MDM deployment
- Direct distribution (users must allow in System Settings > Privacy & Security)

## License

MIT

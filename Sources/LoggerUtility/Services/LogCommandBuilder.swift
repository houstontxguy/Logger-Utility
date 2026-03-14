import Foundation

enum LogCommandBuilder {
    static func buildStreamArguments(from filter: LogFilter) -> [String] {
        var args = ["stream", "--style", "ndjson"]

        if filter.includeInfo {
            args.append("--info")
        }
        if filter.includeDebug {
            args.append("--debug")
        }
        if filter.includeSource {
            args.append("--source")
        }

        let predicate = filter.effectivePredicate
        if !predicate.isEmpty {
            args.append("--predicate")
            args.append(predicate)
        }

        return args
    }

    static func buildShowArguments(from filter: LogFilter) -> [String] {
        var args = ["show", "--style", "ndjson"]

        if filter.includeInfo {
            args.append("--info")
        }
        if filter.includeDebug {
            args.append("--debug")
        }
        if filter.includeSource {
            args.append("--source")
        }

        if let startDate = filter.startDate {
            args.append("--start")
            args.append(DateFormatting.commandString(from: startDate))
        }
        if let endDate = filter.endDate {
            args.append("--end")
            args.append(DateFormatting.commandString(from: endDate))
        }

        let predicate = filter.effectivePredicate
        if !predicate.isEmpty {
            args.append("--predicate")
            args.append(predicate)
        }

        return args
    }

    static func buildCollectArguments(outputPath: String, lastDuration: String? = nil, startDate: Date? = nil) -> [String] {
        var args = ["collect", "--output", outputPath]

        if let duration = lastDuration {
            args.append("--last")
            args.append(duration)
        } else if let start = startDate {
            args.append("--start")
            args.append(DateFormatting.commandString(from: start))
        }

        return args
    }
}

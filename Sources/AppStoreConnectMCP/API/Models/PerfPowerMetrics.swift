import Foundation

// The perfPowerMetrics endpoints return custom JSON, not JSON:API.

struct PerfPowerMetricsResponse: Decodable, Sendable {
    let productData: [MetricProductData]?

    struct MetricProductData: Decodable, Sendable {
        let metricCategories: [MetricCategory]?
        let platform: String?
    }
}

/// Goal can be a numeric threshold or a symbolic key like "fair".
enum MetricGoal: Decodable, Sendable {
    case numeric(Double)
    case symbolic(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            self = .numeric(value)
        } else if let value = try? container.decode(String.self) {
            self = .symbolic(value)
        } else {
            throw DecodingError.typeMismatch(
                MetricGoal.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected Double or String for goal")
            )
        }
    }

    var displayString: String {
        switch self {
        case .numeric(let v): String(format: "%.2f", v)
        case .symbolic(let s): s
        }
    }
}

struct MetricCategory: Decodable, Sendable {
    let identifier: String?
    let metrics: [PerfPowerMetric]?
}

struct PerfPowerMetric: Decodable, Sendable {
    let identifier: String?
    let unit: MetricUnit?
    let datasets: [MetricDataset]?

    struct MetricUnit: Decodable, Sendable {
        let identifier: String?
        let displayName: String?
    }

    struct MetricDataset: Decodable, Sendable {
        let filterCriteria: FilterCriteria?
        let points: [DataPoint]?

        struct FilterCriteria: Decodable, Sendable {
            let device: String?
            let deviceMarketingName: String?
            let percentile: String?
        }

        struct DataPoint: Decodable, Sendable {
            let version: String?
            let value: Double?
            let goal: MetricGoal?
            let percentageBreakdown: [PercentageBreakdown]?

            struct PercentageBreakdown: Decodable, Sendable {
                let value: Double?
                let subSystemLabel: String?
            }
        }
    }
}

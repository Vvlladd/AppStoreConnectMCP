import Foundation

// The perfPowerMetrics endpoints return custom JSON, not JSON:API.

struct PerfPowerMetricsResponse: Decodable, Sendable {
    let productData: [MetricProductData]?

    struct MetricProductData: Decodable, Sendable {
        let metricCategories: [MetricCategory]?
        let platform: String?
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
            let goal: Double?
            let percentageBreakdown: PercentageBreakdown?

            struct PercentageBreakdown: Decodable, Sendable {
                let value: Double?
                let subSystemLabel: String?
            }
        }
    }
}

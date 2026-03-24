import Foundation
import MCP

struct GetPerfMetricsHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }

        let appID: String? = if case .string(let v) = args["app_id"] { v } else { nil }
        let buildID: String? = if case .string(let v) = args["build_id"] { v } else { nil }

        guard appID != nil || buildID != nil else {
            throw AppStoreConnectError.invalidArgument("Either app_id or build_id is required")
        }

        let metricType: String? = if case .string(let v) = args["metric_type"] { v } else { nil }
        let platform: String? = if case .string(let v) = args["platform"] { v } else { nil }

        let url: URL
        if let buildID {
            url = Endpoints.perfPowerMetricsForBuild(buildID: buildID, metricType: metricType, platform: platform)
        } else {
            url = Endpoints.perfPowerMetricsForApp(appID: appID!, metricType: metricType, platform: platform)
        }

        let response = try await client.get(url, as: PerfPowerMetricsResponse.self)

        var output = ""
        guard let productData = response.productData, !productData.isEmpty else {
            return CallTool.Result(content: [.text("No performance metrics found.")])
        }

        for product in productData {
            if let platform = product.platform {
                output += "Platform: \(platform)\n"
            }
            guard let categories = product.metricCategories else { continue }

            for category in categories {
                output += "\n[\(category.identifier ?? "?")]\n"
                guard let metrics = category.metrics else { continue }

                for metric in metrics {
                    let name = metric.identifier ?? "?"
                    let unit = metric.unit?.displayName ?? metric.unit?.identifier ?? ""
                    output += "  \(name) (\(unit)):\n"

                    guard let datasets = metric.datasets else { continue }
                    for dataset in datasets {
                        let device = dataset.filterCriteria?.deviceMarketingName
                            ?? dataset.filterCriteria?.device ?? "all"
                        let percentile = dataset.filterCriteria?.percentile ?? ""
                        let percentileLabel = percentile.isEmpty ? "" : " p\(percentile)"

                        guard let points = dataset.points else { continue }
                        for point in points {
                            let version = point.version ?? "?"
                            let value = point.value.map { String(format: "%.2f", $0) } ?? "?"
                            let goalInfo = point.goal.map { String(format: " (goal: %.2f)", $0) } ?? ""
                            output += "    \(device)\(percentileLabel): v\(version) = \(value) \(unit)\(goalInfo)\n"
                        }
                    }
                }
            }
        }

        if output.isEmpty {
            output = "No performance metrics found."
        }

        return CallTool.Result(content: [.text(output)])
    }
}

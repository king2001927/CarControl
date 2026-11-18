import Foundation
import CoreLocation

/// 车辆数据源错误
enum VehicleError: LocalizedError {
    case notConfigured
    case tokenFormat
    case vinFormat
    case http(Int)
    case invalidResponse
    case geocodeFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "请先在「设置 › 车辆数据源」填写车架号和 ACCESS_TOKEN"
        case .tokenFormat:
            return "ACCESS_TOKEN 格式不正确（应以 -prod_SAIC 结尾）"
        case .vinFormat:
            return "车架号应为 17 位字符"
        case .http(let code):
            return "云端接口返回错误（HTTP \(code)），令牌可能已过期"
        case .invalidResponse:
            return "云端返回数据不完整"
        case .geocodeFailed:
            return "位置解析失败"
        }
    }
}

// MARK: - 上汽云端响应模型
// 字段与 MG Linker（Apache-2.0）公开的 getVehicleStatus 返回结构对应，
// 仅声明本项目用到的字段，其余字段由 JSONDecoder 自动忽略。

struct SaiStatusResponse: Decodable {
    let reqId: String?
    let data: SaiVehicleData?
}

struct SaiVehicleData: Decodable {
    let vehiclePosition: SaiVehiclePosition?
    let vehicleValue: SaiVehicleValue?
    let vehicleState: SaiVehicleState?
    let updateTime: Int64?
}

struct SaiVehiclePosition: Decodable {
    let latitude: String?
    let longitude: String?
    let gpsStatus: Int?
    let updateTime: Int64?
}

struct SaiVehicleValue: Decodable {
    let batteryPackPrc: Int?
    let batteryPackRange: Int?
    let drivingRange: Int?
    let fuelLevelPrc: Int?
    let fuelRange: Int?
    let odometer: Int?
    let interiorTemperature: Double?
    let exteriorTemperature: Int?
    let frontLeftTyrePressure: Int?
    let frontRightTyrePressure: Int?
    let rearLeftTyrePressure: Int?
    let rearRightTyrePressure: Int?
    let chargeStatus: Int?
    let chrgngRmnngTime: Int?
    let vehicleBattery: Int?
    let speed: Int?
    let bmsChargeStatus: Int?
}

struct SaiVehicleState: Decodable {
    let lock: Bool?
    let door: Bool?
    let driverDoor: Bool?
    let passengerDoor: Bool?
    let rearLeftDoor: Bool?
    let rearRightDoor: Bool?
    let boot: Bool?
    let window: Bool?
    let sunroof: Bool?
    let climate: Bool?
    let charge: Bool?
    let light: Bool?
    let engine: Bool?
    let bonnet: Bool?
}

// MARK: - 上汽云端数据源

/// 真实车况数据源：调用上汽斑马车联云端接口。
/// 接口与凭证方式参考 MG Linker（Apache-2.0）：
///   GET https://mp.ebanma.com/app-mp/vp/1.1/getVehicleStatus?timestamp={秒}&token={token}&vin={vin}
/// token 为用户从官方 App 抓包获得、以 -prod_SAIC 结尾的访问令牌。
final class SaiCloudVehicleService: VehicleService {
    private static let endpoint = "https://mp.ebanma.com/app-mp/vp/1.1/getVehicleStatus"

    let vin: String
    let token: String

    init(vin: String, token: String) {
        self.vin = vin
        self.token = token
    }

    func refresh() async throws -> VehicleStatusSnapshot {
        guard vin.count == 17 else { throw VehicleError.vinFormat }
        guard token.hasSuffix("-prod_SAIC") else { throw VehicleError.tokenFormat }

        let timestamp = Int(Date().timeIntervalSince1970)
        var components = URLComponents(string: Self.endpoint)!
        components.queryItems = [
            URLQueryItem(name: "timestamp", value: String(timestamp)),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "vin", value: vin),
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 20
        request.setValue("CarControl/0.2", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw VehicleError.invalidResponse }
        guard http.statusCode == 200 else { throw VehicleError.http(http.statusCode) }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let payload = try decoder.decode(SaiStatusResponse.self, from: data)
        guard let vehicle = payload.data else { throw VehicleError.invalidResponse }

        let value = vehicle.vehicleValue
        let state = vehicle.vehicleState

        let battery = value?.batteryPackPrc
        let fuel = value?.fuelLevelPrc
        let displayLevel = battery ?? fuel ?? 0
        let range = value?.drivingRange ?? value?.batteryPackRange ?? value?.fuelRange ?? 0

        var snapshot = VehicleStatusSnapshot()
        snapshot.batteryPercent = displayLevel
        snapshot.rangeKm = range
        snapshot.locked = state?.lock ?? true
        snapshot.fuelLevelPrc = fuel
        snapshot.fuelRange = value?.fuelRange
        snapshot.batteryPackPrc = battery
        snapshot.batteryPackRange = value?.batteryPackRange
        snapshot.drivingRange = value?.drivingRange
        snapshot.odometer = value?.odometer
        snapshot.interiorTemperature = value?.interiorTemperature
        snapshot.exteriorTemperature = value?.exteriorTemperature
        snapshot.vehicleBatteryVoltage = value?.vehicleBattery
        snapshot.chargeStatus = value?.chargeStatus
        snapshot.chargeRemainingTime = value?.chrgngRmnngTime
        snapshot.frontLeftTyrePressure = value?.frontLeftTyrePressure
        snapshot.frontRightTyrePressure = value?.frontRightTyrePressure
        snapshot.rearLeftTyrePressure = value?.rearLeftTyrePressure
        snapshot.rearRightTyrePressure = value?.rearRightTyrePressure
        snapshot.anyDoorOpen = state?.door
        snapshot.bootOpen = state?.boot
        snapshot.windowOpen = state?.window
        snapshot.sunroofOpen = state?.sunroof
        snapshot.climateOn = state?.climate
        snapshot.charging = state?.charge ?? (value?.chargeStatus == 1)
        snapshot.lightOn = state?.light
        snapshot.engineOn = state?.engine
        snapshot.dataSource = "上汽云端"

        if let latText = vehicle.vehiclePosition?.latitude,
           let lonText = vehicle.vehiclePosition?.longitude,
           let lat = Double(latText), let lon = Double(lonText) {
            snapshot.latitude = lat
            snapshot.longitude = lon
        }
        snapshot.address = await Self.reverseGeocode(
            lat: snapshot.latitude, lon: snapshot.longitude
        )
        snapshot.updatedAt = Date()

        return snapshot
    }

    /// 逆地理编码：坐标 → 中文地址（失败时退回坐标文本）
    private static func reverseGeocode(lat: Double?, lon: Double?) async -> String {
        guard let lat, let lon else { return "暂无位置" }
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(
                CLLocation(latitude: lat, longitude: lon)
            )
            if let place = placemarks.first {
                let parts = [
                    place.name,
                    place.locality,
                    place.subLocality,
                    place.thoroughfare,
                ].compactMap { $0 }.filter { !$0.isEmpty }
                if !parts.isEmpty { return parts.joined(separator: " ") }
            }
            return String(format: "%.5f, %.5f", lat, lon)
        } catch {
            return String(format: "%.5f, %.5f", lat, lon)
        }
    }
}

// MARK: - 数据源工厂

/// 车辆数据源选项
enum VehicleDataSource: String, CaseIterable, Identifiable {
    case demo = "演示数据"
    case saiCloud = "上汽云端"

    var id: String { rawValue }
}

/// 根据设置里的配置选择当前数据源。
enum VehicleServiceFactory {
    static let sourceKey = "vehicle.source"
    static let vinKey = "vehicle.vin"
    static let tokenKey = "vehicle.token"

    static func current() -> any VehicleService {
        let saved = UserDefaults.standard.string(forKey: sourceKey) ?? ""
        let source = VehicleDataSource(rawValue: saved) ?? .demo
        switch source {
        case .demo:
            return MockVehicleService()
        case .saiCloud:
            let vin = UserDefaults.standard.string(forKey: vinKey) ?? ""
            let token = UserDefaults.standard.string(forKey: tokenKey) ?? ""
            if vin.count == 17 && token.hasSuffix("-prod_SAIC") {
                return SaiCloudVehicleService(vin: vin, token: token)
            }
            // 云端凭证未配置完整时，抛错由 UI 提示，而不是静默退回演示
            return UnconfiguredVehicleService()
        }
    }
}

/// 未配置完成时的占位数据源：让 UI 明确提示用户去配置
final class UnconfiguredVehicleService: VehicleService {
    func refresh() async throws -> VehicleStatusSnapshot {
        throw VehicleError.notConfigured
    }
}

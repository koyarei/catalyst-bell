import CoreLocation
import Foundation

@MainActor
final class LocationProvider: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CoarseLocation?, Never>?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestOneCoarseLocationIfAllowed(enabled: Bool) async -> CoarseLocation? {
        guard enabled else {
            return nil
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            return CoarseLocation.notRequested
        case .restricted, .denied:
            return CoarseLocation.denied
        case .authorizedAlways, .authorizedWhenInUse:
            return await requestLocationWithTimeout()
        @unknown default:
            return CoarseLocation.unavailable
        }
    }

    private func requestLocationWithTimeout() async -> CoarseLocation? {
        await withTaskGroup(of: CoarseLocation?.self) { group in
            group.addTask { @MainActor in
                await withCheckedContinuation { continuation in
                    self.continuation = continuation
                    self.manager.requestLocation()
                }
            }

            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return CoarseLocation.unavailable
            }

            let result = await group.next() ?? CoarseLocation.unavailable
            group.cancelAll()
            return result
        }
    }

    private func finish(with location: CoarseLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latest = locations.last
        Task { @MainActor in
            guard let latest else {
                finish(with: .unavailable)
                return
            }

            finish(with: CoarseLocation(
                permissionStatus: .allowed,
                granularity: .coarseRoundedCoordinate,
                latitudeRounded: latest.coordinate.latitude.roundedToTwoPlaces,
                longitudeRounded: latest.coordinate.longitude.roundedToTwoPlaces,
                locality: nil,
                administrativeArea: nil,
                countryCode: nil
            ))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            finish(with: .unavailable)
        }
    }
}

private extension CoarseLocation {
    static let notRequested = CoarseLocation(permissionStatus: .notRequested, granularity: .none, latitudeRounded: nil, longitudeRounded: nil, locality: nil, administrativeArea: nil, countryCode: nil)
    static let denied = CoarseLocation(permissionStatus: .denied, granularity: .none, latitudeRounded: nil, longitudeRounded: nil, locality: nil, administrativeArea: nil, countryCode: nil)
    static let unavailable = CoarseLocation(permissionStatus: .unavailable, granularity: .none, latitudeRounded: nil, longitudeRounded: nil, locality: nil, administrativeArea: nil, countryCode: nil)
}

private extension Double {
    var roundedToTwoPlaces: Double {
        (self * 100).rounded() / 100
    }
}

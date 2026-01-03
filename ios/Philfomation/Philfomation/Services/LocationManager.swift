//
//  LocationManager.swift
//  Philfomation
//

import Foundation
import CoreLocation
import Combine

// MARK: - Location Authorization Status
enum LocationAuthStatus {
    case notDetermined
    case restricted
    case denied
    case authorizedWhenInUse
    case authorizedAlways

    var isAuthorized: Bool {
        self == .authorizedWhenInUse || self == .authorizedAlways
    }

    var message: String {
        switch self {
        case .notDetermined:
            return "위치 권한이 필요합니다"
        case .restricted:
            return "위치 서비스가 제한되어 있습니다"
        case .denied:
            return "위치 권한이 거부되었습니다. 설정에서 활성화해주세요."
        case .authorizedWhenInUse, .authorizedAlways:
            return "위치 서비스가 활성화되어 있습니다"
        }
    }
}

// MARK: - Location Manager
@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: LocationAuthStatus = .notDetermined
    @Published var isUpdatingLocation = false
    @Published var lastError: Error?
    @Published var heading: CLHeading?

    private let locationManager = CLLocationManager()
    private var locationUpdateHandler: ((CLLocation) -> Void)?

    // Manila default location (for when location is unavailable)
    static let defaultLocation = CLLocation(latitude: 14.5995, longitude: 120.9842)

    // Distance thresholds
    static let nearbyDistance: CLLocationDistance = 5000 // 5km
    static let veryNearDistance: CLLocationDistance = 1000 // 1km

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update every 50 meters
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    private func updateAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .restricted:
            authorizationStatus = .restricted
        case .denied:
            authorizationStatus = .denied
        case .authorizedWhenInUse:
            authorizationStatus = .authorizedWhenInUse
        case .authorizedAlways:
            authorizationStatus = .authorizedAlways
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    // MARK: - Location Updates

    func startUpdatingLocation() {
        guard authorizationStatus.isAuthorized else {
            requestAuthorization()
            return
        }

        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }

    func requestOneTimeLocation(completion: ((CLLocation?) -> Void)? = nil) {
        locationUpdateHandler = completion

        if authorizationStatus.isAuthorized {
            locationManager.requestLocation()
        } else {
            requestAuthorization()
        }
    }

    // MARK: - Heading Updates

    func startUpdatingHeading() {
        guard CLLocationManager.headingAvailable() else { return }
        locationManager.startUpdatingHeading()
    }

    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }

    // MARK: - Distance Calculations

    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }

    func distance(to business: Business) -> CLLocationDistance? {
        guard let coordinate = business.coordinate else { return nil }
        return distance(to: coordinate)
    }

    func formattedDistance(to business: Business) -> String? {
        guard let distance = distance(to: business) else { return nil }
        return formatDistance(distance)
    }

    func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }

    // MARK: - Sorting & Filtering

    func sortByDistance(_ businesses: [Business]) -> [Business] {
        guard currentLocation != nil else { return businesses }

        return businesses.sorted { business1, business2 in
            let distance1 = distance(to: business1) ?? .infinity
            let distance2 = distance(to: business2) ?? .infinity
            return distance1 < distance2
        }
    }

    func filterNearby(_ businesses: [Business], within distance: CLLocationDistance = nearbyDistance) -> [Business] {
        guard currentLocation != nil else { return businesses }

        return businesses.filter { business in
            guard let businessDistance = self.distance(to: business) else { return true }
            return businessDistance <= distance
        }
    }

    func businessesWithDistance(_ businesses: [Business]) -> [(business: Business, distance: CLLocationDistance?)] {
        return businesses.map { business in
            (business: business, distance: distance(to: business))
        }
    }

    // MARK: - Region Monitoring

    func isNearby(_ business: Business, within radius: CLLocationDistance = nearbyDistance) -> Bool {
        guard let distance = distance(to: business) else { return false }
        return distance <= radius
    }

    func isVeryNear(_ business: Business) -> Bool {
        isNearby(business, within: Self.veryNearDistance)
    }

    // MARK: - Open Maps

    func openInMaps(business: Business) {
        guard let coordinate = business.coordinate else { return }
        openInMaps(coordinate: coordinate, name: business.name)
    }

    func openInMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let urlString = "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)&q=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    func openInGoogleMaps(business: Business) {
        guard let coordinate = business.coordinate else { return }
        let urlString = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to web
            let webUrlString = "https://www.google.com/maps/dir/?api=1&destination=\(coordinate.latitude),\(coordinate.longitude)"
            if let webUrl = URL(string: webUrlString) {
                UIApplication.shared.open(webUrl)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            self.lastError = nil
            self.locationUpdateHandler?(location)
            self.locationUpdateHandler = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error
            self.locationUpdateHandler?(Self.defaultLocation)
            self.locationUpdateHandler = nil
            print("Location error: \(error.localizedDescription)")
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.updateAuthorizationStatus()

            if self.authorizationStatus.isAuthorized {
                self.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            self.heading = newHeading
        }
    }
}

// MARK: - Business Extension for Distance
extension Business {
    func distance(from location: CLLocation) -> CLLocationDistance? {
        guard let coordinate = self.coordinate else { return nil }
        let businessLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: businessLocation)
    }

    func formattedDistance(from location: CLLocation) -> String? {
        guard let distance = distance(from: location) else { return nil }
        return LocationManager.shared.formatDistance(distance)
    }
}

// MARK: - Location Permission View
import SwiftUI

struct LocationPermissionView: View {
    @ObservedObject var locationManager = LocationManager.shared
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color(hex: "2563EB"))

            VStack(spacing: 12) {
                Text("주변 업소 찾기")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("현재 위치를 기반으로\n가까운 업소를 찾아보세요")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    locationManager.requestAuthorization()
                } label: {
                    Text("위치 권한 허용")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "2563EB"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onContinue()
                } label: {
                    Text("나중에 하기")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Location Status Badge
struct LocationStatusBadge: View {
    @ObservedObject var locationManager = LocationManager.shared

    var body: some View {
        HStack(spacing: 4) {
            if locationManager.authorizationStatus.isAuthorized {
                if locationManager.currentLocation != nil {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.green)
                    Text("위치 활성화")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "location")
                        .foregroundStyle(.orange)
                    Text("위치 확인 중...")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            } else {
                Image(systemName: "location.slash")
                    .foregroundStyle(.red)
                Text("위치 비활성화")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

// MARK: - Distance Badge
struct DistanceBadge: View {
    let business: Business
    @ObservedObject var locationManager = LocationManager.shared

    var body: some View {
        if let distance = locationManager.formattedDistance(to: business) {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                Text(distance)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color(hex: "2563EB"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "2563EB").opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Nearby Businesses Section
struct NearbyBusinessesSection: View {
    let businesses: [Business]
    @ObservedObject var locationManager = LocationManager.shared

    var nearbyBusinesses: [Business] {
        locationManager.sortByDistance(
            locationManager.filterNearby(businesses)
        ).prefix(5).map { $0 }
    }

    var body: some View {
        if locationManager.authorizationStatus.isAuthorized && !nearbyBusinesses.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Color(hex: "2563EB"))
                    Text("내 주변 업소")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(nearbyBusinesses) { business in
                            NearbyBusinessCard(business: business)
                        }
                    }
                }
            }
        }
    }
}

struct NearbyBusinessCard: View {
    let business: Business
    @ObservedObject var locationManager = LocationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo
            if let photo = business.photos.first {
                CachedAsyncImage(url: photo) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 140, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        Image(systemName: business.category.icon)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(business.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let distance = locationManager.formattedDistance(to: business) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(distance)
                            .font(.caption)
                    }

                    Spacer()

                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(String(format: "%.1f", business.rating))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .frame(width: 140)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

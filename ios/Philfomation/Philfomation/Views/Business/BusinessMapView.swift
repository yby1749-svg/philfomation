//
//  BusinessMapView.swift
//  Philfomation
//

import SwiftUI
import MapKit
import Combine

struct BusinessMapView: View {
    @EnvironmentObject var viewModel: BusinessViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var selectedBusiness: Business?
    @State private var showBusinessDetail = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 14.5995, longitude: 120.9842), // Manila
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: businessesWithCoordinates) { business in
                MapAnnotation(coordinate: business.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)) {
                    Button {
                        selectedBusiness = business
                    } label: {
                        BusinessMarker(business: business, isSelected: selectedBusiness?.id == business.id)
                    }
                }
            }

            // Selected business card
            if let business = selectedBusiness {
                BusinessMapCard(business: business) {
                    showBusinessDetail = true
                }
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showBusinessDetail) {
            if let business = selectedBusiness {
                NavigationStack {
                    BusinessDetailView(business: business)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            centerOnUserLocation()
        }
    }

    private var businessesWithCoordinates: [Business] {
        viewModel.filteredBusinesses.filter { $0.coordinate != nil }
    }

    private func centerOnUserLocation() {
        if let location = locationManager.userLocation {
            region = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}

// MARK: - Business Marker
struct BusinessMarker: View {
    let business: Business
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: "2563EB") : .white)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                Image(systemName: business.category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? .white : Color(hex: "2563EB"))
            }

            // Arrow
            Triangle()
                .fill(isSelected ? Color(hex: "2563EB") : .white)
                .frame(width: 12, height: 8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Business Map Card
struct BusinessMapCard: View {
    let business: Business
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category Icon
                Image(systemName: business.category.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color(hex: "2563EB").gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(business.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(Color(hex: "2563EB"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "2563EB").opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Text(business.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", business.rating))
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("(\(business.reviewCount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(business.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location.coordinate
        }
    }
}

#Preview {
    BusinessMapView()
        .environmentObject(BusinessViewModel())
}

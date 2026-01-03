//
//  BusinessMapView.swift
//  Philfomation
//

import SwiftUI
import MapKit
import Combine

struct BusinessMapView: View {
    @EnvironmentObject var viewModel: BusinessViewModel
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var selectedBusiness: Business?
    @State private var showBusinessDetail = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 14.5995, longitude: 120.9842), // Manila
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var showDirectionsSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: businessesWithCoordinates) { business in
                MapAnnotation(coordinate: business.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedBusiness = business
                        }
                        HapticManager.shared.selectionChanged()
                    } label: {
                        BusinessMarker(business: business, isSelected: selectedBusiness?.id == business.id)
                    }
                }
            }

            VStack(spacing: 12) {
                // Map Controls
                HStack {
                    Spacer()

                    VStack(spacing: 8) {
                        // Center on user location
                        Button {
                            centerOnUserLocation()
                            HapticManager.shared.lightImpactOccurred()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundStyle(locationManager.currentLocation != nil ? Color(hex: "2563EB") : .secondary)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4)
                        }

                        // Zoom to fit all
                        Button {
                            zoomToFitAll()
                            HapticManager.shared.lightImpactOccurred()
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.title3)
                                .foregroundStyle(Color(hex: "2563EB"))
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4)
                        }
                    }
                    .padding(.trailing, 16)
                }

                Spacer()

                // Selected business card
                if let business = selectedBusiness {
                    BusinessMapCard(business: business, onTap: {
                        showBusinessDetail = true
                    }, onDirections: {
                        showDirectionsSheet = true
                    })
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
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
        .confirmationDialog("길찾기", isPresented: $showDirectionsSheet, titleVisibility: .visible) {
            if let business = selectedBusiness {
                Button("Apple 지도") {
                    locationManager.openInMaps(business: business)
                }
                Button("Google 지도") {
                    locationManager.openInGoogleMaps(business: business)
                }
                Button("취소", role: .cancel) {}
            }
        }
        .onAppear {
            if !locationManager.authorizationStatus.isAuthorized {
                locationManager.requestAuthorization()
            }
            locationManager.startUpdatingLocation()
            centerOnUserLocation()
        }
    }

    private var businessesWithCoordinates: [Business] {
        viewModel.filteredBusinesses.filter { $0.coordinate != nil }
    }

    private func centerOnUserLocation() {
        if let location = locationManager.currentLocation {
            withAnimation(.easeInOut(duration: 0.5)) {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }

    private func zoomToFitAll() {
        let businesses = businessesWithCoordinates
        guard !businesses.isEmpty else { return }

        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLng = Double.infinity
        var maxLng = -Double.infinity

        for business in businesses {
            if let coord = business.coordinate {
                minLat = min(minLat, coord.latitude)
                maxLat = max(maxLat, coord.latitude)
                minLng = min(minLng, coord.longitude)
                maxLng = max(maxLng, coord.longitude)
            }
        }

        // Include user location if available
        if let userLocation = locationManager.currentLocation {
            minLat = min(minLat, userLocation.coordinate.latitude)
            maxLat = max(maxLat, userLocation.coordinate.latitude)
            minLng = min(minLng, userLocation.coordinate.longitude)
            maxLng = max(maxLng, userLocation.coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLng - minLng) * 1.3
        )

        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(center: center, span: span)
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
    var onDirections: (() -> Void)? = nil
    @ObservedObject private var locationManager = LocationManager.shared

    var body: some View {
        VStack(spacing: 0) {
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

                            if let distance = locationManager.formattedDistance(to: business) {
                                HStack(spacing: 2) {
                                    Image(systemName: "location.fill")
                                        .font(.caption2)
                                    Text(distance)
                                        .font(.caption)
                                }
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Capsule())
                            }
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
            }
            .buttonStyle(.plain)

            // Directions Button
            if business.coordinate != nil, let onDirections = onDirections {
                Divider()

                Button(action: onDirections) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .foregroundStyle(Color(hex: "2563EB"))
                        Text("길찾기")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color(hex: "2563EB"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    BusinessMapView()
        .environmentObject(BusinessViewModel())
}

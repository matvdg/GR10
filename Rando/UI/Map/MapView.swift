//
//  MapView.swift
//  Rando
//
//  Created by Mathieu Vandeginste on 02/05/2020.
//  Copyright © 2020 Mathieu Vandeginste. All rights reserved.
//

import SwiftUI
import UIKit
import MapKit

var currentLayer: Layer?
var selectedAnnotation: PoiAnnotation?
var customAnnotation: PoiAnnotation?
var removeCustomAnnotation = false
var lockedCustomAnnotation = false
var mapChangedFromUserInteraction = false
var currentPlayingTourState = false
var timer: Timer?

struct MapView: UIViewRepresentable {
  
  // MARK: Binding properties
  @Binding var selectedTracking: Tracking
  @Binding var selectedLayer: Layer
  @Binding var selectedPoi: Poi?
  @Binding var isPlayingTour: Bool
  @State var sender: UILongPressGestureRecognizer?
  
  // MARK: Constructors
  init(selectedTracking: Binding<Tracking>, selectedLayer: Binding<Layer>, selectedPoi: Binding<Poi?>, isPlayingTour: Binding<Bool>, trail: Trail? = nil) {
    
    self.trail = trail
    self._selectedTracking = selectedTracking
    self._selectedLayer = selectedLayer
    self._selectedPoi = selectedPoi
    self._isPlayingTour = isPlayingTour
    
  }
  
  // Convenience init
  init(trail: Trail? = nil) {
    
    self.init(selectedTracking: Binding<Tracking>.constant(.disabled), selectedLayer: Binding<Layer>.constant(.ign), selectedPoi: Binding<Poi?>.constant(nil), isPlayingTour: Binding<Bool>.constant(false), trail: trail)
    
  }
  
  // MARK: Properties
  var trail: Trail?
  let trailManager = TrailManager.shared
  let locationManager = LocationManager.shared
  var annotations: [PoiAnnotation] {
    PoiManager.shared.pois.map { PoiAnnotation(poi: $0) }
  }
  var compassY: CGFloat {
    if trail != nil {
      return 8
    } else {
      return isPlayingTour ? 50 : 160
    }
  }
  
  // MARK: Coordinator
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, MKMapViewDelegate, HeadingDelegate {
    
    var parent: MapView
    var headingImageView: UIImageView?
    
    init(_ parent: MapView) {
      self.parent = parent
      super.init()
      parent.locationManager.headingDelegate = self
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
      mapView.userLocation.subtitle = "Alt. \(Int(parent.locationManager.currentPosition.altitude))m"
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      switch overlay {
      case let overlay as MKTileOverlay:
        return MKTileOverlayRenderer(tileOverlay: overlay)
      default:
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = .grblue
        polylineRenderer.lineWidth = 3
        return polylineRenderer
      }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      guard let annotation = annotation as? PoiAnnotation else { return nil }
      let identifier = "Annotation"
      var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
      if let view = view {
        view.annotation = annotation
      } else {
        view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view?.canShowCallout = true
      }
      if let view = view as? MKMarkerAnnotationView {
        view.glyphImage = annotation.markerGlyph
        view.markerTintColor = annotation.markerColor
      }
      return view
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
      mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction(mapView)
      if mapChangedFromUserInteraction {
        self.parent.selectedTracking = .disabled
      }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      guard !parent.isPlayingTour, parent.selectedLayer == .ign else { return }
      // Max zoom check
      let coordinate = CLLocationCoordinate2DMake(mapView.region.center.latitude, mapView.region.center.longitude)
      var span = mapView.region.span
      let maxZoom: CLLocationDegrees = 0.014
      if span.latitudeDelta < maxZoom {
        span = MKCoordinateSpan(latitudeDelta: maxZoom, longitudeDelta: maxZoom)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
      }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
      guard let annotation = view.annotation as? PoiAnnotation else {
        return }
      self.parent.selectedPoi = annotation.poi
      selectedAnnotation = annotation
      Feedback.selected()
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
      self.parent.selectedPoi = nil
      selectedAnnotation = nil
      Feedback.selected()
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
      if views.last?.annotation is MKUserLocation {
        addHeadingView(toAnnotationView: views.last!)
      }
    }
    
    func didUpdate(_ heading: CLLocationDirection) {
      guard let headingImageView = headingImageView, parent.selectedTracking == .enabled else { return }
      headingImageView.isHidden = false
      let rotation = CGFloat(heading/180 * Double.pi)
      headingImageView.transform = CGAffineTransform(rotationAngle: rotation)
    }
    
    private func mapViewRegionDidChangeFromUserInteraction(_ mapView: MKMapView) -> Bool {
      let view = mapView.subviews[0]
      //  Look through gesture recognizers to determine whether this region change is from user interaction
      if let gestureRecognizers = view.gestureRecognizers {
        for recognizer in gestureRecognizers {
          if recognizer.state == .began || recognizer.state == .ended {
            return true
          }
        }
      }
      return false
    }
    
    private func addHeadingView(toAnnotationView annotationView: MKAnnotationView) {
      guard headingImageView == nil else { return }
      let image = UIImage(named: "beam")!
      headingImageView = UIImageView(image: image)
      let size: CGFloat = 100
      headingImageView!.frame = CGRect(x: annotationView.frame.size.width/2 - size/2, y: annotationView.frame.size.height/2 - size/2, width: size, height: size)
      annotationView.insertSubview(headingImageView!, at: 0)
      headingImageView!.isHidden = true
    }
    
    @objc func recognizeLongPress(sender: UILongPressGestureRecognizer) {
      // Do not generate pins many times during long press.
      guard sender.state == .recognized else { return }
      lockedCustomAnnotation = false
      parent.sender = sender
    }
    
  }
  
  // MARK: UIViewRepresentable lifecycle methods
  func makeUIView(context: Context) -> MKMapView {
    currentLayer = nil
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    self.configureMap(mapView: mapView)
    if let trail = trail {
        var region = MKCoordinateRegion(trail.polyline.boundingMapRect)
        region.span.latitudeDelta += 0.01
        region.span.longitudeDelta += 0.01
        mapView.setRegion(region, animated: false)
    } else {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = 1
        gesture.addTarget(context.coordinator, action: #selector(Coordinator.recognizeLongPress))
        mapView.addGestureRecognizer(gesture)
        mapView.addAnnotations(annotations)
        var region = MKCoordinateRegion(trailManager.boundingBox)
        region.span.latitudeDelta += 0.01
        region.span.longitudeDelta += 0.01
        mapView.setRegion(region, animated: false)
    }
    return mapView
  }
  
  func updateUIView(_ uiView: MKMapView, context: Context) {
    playTour(mapView: uiView)
    setTracking(mapView: uiView, headingView: context.coordinator.headingImageView)
    setOverlays(mapView: uiView)
    setAnnotations(mapView: uiView)
    handleLongPress(mapView: uiView)
  }
  
  // MARK: Private methods
  
  private func handleLongPress(mapView: MKMapView) {
    guard let sender = sender, customAnnotation == nil, !lockedCustomAnnotation else { return }
    let location = sender.location(in: mapView)
    let coordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
    let poi = Poi(lat: coordinate.latitude, lng: coordinate.longitude, alt: trailManager.closestAltitude(from: coordinate))
    let annotation = PoiAnnotation(poi: poi)
    mapView.addAnnotation(annotation)
    selectedPoi = poi
    customAnnotation = annotation
    lockedCustomAnnotation = true
    mapView.selectAnnotation(annotation, animated: true)
  }
  
  private func configureMap(mapView: MKMapView) {
    mapView.showsTraffic = false
    mapView.showsBuildings = false
    mapView.showsUserLocation = true
    mapView.showsScale = true
    mapView.isPitchEnabled = true
    // Custom compass
    #if !targetEnvironment(macCatalyst)
    mapView.showsCompass = false // Remove default
    let compass = MKCompassButton(mapView: mapView)
    compass.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.width - 53, y: compassY), size: CGSize(width: 45, height: 45))
    mapView.addSubview(compass)
    #endif
  }
  
  private func setTracking(mapView: MKMapView, headingView: UIImageView?) {
    switch selectedTracking {
    case .disabled:
      mapView.setUserTrackingMode(.none, animated: true)
      locationManager.updateHeading = false
      headingView?.isHidden = true
    case .enabled:
      mapView.setUserTrackingMode(.follow, animated: true)
      locationManager.updateHeading = true
    case .heading:
      mapView.setUserTrackingMode(.followWithHeading, animated: true)
      headingView?.isHidden = true
    default:
      var region = MKCoordinateRegion(trailManager.boundingBox)
      region.span.latitudeDelta += 6
      region.span.longitudeDelta += 6
      mapView.setRegion(region, animated: false)
    }
  }
  
  private func setOverlays(mapView: MKMapView) {
    // Avoid refreshing UI if selectedLayer has not changed
    guard currentLayer != selectedLayer else { return }
    currentLayer = selectedLayer
    mapView.removeOverlays(mapView.overlays)
    switch selectedLayer {
    case .ign:
      let overlay = TileOverlay()
      overlay.canReplaceMapContent = false
      mapView.mapType = .standard
      mapView.addOverlay(overlay, level: .aboveLabels)
    case .satellite:
      mapView.mapType = .hybrid
    case .flyover:
      mapView.mapType = .hybridFlyover
    default:
      mapView.mapType = .standard
    }
    mapView.addOverlay(trail?.polyline ?? trailManager.polyline, level: .aboveLabels)
  }
  
  private func setAnnotations(mapView: MKMapView) {
    
    if selectedPoi == nil {
      if let selectedAnnotation = selectedAnnotation, removeCustomAnnotation {
        removeCustomAnnotation = false
        mapView.removeAnnotation(selectedAnnotation)
        customAnnotation = nil
      } else {
        mapView.deselectAnnotation(selectedAnnotation, animated: true)
      }
    }
  }
  
  private func playTour(mapView: MKMapView) {
    #if !targetEnvironment(macCatalyst)
    if let compass = mapView.subviews.filter({$0 is MKCompassButton}).first as? MKCompassButton {
      compass.frame.origin.y = compassY
    }
    #endif
    guard isPlayingTour else {
      timer?.invalidate()
      currentPlayingTourState = false
      return
    }
    let locs = TrailManager.shared.currentLocationsCoordinate
    let animationDuration: TimeInterval = 4
    let Δ = 5
    if currentPlayingTourState {
      timer?.invalidate()
      let camera = MKMapCamera(lookingAtCenter: locs[Δ], fromEyeCoordinate: locs[0], eyeAltitude: 1000)
      camera.pitch = 0
      mapView.camera = camera
    }
    currentPlayingTourState = true
    var i = 0
    guard locs.count > Δ else { return }
    mapView.camera = MKMapCamera(lookingAtCenter: locs[i + Δ], fromEyeCoordinate: locs[i], eyeAltitude: 6000)
    timer = Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { timer in
      i += Δ
      guard i < locs.count else {
        self.isPlayingTour = false
        currentPlayingTourState = false
        return timer.invalidate()
      }
      let camera =  MKMapCamera(lookingAtCenter: locs[i], fromEyeCoordinate: locs[i - Δ], eyeAltitude: 6000)
      camera.pitch = 80
      UIView.animate(withDuration: animationDuration, delay: 0, options: .curveLinear, animations: {
        mapView.camera = camera
      })
    }
    
  }
  
}


// MARK: Previews
struct MapView_Previews: PreviewProvider {
  
  static var previews: some View {
    MapView()
      .previewDevice(PreviewDevice(rawValue: "iPhone X"))
      .previewDisplayName("iPhone X")
      .environment(\.colorScheme, .dark)
  }
}

//
//  CLLocationCoordinate2D.swift
//  GR10
//
//  Created by Mathieu Vandeginste on 13/05/2020.
//  Copyright © 2020 Mathieu Vandeginste. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
  
  func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
    CLLocation(latitude: from.latitude, longitude: from.longitude).distance(from: CLLocation(latitude: latitude, longitude: longitude))
  }
}

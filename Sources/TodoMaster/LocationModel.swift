//
//  LocationModel.swift
//  WeatherMaster
//
//  Created by Mohammad on 2/25/23.
//

import Foundation
import CoreLocation

class Location {
    var lon : CLLocationDegrees
    var lat : CLLocationDegrees
    
    init(lon: CLLocationDegrees, lat: CLLocationDegrees) {
        self.lon = lon
        self.lat = lat
    }
}

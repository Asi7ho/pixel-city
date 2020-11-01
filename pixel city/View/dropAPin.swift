//
//  dropAPin.swift
//  pixel city
//
//  Created by Yann Debain on 21/01/2018.
//  Copyright © 2018 Debain Yann. All rights reserved.
//

import UIKit
import MapKit

class DropAPin: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier: String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}

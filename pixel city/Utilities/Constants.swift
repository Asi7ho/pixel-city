//
//  Constants.swift
//  pixel city
//
//  Created by Yann Debain on 24/01/2018.
//  Copyright © 2018 Debain Yann. All rights reserved.
//

import Foundation

let API_KEY = "2fac1a1c68c17542a7b3b38751cc7ea1"

func flickrUrl(forApiKey key: String, withAnnotation annotation: DropAPin, andNumberOfPhotos number: Int) -> String {
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=5&radius_units=m&per_page=\(number)&format=json&nojsoncallback=1"
}

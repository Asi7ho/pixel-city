//
//  MapVC.swift
//  pixel city
//
//  Created by Yann Debain on 20/01/2018.
//  Copyright © 2018 Debain Yann. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pollUpView: UIView!
    
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 2000
    var locationManager = CLLocationManager.init()
    var pullUpHeight = 300
    var screenSize = UIScreen.main.bounds
    var spinner: UIActivityIndicatorView?
    var progresseLbl: UILabel?
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        configureLocationServices()
        
        doubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(photoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        pollUpView.addSubview(collectionView!)
    }
    
    func doubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pollUpView.addGestureRecognizer(swipe)
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = CGFloat(pullUpHeight)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: CGFloat(pullUpHeight / 2))
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner () {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl () {
        progresseLbl = UILabel()
        progresseLbl?.frame = CGRect(x: (screenSize.width / 2) - 125, y: 175, width: 250, height: 40)
        progresseLbl?.font = UIFont(name: "Avenir Next", size: 18)
        progresseLbl?.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        progresseLbl?.textAlignment = .center
        collectionView?.addSubview(progresseLbl!)
    }
    
    func removeProgressLbl () {
        if progresseLbl != nil {
            progresseLbl?.removeFromSuperview()
        }
    }
    
    @objc func animateViewDown() {
        cancelAllSessions()
        pullUpViewHeightConstraint.constant = 1
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            mapCenterOnUserLocation()
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "dropAPin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func mapCenterOnUserLocation() {
        guard let coordonates = locationManager.location?.coordinate else {return}
        let coordonateRegion = MKCoordinateRegionMakeWithDistance(coordonates, regionRadius, regionRadius)
        mapView.setRegion(coordonateRegion, animated: true)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePin()
        removeSpinner()
        removeProgressLbl()
        cancelAllSessions()
        
        imageUrlArray = []
        imageArray = []
        collectionView?.reloadData()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordonates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DropAPin(coordinate: touchCoordonates, identifier: "dropAPin")
        mapView.addAnnotation(annotation)
        
        let coordonatesRegion = MKCoordinateRegionMakeWithDistance(touchCoordonates, regionRadius, regionRadius)
        mapView.setRegion(coordonatesRegion, animated: true)
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLbl()
        retrieveUrls(forAnnotation: annotation) { (finished) in
            if finished == true {
                self.retrieveImages(handler: { (finished) in
                    if finished == true {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DropAPin, handler: @escaping (_ status: Bool) -> ()) {
        
        Alamofire.request(flickrUrl(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else {return}
            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photosDictArray {
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                self.imageUrlArray.append(postUrl)
            }
            handler(true)
        }
    }
    
    func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {
        
        for url in imageUrlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else {return}
                self.imageArray.append(image)
                self.progresseLbl?.text = "\(self.imageArray.count)/40 IMAGES DOWLOADED"
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
            })
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
        }
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapCenterOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? photoCell else {return UICollectionViewCell()}
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return}
        popVC.initData(forImage: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}


//
//  MapsViewContoller.swift
//  GoogMapsTracker
//
//  Created by innowise on 8/24/23.
//

import UIKit
import GoogleMaps

struct User {
    let title: String
    let image: String
    let coordinates: CLLocationCoordinate2D
}

class MapsViewContoller: UIViewController, UINavigationBarDelegate {
    
    let users = [
        User(title: "User 1", image: "user1", coordinates: CLLocationCoordinate2D(latitude: 52.42737345173471, longitude: 31.01787866195918)),
        User(title: "User 2", image: "user2", coordinates: CLLocationCoordinate2D(latitude: 52.43895419185292, longitude: 31.00903786718845)),
        User(title: "User 3", image: "user3", coordinates: CLLocationCoordinate2D(latitude: 52.430507111833684, longitude: 31.00534077733755))
    ]
//end: 52.449888941039504, 31.036552973091602
    var locationManager = CLLocationManager()
    var userCoordinates: CLLocationCoordinate2D!
    var destinationCoordinates: CLLocationCoordinate2D!
    var mapView: GMSMapView!
    var userMarker: GMSMarker!
    lazy var destinationIcon: UIImageView = {
       let imageView = UIImageView(image: UIImage(systemName: "arrow.down"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    lazy var destinationButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Destination", for: .normal)
        button.addTarget(self, action: #selector(desctinationButtonAction), for: .touchUpInside)
        button.tintColor = .blue
        button.backgroundColor = .lightGray
        return button
    }()
    
    lazy var destinationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.text = "Test tesxt"
        return label
    }()
    
    lazy var runButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Run", for: .normal)
        button.addTarget(self, action: #selector(runButtonAction), for: .touchUpInside)
        button.tintColor = .blue
        button.backgroundColor = .lightGray
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = GMSMapView(frame: view.frame)
        view.addSubview(mapView)
        
        
        mapView.addSubview(destinationButton)
        mapView.addSubview(runButton)
        mapView.addSubview(destinationIcon)
        mapView.addSubview(destinationLabel)
                
        NSLayoutConstraint.activate([
            destinationButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -80),
            destinationButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 10),
            runButton.leadingAnchor.constraint(equalTo: destinationButton.trailingAnchor, constant: 10),
            runButton.bottomAnchor.constraint(equalTo: destinationButton.bottomAnchor),
            destinationIcon.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            destinationIcon.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
            destinationLabel.bottomAnchor.constraint(equalTo: destinationIcon.topAnchor, constant: 5),
            destinationLabel.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            destinationLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        locationManager.delegate = self
        mapView.delegate = self
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
            locationManager.startUpdatingLocation()

            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
            guard let location = locationManager.location else { return }
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 16, bearing: 0, viewingAngle: 0)
            createMarker()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func createMarker() {
            let marker = GMSMarker()
            marker.iconView = UIImageView(image: UIImage(systemName: "car.side"))
            marker.map = mapView
            userMarker = marker
        }
    
    func updateMarkerWith(position: CLLocationCoordinate2D, angle: Double) {
            userMarker.position = position
            guard angle >= 0 && angle < 360 else {
                return
            }
            let angleInRadians: CGFloat = CGFloat(angle) * .pi / CGFloat(180) //Form degrees to radians transformation
            userMarker.iconView?.transform = CGAffineTransform.identity.rotated(by: angleInRadians) //Rotation of the marker
        }
    
    @objc func desctinationButtonAction() {
        userMarker.iconView?.isHidden.toggle()
        destinationIcon.isHidden.toggle()
        destinationLabel.isHidden.toggle()
    }
    
    @objc func runButtonAction() {
//        let routingOptions = GMSNavigationRoutingOptions(alternateRoutesStrategy: .none)
//        navigator?.setDestinations(destinations,
//                                   routingOptions: routingOptions) { routeStatus in
//          ...
//        }
        getRouteSteps(from: userCoordinates, to: destinationCoordinates)
        
    }
    
    func getRouteSteps(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        
        let positions = users.map { $0.coordinates }
        var wayPoints = ""
        for point in positions {
            wayPoints = wayPoints.count == 0 ? "\(point.latitude),\(point.longitude)" : "\(wayPoints)%7C\(point.latitude),\(point.longitude)"
        }

        let session = URLSession.shared

        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=52.42737295090826,31.01787909865379&destination=\(destination.latitude),\(destination.longitude)&waypoints=via:\(wayPoints)&mode=driving&key=\(AppDelegate.apiKey)")!

        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in

            guard error == nil else {
                print(error!.localizedDescription)
                return
            }

            guard let jsonResult = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] else {
                print("error in JSONSerialization")
                return
            }
            
            guard let routes = jsonResult["routes"] as? [Any] else { return }
            guard let route = routes[0] as? [String: Any] else { return }
            guard let testValues = route["overview_polyline"] as? [String: Any] else { return }
            guard let legs = route["legs"] as? [Any] else { return }
            guard let leg = legs[0] as? [String: Any] else { return }
            guard let steps = leg["steps"] as? [Any] else { return }
            for item in steps {
                guard let step = item as? [String: Any] else {
                    return
                }
                guard let polyline = step["polyline"] as? [String: Any] else {
                    return
                }
                guard let polyLineString = polyline["points"] as? String else {
                    return
                }
                //Call this method to draw path on map
                DispatchQueue.main.async {
                    for user in self.users {
                        let marker = GMSMarker()
                        marker.title = user.title
                        marker.iconView = UIImageView(image: UIImage(named: user.image))
                        marker.iconView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                        marker.iconView?.layer.masksToBounds = true
                        marker.iconView?.layer.cornerRadius = 15
                        marker.position = user.coordinates
                        marker.appearAnimation = .pop
                        marker.map = self.mapView
                    }
                }
                
                
            }
            
            DispatchQueue.main.async {
                self.drawPath(from: (testValues["points"] as? String)!)
            }
        })
        task.resume()
    }
    
    func drawPath(from polyStr: String){
        
//        let path = GMSPath(fromEncodedPath: polyStr)
//        let routePolyline = GMSPolyline(path: path)
//        routePolyline.map = mapView
        let path = GMSPath(fromEncodedPath: polyStr)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3.0
        polyline.map = mapView // Google MapView
        print("------")
        print(path)
        print("------")
        print(polyline)


        let cameraUpdate = GMSCameraUpdate.fit(GMSCoordinateBounds(coordinate: userCoordinates, coordinate: destinationCoordinates))
        mapView.moveCamera(cameraUpdate)
        let currentZoom = mapView.camera.zoom
        mapView.animate(toZoom: currentZoom - 1.4)
    }
}


extension MapsViewContoller: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else { return }
        
        locationManager.requestLocation()
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("UPdate locatiosn")
        guard let location = locations.first else { return }
        let point = CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                           longitude: location.coordinate.longitude)
        userCoordinates = point
        updateMarkerWith(position: point, angle: location.course)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension MapsViewContoller: GMSMapViewDelegate {
    
    func geocodeLocation(_ coordinate: CLLocationCoordinate2D) {
        guard !destinationLabel.isHidden else { return }
        destinationCoordinates = coordinate
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate) { [weak self] response, error in
            guard let self = self else { return }
            guard let address = response?.firstResult(), let lines = address.lines else { return }
            self.destinationLabel.text = lines.joined(separator: "\n")
        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        print("From GMaps idleAt method \(position.target)")
        geocodeLocation(position.target)
    }
}

//52.42737345173471, 31.01787866195918
//let location = CLLocationCoordinate2D(latitude: 47.67, longitude: -122.20)
//let waypoint = GMSNavigationMutableWaypoint(location: location, title: "waypoint from location")!
//waypoint.vehicleStopover = true
//mapView.navigator?.setDestinations([waypoint], routingOptions: routingOptions, callback: {...})

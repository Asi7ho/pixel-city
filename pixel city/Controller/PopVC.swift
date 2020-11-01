//
//  PopVC.swift
//  pixel city
//
//  Created by Yann Debain on 26/01/2018.
//  Copyright © 2018 Debain Yann. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var popImageView: UIImageView!
    
    var passedImage: UIImage!
    
    func initData(forImage image: UIImage) {
        self.passedImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popImageView.image = passedImage
        addDoubleTap()
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenWasDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func screenWasDoubleTapped() {
        dismiss(animated: true, completion: nil)
    }
}

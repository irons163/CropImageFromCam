//
//  CroppedImageViewController.swift
//  SpikeCustomBgFromCam
//
//  Created by Phil Chang on 2023/1/19.
//        

import UIKit

class CroppedImageViewController: UIViewController {

    @IBOutlet weak var croppedImageView: UIImageView!

    var croppedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.croppedImageView.image = croppedImage
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

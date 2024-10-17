//
//  ViewController.swift
//  SpikeCustomBgFromCam
//
//  Created by Phil Chang on 2023/1/18.
//        

import UIKit
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var scrollView: UIScrollView!
    var preview: UIView?

    // can be .scaleAspectFill or .scaleAspectFit
    var fitMode: UIView.ContentMode = .scaleAspectFill

    var allowFullImage: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupScrollView()
    }

    private func dealWithImage(_ image: UIImage?) {
        self.imageView.image = image
        self.imageView.frame.size = image?.size ?? .zero
        self.scrollView.contentSize = self.imageView.frame.size
        centerImageView()
    }

    @IBAction func didTapPreviewButton(_ sender: Any) {
        let preview = ProfileViewController()
        self.preview = preview.view
        preview.view.translatesAutoresizingMaskIntoConstraints = false
        preview.view.backgroundColor = nil
        preview.bgView.backgroundColor = nil
        preview.bgImageView.image = nil
        preview.view.layer.borderColor = UIColor.green.cgColor
        preview.view.layer.borderWidth = 3
        self.scrollView.addSubview(preview.view)
        let defaultTop = preview.view.topAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.topAnchor)
        defaultTop.priority = .defaultHigh
        let defaultBottom = preview.view.bottomAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.bottomAnchor)
        defaultBottom.priority = .defaultHigh
        let defaultLeading = preview.view.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor)
        defaultLeading.priority = .defaultHigh
        let defaultTrailing = preview.view.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor)
        defaultTrailing.priority = .defaultHigh
        NSLayoutConstraint.activate([
            preview.view.widthAnchor.constraint(equalTo: preview.view.heightAnchor, multiplier: UIScreen.main.bounds.size.width / UIScreen.main.bounds.size.height),
            preview.view.centerXAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.centerXAnchor),
            preview.view.centerYAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.centerYAnchor),
            preview.view.topAnchor.constraint(greaterThanOrEqualTo: self.scrollView.frameLayoutGuide.topAnchor),
            preview.view.bottomAnchor.constraint(lessThanOrEqualTo: self.scrollView.frameLayoutGuide.bottomAnchor),
            preview.view.leadingAnchor.constraint(greaterThanOrEqualTo: self.scrollView.frameLayoutGuide.leadingAnchor),
            preview.view.trailingAnchor.constraint(lessThanOrEqualTo: self.scrollView.frameLayoutGuide.trailingAnchor),
            defaultTop,
            defaultBottom,
            defaultLeading,
            defaultTrailing
        ])
    }

    @IBAction func didTapCropButton(_ sender: Any) {
        guard let image = self.imageView.image,
              let preview = self.preview else { return }
        let cropRect = CGRect(x: preview.frame.origin.x - imageView.realImageRect().origin.x,
                              y: preview.frame.origin.y - imageView.realImageRect().origin.y,
                              width: preview.frame.width,
                              height: preview.frame.height)
        let croppedVc = CroppedImageViewController()
        let croppedImage = ImageCropHelper.shared.cropImage(image, toRect: cropRect, viewWidth: imageView.frame.width, viewHeight: imageView.frame.height)
        croppedVc.croppedImage = croppedImage
        croppedVc.modalPresentationStyle = .fullScreen
        self.present(croppedVc, animated: true)
    }

    @IBAction func pickPhotoFromAlbum(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.videoExportPreset = AVAssetExportPresetPassthrough
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        self.present(picker, animated: true, completion: nil)
    }
}

extension ViewController: UIScrollViewDelegate {

    func setupScrollView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleToFill

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.updateMinZoomScaleForSize(size, shouldSize: (self.scrollView.zoomScale == self.scrollView.minimumZoomScale))
        }, completion: {
            _ in
        })
    }

    func updateMinZoomScaleForSize(_ size: CGSize, shouldSize: Bool = true) {
        guard let img = imageView.image else {
            return
        }

        var bShouldSize = shouldSize

        let widthScale = img.size.width / size.width
        let heightScale = img.size.height / size.height

        var minScale = min(widthScale, heightScale)
        let startScale = max(widthScale, heightScale)

        if fitMode == .scaleAspectFill && !allowFullImage {
            minScale = startScale
        }
        if scrollView.zoomScale < minScale {
            bShouldSize = true
        }
        scrollView.minimumZoomScale = minScale
        if bShouldSize {
            scrollView.zoomScale = fitMode == .scaleAspectFill ? startScale : minScale
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        //        updateConstraintsForSize(scrollView.bounds.size)
    }

    func centerImageView() -> Void {
        let yOffset = (scrollView.frame.size.height - imageView.frame.size.height) / 2
        let xOffset = (scrollView.frame.size.width - imageView.frame.size.width) / 2
        scrollView.contentOffset = CGPoint(x: -xOffset, y: -yOffset)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        self.dealWithImage(self.imageWithMediaInfo(info))
        picker.dismiss(animated: true, completion: nil)
    }

    private func imageWithMediaInfo(_ info: [UIImagePickerController.InfoKey: Any]) -> UIImage? {
        let originalImage = info[.originalImage] as? UIImage
        return originalImage
    }
}

extension UIImageView {

    // MARK: - Methods
    func realImageRect() -> CGRect {
        let imageViewSize = self.frame.size
        let imgSize = self.image?.size

        guard let imageSize = imgSize else {
            return CGRect.zero
        }

        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)

        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)

        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2

        // Add imageView offset
        imageRect.origin.x += self.frame.origin.x
        imageRect.origin.y += self.frame.origin.y

        return imageRect
    }
}

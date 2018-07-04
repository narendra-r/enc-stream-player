//
//  ViewController.swift
//  EncStream
//
//  Created by Narendra Kumar R on 6/28/18.
//  Copyright © 2018 Narendra Kumar R. All rights reserved.
//

import UIKit
import AVKit
class ViewController: UIViewController, DVAssetLoaderDelegatesDelegate {
    private weak var avPlayer: AVPlayer?
    private var videoVC: AVPlayerViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        let plain_video = "https://s3.amazonaws.com/simple-naren/big_buck_bunny.mp4"
        let enc_url = "https://s3.amazonaws.com/simple-naren/enc_earth_video.mp4"
        playfrom(videoURL: enc_url)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func playfrom(videoURL: String) {
        
        if let url = URL(string: videoURL) {
            let resourceLoaderDelegate = DVAssetLoaderDelegate.init(url: url)
            resourceLoaderDelegate?.delegate = self;
            
            let components = NSURLComponents.init(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = DVAssetLoaderDelegate.scheme();
            
            let asset = AVURLAsset.init(url: (components?.url)!)
            asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)
            
            let assetKeys = ["playable","hasProtectedContent"]
            let playerItem = AVPlayerItem(asset: asset,automaticallyLoadedAssetKeys: assetKeys)
            avPlayer = AVPlayer.init(playerItem: playerItem)
            
            avPlayer?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer!.currentItem)
        }
        
        
        videoVC = childViewControllers[0] as! AVPlayerViewController
        videoVC.view.clipsToBounds = true
        videoVC.player = avPlayer
        videoVC.showsPlaybackControls = true
        
        avPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 2), queue: DispatchQueue.main, using: { (time) in
            // This need to have to update transcript timeline
        })

        avPlayer?.addObserver(self, forKeyPath: "status", options: .initial, context: nil)
    }
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        
    }
    
    func dvAssetLoaderDelegate(_ loaderDelegate: DVAssetLoaderDelegate!, didLoad data: Data!, for url: URL!) {
        print("finished")
    }
    func dvAssetLoaderDelegate(_ loaderDelegate: DVAssetLoaderDelegate!, didRecieveLoadingError error: Error!, with dataTask: URLSessionDataTask!, for request: AVAssetResourceLoadingRequest!) {
        print("failed")
    }
    
    func dvAssetLoaderDelegate(_ loaderDelegate: DVAssetLoaderDelegate!, didLoad data: Data!, for range: NSRange, url: URL!) {
        print("data : \(data)")
    }

    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if avPlayer == object as? AVPlayer, keyPath  == "status" {
            if (avPlayer?.status == .readyToPlay) {
                avPlayer?.play()
            }
        }
    }
}


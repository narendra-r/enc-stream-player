//
//  ViewController.swift
//  EncStream
//
//  Created by Narendra Kumar R on 6/28/18.
//  Copyright © 2018 Narendra Kumar R. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private weak var avPlayer: AVPlayer?
    @IBOutlet weak var videoPlayerView: VideoPlayerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let plain_video = "https://s3.amazonaws.com/simple-naren/big_buck_bunny.mp4"
        let enc_url = "https://s3.amazonaws.com/simple-naren/enc_earth_video.mp4"
        playfrom(audioUrl: plain_video)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func playfrom(audioUrl: String) {
        videoPlayerView.setupPlayerView(urlString : audioUrl)
        self.avPlayer = videoPlayerView.player
        
        avPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 2), queue: DispatchQueue.main, using: { (time) in
            
            if let videoItem = self.avPlayer?.currentItem {
                let currentTime : Float64 = CMTimeGetSeconds(videoItem.currentTime());
                let totalDuration : Float64 = CMTimeGetSeconds(videoItem.duration);
                let progress = currentTime / totalDuration
                self.videoPlayerView.videoSlider.value = Float(progress)
                
            }
        })
        
        avPlayer?.addObserver(self, forKeyPath: "status", options: .initial, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if avPlayer == object as? AVPlayer, keyPath  == "status" {
            if (avPlayer?.status == .readyToPlay) {
                avPlayer?.play()
            }
        }
    }
}


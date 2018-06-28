//
//  VideoPlayerView.swift
//  EncStream
//
//  Created by Narendra Kumar R on 6/28/18.
//  Copyright © 2018 Narendra Kumar R. All rights reserved.
//

import Foundation

import UIKit
class VideoPlayerView: UIView, DVAssetLoaderDelegatesDelegate {
    var fileHandle: FileHandle!
    // MARK: - init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setUp()
    }
    
    deinit {
        if isPlayerViewSettedUp {
            NotificationCenter.default.removeObserver(self, forKeyPath: NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue)
        }
    }
    
    // MARK: - Life cycle methods
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.playerLayer?.frame = self.layer.frame
    }
    
    // MARK: - private variables
    private let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        aiv.startAnimating()
        return aiv
    }()
    
    private lazy var pausePlayButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "icn-audio-play")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.isHidden = true
        
        button.addTarget(self, action: #selector(handlePause), for: .touchUpInside)
        
        return button
    }()
    
    private let controlsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0, alpha: 1)
        return view
    }()
    
    private var playerLayer : AVPlayerLayer?
    private var isPlayerViewSettedUp : Bool = false
    
    // MARK: - public variables
    public var isPlaying = false {
        didSet {
            if isPlaying {
                player?.play()
                pausePlayButton.isHidden = true
            } else {
                player?.pause()
                pausePlayButton.isHidden = false
            }
        }
    }
    public var player: AVPlayer?
    public lazy var videoSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .blue
        slider.maximumTrackTintColor = .white
        
        slider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        
        return slider
    }()
    
    // MARK: - Action methods
    @objc func handlePause() {
        isPlaying = !isPlaying
    }
    
    @objc func handleSliderChange() {
        videoSlider.setThumbImage(UIImage(named : ""), for: .normal)
        
        if let duration = player?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            
            if totalSeconds.isInfinite || totalSeconds.isNaN {
                return
            }
            
            let value = Float64(videoSlider.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            player?.seek(to: seekTime, completionHandler: { (completedSeek) in
                self.videoSlider.setThumbImage(nil, for: .normal)
            })
        }
    }
    
    // MARK: - private methods
    private func setUp() {
        avPlayerLayerSetup()
        
        //Controls setup
        controlsContainerView.frame = frame
        addSubview(controlsContainerView)
        controlsContainerView.widthAnchor.constraint(equalTo : widthAnchor).isActive = true
        controlsContainerView.heightAnchor.constraint(equalTo : heightAnchor).isActive = true
        
        controlsContainerView.addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        controlsContainerView.addSubview(pausePlayButton)
        pausePlayButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        pausePlayButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        pausePlayButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        pausePlayButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        controlsContainerView.addSubview(videoSlider)
        videoSlider.rightAnchor.constraint(equalTo: rightAnchor , constant : -10).isActive = true
        videoSlider.bottomAnchor.constraint(equalTo: bottomAnchor, constant : -15).isActive = true
        videoSlider.leftAnchor.constraint(equalTo: leftAnchor, constant : 10).isActive = true
        videoSlider.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        backgroundColor = .black
        
        //tap gesture for pause and play
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePause))
        self.addGestureRecognizer(tapGesture)
    }
    
    private func avPlayerLayerSetup() {
        //AVPlayer Layer setup
        let playerLayer = AVPlayerLayer()
        self.layer.addSublayer(playerLayer)
        playerLayer.frame = self.layer.frame
        self.playerLayer = playerLayer
    }
    
    private func restart() {
        let seekTime = CMTime(value: Int64(0), timescale: 1)
        player?.seek(to: seekTime)
    }
    
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        restart()
        self.isPlaying = false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "currentItem.loadedTimeRanges" {
            
            if activityIndicatorView.isAnimating {
                activityIndicatorView.stopAnimating()
                controlsContainerView.backgroundColor = .clear
                if !isPlaying {
                    isPlaying = true
                }
            }
        }
    }
    
    private func reset() {
        self.isPlaying = true
        restart()
        videoSlider.value = 0
    }
    
    // MARK: - Public methods
    public func setupPlayerView(urlString : String) {
        activityIndicatorView.startAnimating()
        
        if let url = URL(string: urlString) {
            let resourceLoaderDelegate = DVAssetLoaderDelegate.init(url: url)
            resourceLoaderDelegate?.delegate = self;
            
            let components = NSURLComponents.init(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = DVAssetLoaderDelegate.scheme();
            
            let asset = AVURLAsset.init(url: (components?.url)!)
            asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)

            let assetKeys = ["playable","hasProtectedContent"]
            let playerItem = AVPlayerItem(asset: asset,automaticallyLoadedAssetKeys: assetKeys)
            player = AVPlayer.init(playerItem: playerItem)
            self.playerLayer?.player = player
            reset()
            player?.play()
            player?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
            isPlayerViewSettedUp = true
        }
        
        
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
}

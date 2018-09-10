/*
   Copyright 2016 Domenico Ottolia

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

import Foundation
import AVFoundation
import CoreGraphics
import CoreImage
import GLKit

class VideoFilterExport{
   
   // For implementation in Swift 2.x, look at the history of this file at
   // https://github.com/jojodmo/VideoFilterExporter/blob/cf6fcdb4852eae5a1c8a2ce0887bebfeb0f36a9a/VideoFilterExporter.swift
    
    let asset: AVAsset
    let filters: [CIFilter]
    let context: CIContext
    init(asset: AVAsset, filters: [CIFilter], context: CIContext){
        self.asset = asset
        self.filters = filters
        self.context = context
    }
    
    convenience init(asset: AVAsset, filters: [CIFilter]){
      let eagl = EAGLContext(api: EAGLRenderingAPI.openGLES2)
      let context = CIContext.init(eaglContext: eagl!)
      
        
        self.init(asset: asset, filters: filters, context: context)
    }
  
  
  func exportVideoAsyncTask(toURL url: URL, completion: @escaping ((_ url: AVAssetExportSession?) -> Void)) {
//    DispatchQueue.global().async {
    
      guard let track : AVAssetTrack = self.asset.tracks(withMediaType: AVMediaType.video).first else {
        completion(nil)
        return
      }
      let composition = AVMutableComposition()
      guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
        return
      }
//      guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
//        return
//      }
      do {
        try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, self.asset.duration), of: track, at: kCMTimeZero)
      } catch _ {
        completion(nil)
        return
      }
      
//      do {
//        try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, self.asset.duration), of: track, at: kCMTimeZero)
//      } catch _ {
//        completion(nil)
//        return
//      }
      
      let layerInstruction = VideoHelper.videoCompositionInstruction(videoTrack, asset: self.asset)
//      layerInstruction.trackID = videoTrack.trackID
    
      let instruction = AVMutableVideoCompositionInstruction()//VideoFilterCompositionInstruction(trackID: videoTrack.trackID, filters: self.filters, context: self.context)
      instruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.asset.duration)
      instruction.layerInstructions = [layerInstruction]
      
      let videoComposition = AVMutableVideoComposition()
//      videoComposition.customVideoCompositorClass = VideoFilterCompositor.self
      videoComposition.frameDuration = CMTimeMake(1, 30)
      videoComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
      videoComposition.instructions = [instruction]
      
      
    
      
      // 5 - Create Exporter
      guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { return }
      exporter.outputURL = url
      exporter.outputFileType = AVFileType.mov
      exporter.shouldOptimizeForNetworkUse = true
      exporter.videoComposition = videoComposition
      
      // 6 - Perform the Export
      exporter.exportAsynchronously() {
        DispatchQueue.main.async {
          completion(exporter)
//          self.exportDidFinish(exporter)
        }
      }
    
    
//    }
  }
  /*
    
  func export(toURL url: URL, @escaping callback: (_ url: URL?) -> Void){
    guard let track: AVAssetTrack = self.asset.tracks(withMediaType: AVMediaType.video).first else{callback(nil); return}
        
        let composition = AVMutableComposition()
        composition.naturalSize = track.naturalSize
        let videoTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        do{try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, self.asset.duration), of: track, at: kCMTimeZero)}
        catch _{callback(nil); return}
        
        if let audio = self.asset.tracks(withMediaType: AVMediaTypeAudio).first{
            do{try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, self.asset.duration), ofTrack: audio, atTime: kCMTimeZero)}
            catch _{callback(nil); return}
        }
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.trackID = videoTrack.trackID
        
        let instruction = VideoFilterCompositionInstruction(trackID: videoTrack.trackID, filters: self.filters, context: self.context)
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.asset.duration)
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = VideoFilterCompositor.self
        videoComposition.frameDuration = CMTimeMake(1, 30)
        videoComposition.renderSize = videoTrack.naturalSize
        videoComposition.instructions = [instruction]
        
        let session: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
        session.videoComposition = videoComposition
        session.outputURL = url
        session.outputFileType = AVFileTypeMPEG4
        
        session.exportAsynchronously(){
            DispatchQueue.main.async{
                callback(url)
            }
        }
    }
 
 */
}

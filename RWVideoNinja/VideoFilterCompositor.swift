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

class VideoFilterCompositor : NSObject, AVVideoCompositing{
  
  
  
  
  // For Swift 2.*, replace [String : Any] and [String : Any]? with [String : AnyObject] and [String : AnyObject]? respectively
  
  // You may alter the value of kCVPixelBufferPixelFormatTypeKey to fit your needs
  var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
    kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32),
    kCVPixelBufferOpenGLESCompatibilityKey as String : NSNumber(value: true),
    kCVPixelBufferOpenGLCompatibilityKey as String : NSNumber(value: true)
  ]
  
  // You may alter the value of kCVPixelBufferPixelFormatTypeKey to fit your needs
  var sourcePixelBufferAttributes: [String : Any]? = [
    kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32),
    kCVPixelBufferOpenGLESCompatibilityKey as String : NSNumber(value: true),
    kCVPixelBufferOpenGLCompatibilityKey as String : NSNumber(value: true)
  ]
  
  let renderQueue = DispatchQueue(label: "com.jojodmo.videofilterexporter.renderingqueue", attributes: [])
  let renderContextQueue = DispatchQueue(label: "com.jojodmo.videofilterexporter.rendercontextqueue", attributes: [])
  let transition = CIFilter.init(name: "CIDissolveTransition")
  var renderContext: AVVideoCompositionRenderContext!
  override init(){
    super.init()
    
//    self.transition?.setValue(CGPoint.init(x: 200, y: 500), forKey: "inputCenter")
//    self.transition?.setValue(CGRect.init(x: 0, y: 0, width: 720, height: 1280), forKey: "inputExtent")
    self.transition?.setValue(0.100, forKey: "inputTime")
    
  }
  
  func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
    autoreleasepool(){
      self.renderQueue.sync{
        guard let instruction = request.videoCompositionInstruction as? VideoFilterCompositionInstruction else{
          request.finish(with: NSError(domain: "jojodmo.com", code: 760, userInfo: nil))
          return
        }
        guard let pixels = request.sourceFrame(byTrackID: instruction.trackID[0]) else{
          request.finish(with: NSError(domain: "jojodmo.com", code: 761, userInfo: nil))
          return
        }
        
        guard let pixels2 = request.sourceFrame(byTrackID: instruction.trackID[1]) else{
          request.finish(with: NSError(domain: "jojodmo.com", code: 761, userInfo: nil))
          return
        }
        
        var image = CIImage(cvPixelBuffer: pixels)
        let image2 = CIImage(cvPixelBuffer: pixels2)
        
        transition?.setValue(image, forKey: "inputTargetImage")
        transition?.setValue(image2, forKey: "inputImage")
        let fimage = transition?.outputImage
        image = fimage ?? image
//        for filter in instruction.filters{
//          filter.setValue(image, forKey: kCIInputImageKey)
//          image = filter.outputImage ?? image
//          filter.setValue(image2, forKey: kCIInputImageKey)
//          image2 = filter.outputImage ?? image2
//        }
        
        let newBuffer: CVPixelBuffer? = self.renderContext.newPixelBuffer()
        
        if let buffer = newBuffer {
          instruction.context.render(image, to: buffer)
//          instruction.context.render(image2, to: buffer)
          request.finish(withComposedVideoFrame: buffer)
        }
        else{
          request.finish(withComposedVideoFrame: pixels)
          request.finish(withComposedVideoFrame: pixels2)
        }
      }
    }
  }
  
  func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext){
    self.renderContextQueue.sync{
      self.renderContext = newRenderContext
    }
  }
}


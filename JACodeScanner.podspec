Pod::Spec.new do |s|
  s.name         = "JACodeScanner"
  s.version      = "0.0.1"
  s.summary      = "A scanner framework"
  s.description  = <<-DESC
  A scanner framework which can recognize qrcode
                   DESC
  s.homepage     = "https://github.com/ishepherdMiner/JACodeScanner"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"
  s.license      = "MIT"
  s.author       = { "Jason" => "iJason92@yahoo.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/ishepherdMiner/JACodeScanner.git", :tag => "#{s.version}" }
  s.source_files =  "JACodeScanner/*.{h,m}"  
  s.resource = "JACodeScanner/**/*.bundle"
  s.public_header_files = "JACodeScanner/JACodeScanner.h"
  s.frameworks   = "UIKit", "QuartzCore","Foundation"
  s.requires_arc = true
  s.module_name  = "JACodeScanner"
  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }

end

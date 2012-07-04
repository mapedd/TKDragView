Pod::Spec.new do |s|
  s.name     = 'TKDragView'
  s.version  = '1.0.0'
  s.platform = :ios
  s.summary  = 'Universal draggable view'
  s.homepage = 'https://github.com/mapedd/TKDragView'
  s.author   = { 'Tomek Kuźma' => 'mapedd@gmail.com' }
  s.source   = { :git => 'https://github.com/fictorial/TKDragView.git', :tag => '1.0.0' }
  s.description  = 'Universal draggable view'
  s.source_files = 'TKDragViewDemo/TKDragView.{h,m}'
  s.clean_paths  = '*.png', 'TKDragViewDemo.xcodeproj', 'TKDragViewDemo'
  s.frameworks   = 'UIKit', 'CoreGraphics', 'Foundation'
  s.requires_arc = true
end

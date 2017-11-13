Pod::Spec.new do |s|
  s.name         = "GPLoadingMore"
  s.version      = "1.0.0"
  s.summary      = "Simple UIScrollView Category for Loading More, iOS 11 Supported."
  s.homepage     = "https://github.com/GeekSprite"
  s.license      = 'MIT'
  s.author       = { "GeekSprite" => "a1019448557@gmail.com" }
  s.source       = { :git => "https://github.com/GeekSprite/GPLoadingMore.git", :tag => "1.0.0" }
  s.platform     = :ios
  s.source_files = 'GPLoadingMoreViewDemo/GPLoadingMoreView'   
  s.framework    = 'QuartzCore'
  s.requires_arc = true
end

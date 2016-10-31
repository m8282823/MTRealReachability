
Pod::Spec.new do |s|
  s.name         = 'MTRealReachability'
  s.version      = '0.0.3'
  s.summary      = 'it is a little tools to monitor network'
  s.homepage     = 'https://github.com/m8282823/MTRealReachability'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors            = { 'martin' => 'martinwithxc@gmail.com' }
  s.social_media_url   = 'http://martin.nnoffice.cn'

  s.platform     = :ios, '8.0'

  s.ios.deployment_target = '8.0'
  s.source       = { :git => 'https://github.com/m8282823/MTRealReachability.git', :tag => s.version.to_s }

  s.source_files  = 'MTRealReachability/**/*.{h,m}'

  s.public_header_files = 'MTRealReachability/**/*.h'

  s.frameworks  = 'SystemConfiguration', 'QuartzCore', 'CoreGraphics', 'SystemConfiguration'
  s.requires_arc = true

end

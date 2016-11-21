Pod::Spec.new do |s|
  s.name = 'Blessing'
  s.version = '0.2'
  s.license = { :type => "MIT", :file => "LICENSE"}
  s.summary = 'httpdns'
  s.homepage = 'https://github.com/Xspyhack/Blessing'
  s.social_media_url = 'https://twitter.com/xspyhack'
  s.authors = { 'Alex' => 'xspyhack@gmail.com' }
  s.source = { :git => 'https://github.com/Xspyhack/Blessing.git', :tag => s.version }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Blessing/*.swift'

end

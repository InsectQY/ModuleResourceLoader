
Pod::Spec.new do |s|
  s.name             = 'ModuleResourceLoader'
  s.version          = '1.2.0'
  s.summary          = 'iOS Module resource loading tool'
  s.description      = <<-DESC
  iOS Module resource loading tool (supports dynamic and static libraries)
                       DESC

  s.homepage         = 'https://github.com/InsectQY/ModuleResourceLoader'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LeslieChen' => '704861917@qq.com' }
  s.source           = { :git => 'https://github.com/InsectQY/ModuleResourceLoader.git', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.source_files = 'ModuleResourceLoader/Classes/**/*'
  s.frameworks = 'UIKit'
end

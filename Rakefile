# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

require 'bubble-wrap/ui'
require 'motion-support/core_ext/time'
require 'motion-support/core_ext/module'
require 'motion-support/core_ext/object'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'TimePlane'
  app.deployment_target = '6.0'
  app.device_family = [:iphone, :ipad]
  app.version = '1.1'

  app.identifier = 'de.furrylabs.TimePlane'

  app.development do
    app.provisioning_profile = "/Users/tkadauke/Library/MobileDevice/Provisioning Profiles/58379186-5379-4AF1-A0B1-22B81A1BC892.mobileprovision"
    app.codesign_certificate = "iPhone Developer: Thomas Kadauke (D23Z75P2H7)"
  end

  app.release do
    app.provisioning_profile = '/Users/tkadauke/Library/MobileDevice/Provisioning Profiles/33D00025-824E-4E30-8B52-B358514E53F7.mobileprovision'
    app.codesign_certificate = "iPhone Distribution: Thomas Kadauke (AUCE642MYV)"
  end
end

task :icons do
  {
    '57x57' => 'Icon.png',
    '114x114' => 'Icon@2x.png',
    '72x72' => 'Icon-72.png',
    '144x144' => 'Icon-72@2x.png',
    '29x29' => 'Icon-Small.png',
    '58x58' => 'Icon-Small@2x.png',
    '50x50' => 'Icon-Small-50.png',
    '100x100' => 'Icon-Small-50@2x.png',
  }.each do |size, filename|
    sh "convert -resize #{size} app/assets/icon.png resources/#{filename}"
  end
end

Pod::Spec.new do |s|
s.name         = "OCRunner"
s.version      = "1.0.3"
s.summary      = "OCRunner"
s.description  = <<-DESC
Execute Objective-C code Dynamically. iOS hotfix SDK.
DESC
s.homepage     = "https://github.com/SilverFruity/OCRunner"
s.license      = "MIT"
s.author             = { "SilverFruity" => "15328044115@163.com" }
s.ios.deployment_target = "8.0"
s.source       = { :git => "https://github.com/SilverFruity/OCRunner.git", :tag => "#{s.version}" }
s.source_files  = "OCRunner/**/*.{h,m,c}"
s.vendored_libraries  = 'OCRunner/libffi/libffi.a'
s.dependency "ORPatchFile", "~> 1.0"
end


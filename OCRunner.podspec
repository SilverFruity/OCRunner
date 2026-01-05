Pod::Spec.new do |s|
s.name         = "OCRunner"
s.version      = "1.3.4"
s.summary      = "OCRunner"
s.description  = <<-DESC
Execute Objective-C code Dynamically. iOS hotfix SDK.
DESC
s.homepage     = "https://github.com/SilverFruity/OCRunner"
s.license      = "MIT"
s.author             = { "SilverFruity" => "389185764@qq.com" }
s.ios.deployment_target = "11.0"
s.source       = { :git => "https://github.com/SilverFruity/OCRunner.git", :tag => "#{s.version}" }
s.source_files  = "OCRunner/*.{h,m,c,mm}", "OCRunner/ORCoreImp/**/*.{h,m,c,mm}", "OCRunner/RunEnv/**/*.{h,m,c,mm}", "OCRunner/Util/**/*.{h,m,c,mm}"
s.ios.vendored_frameworks = 'OCRunner/libffi/libffi.xcframework'
s.dependency "ORPatchFile", "1.2.3"
end


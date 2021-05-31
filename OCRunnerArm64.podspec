Pod::Spec.new do |s|
s.name         = "OCRunnerArm64"
s.version      = "1.0.18"
s.summary      = "OCRunnerArm64"
s.description  = <<-DESC
Only Support Arm64, Execute Objective-C code Dynamically. iOS hotfix SDK.
DESC
s.homepage     = "https://github.com/SilverFruity/OCRunner"
s.license      = "MIT"
s.author             = { "SilverFruity" => "15328044115@163.com" }
s.ios.deployment_target = "9.0"
s.source       = { :git => "https://github.com/SilverFruity/OCRunner.git", :tag => "#{s.version}" }
s.source_files  = "OCRunner/*.{h,m,c}","OCRunner/ORCoreImp/**/*.{h,m,c,s}","OCRunner/RunEnv/*.{h,m,c}","OCRunner/Util/*.{h,m,c}"
s.pod_target_xcconfig = { 'VALID_ARCHS' => 'arm64 arm64e', 'VALID_ARCHS[sdk=iphonesimulator*]' => '' }
s.dependency "ORPatchFile", "1.0.4"
end


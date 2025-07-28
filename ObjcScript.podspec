Pod::Spec.new do |s|
s.name         = "ObjcScript"
s.version      = "1.0.0"
s.summary      = "ObjcScript"
s.description  = <<-DESC
Execute Objective-C source code as script. iOS hotfix SDK.
DESC
s.homepage     = "https://github.com/SilverFruity/OCRunner"
s.license      = "MIT"
s.author             = { "SilverFruity" => "15328044115@163.com" }
s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) OCRUNNER_OBJC_SOURCE=1',
}
s.user_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) OCRUNNER_OBJC_SOURCE=1',
}
s.ios.deployment_target = "9.0"
s.source       = { :git => "https://github.com/SilverFruity/OCRunner.git", :tag => "#{s.version}" }
s.source_files  = "OCRunner/*.{h,m,c,mm}", "OCRunner/ORCoreImp/**/*.{h,m,c,mm}", "OCRunner/RunEnv/**/*.{h,m,c,mm}", "OCRunner/Util/**/*.{h,m,c,mm}", "OCRunner/libffi/**/*.{h,m,c,mm}", "OCRunner/Server/**/*.{h,m,c,mm}"
s.ios.vendored_frameworks = 'OCRunner/libffi/libffi.xcframework'
s.dependency "oc2mangoLib", "1.2.3"
end


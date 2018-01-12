
Pod::Spec.new do |s|
s.name = 'HACameraView'
s.version = '1.2'
s.license = 'MIT'
s.summary = "Take auto profile picture"
s.homepage = "https://github.com/hamzaansari09/HACameraView"
s.author = { "Hamza Ansari" => "hamzaansari209@gmail.com" }
s.source = { :git => 'https://github.com/hamzaansari09/HACameraView.git', :tag => s.version }

s.ios.deployment_target = '9.0'
s.source_files = 'Source/*.swift'
end




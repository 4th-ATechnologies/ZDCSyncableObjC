Pod::Spec.new do |s|
	s.name         = "ZDCSyncableObjC"
	s.version      = "1.0.1"
	s.summary      = "Undo, redo & merge capabilities for plain objects in Objective-C."
	s.homepage     = "https://github.com/4th-ATechnologies/ZDCSyncableObjC"
	s.license      = 'MIT'

	s.author = {
		"Robbie Hanson" => "robbiehanson@deusty.com"
	}
	s.source = {
		:git => "https://github.com/4th-ATechnologies/ZDCSyncableObjC.git",
		:tag => s.version.to_s
	}

	s.osx.deployment_target = '10.10'
	s.ios.deployment_target = '10.0'
	s.tvos.deployment_target = '10.0'

	s.source_files = 'ZDCSyncable/*.{h,m}', 'ZDCSyncable/{Internal,Utilities}/*.{h,m}'
	s.private_header_files = 'ZDCSyncable/Internal/*.h'

end

Pod::Spec.new do |s|
  s.name				= "AFImage"
  s.version				= "0.1.0"
  s.summary				= "An async image loading and caching framework for iOS."
  s.description			= <<-DESC
						  An async image loading and caching framework for iOS.
						  DESC
  s.homepage			= "https://github.com/mlatham/AFImage"
  s.license				= "WTFPL"
  s.author				= { "Matt Latham" => "matt.e.latham@gmail.com" }
  s.social_media_url	= "https://twitter.com/mattlath"
  
  s.source				= { :git => "https://github.com/mlatham/AFImage.git", :tag => "v0.1.0" }
  s.source_files		= 'AFImage/Pod/**/*.{h,m}'
  s.public_header_files = 'AFImage/Pod/**/*.h'

  s.prefix_header_contents = '#import "AFImage-Includes.h"'

  s.platform			= :ios, "6.0"
  s.requires_arc		= true

end

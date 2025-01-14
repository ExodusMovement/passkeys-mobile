#
#  Be sure to run `pod spec lint Passkeys.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "Passkeys"
  spec.version      = "1.0.1"
  spec.summary      = "A short description of Passkeys."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
  A longer description of Passkeys.
                   DESC

  spec.homepage     = "https://github.com/ExodusMovement/passkeys-mobile/ios"

  spec.license      = "MIT"
  spec.author       = "ExodusMovement"

  spec.platform     = :ios, "15.0"

  spec.source       = { :http => "https://github.com/ExodusMovement/passkeys-mobile/archive/refs/tags/ios-1.0.1.tar.gz", :sha256 => "02aaef78b05570fd39540ca5aa655e869bf9e368ad2258aebd68a6acc3448185" }

  spec.source_files = 'ios/Sources/**/*.{swift,h,m}'
  spec.requires_arc = true

end

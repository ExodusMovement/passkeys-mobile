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
  spec.summary      = "Passkeys is used to interact with my.passkeys.network crypto signer. Checkout passkeys.foundation for more details."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
  Passkeys is used to interact with my.passkeys.network crypto signer. Checkout passkeys.foundation for more details.
                   DESC

  spec.homepage     = "https://github.com/ExodusMovement/passkeys-mobile/ios"

  spec.license      = "MIT"
  spec.author       = "ExodusMovement"

  spec.platform     = :ios, "15.0"

  spec.source       = { :http => "https://github.com/ExodusMovement/passkeys-mobile/archive/refs/tags/ios-1.0.1.tar.gz", :sha256 => "00f165f4d3a3b1327caa98ae29b4be4e894936bd27f7c76af4c8707ae9b1c8d7" }

  spec.source_files = 'ios/Sources/**/*.{swift,h,m}'
  spec.requires_arc = true

end

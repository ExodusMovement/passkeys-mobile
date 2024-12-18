#
#  Be sure to run `pod spec lint PasskeysMobile.podspec' to ensure this is a
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

  spec.name         = "PasskeysMobile"
  spec.version      = "0.1.0"
  spec.summary      = "A short description of PasskeysMobile."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
  A longer description of PasskeysMobile.
                   DESC

  spec.homepage     = "https://github.com/ExodusMovement/passkeys-webview-embedded/ios"

  spec.license      = "MIT"
  spec.author       = "ExodusMovement"

  spec.platform     = :ios, "15.0"

  spec.source       = { :http => "https://github.com/ExodusMovement/passkeys-webview-embedded/archive/refs/tags/ios-#{spec.version}.tar.gz", :sha256 => "607fdd515a4a1b45bb0861cddcda978988481c5bd6fdf1650c418007d45b62ea" }

  spec.source_files = 'Sources/**/*.{swift,h,m}'
  spec.requires_arc = true

end

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint libgit2dart.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'git2dart_binaries'
  s.version          = '1.11.1'
  s.summary          = 'Dart bindings to libgit2.'
  s.description      = <<-DESC
Dart bindings to libgit2.
                       DESC
  s.homepage         = 'https://github.com/DartGit-dev/git2dart_binaries'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Viktor Borisov' => 'vik.borisoff@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  # The libgit2 dylib's install_name is @rpath/libgit2.dylib,
  # so the file must be vendored under that exact name or dyld can't find
  # it inside the .app bundle at runtime. libssh2.1.dylib and libcrypto.3.dylib
  # are transitive dependencies of libgit2 and must also be declared here so
  # CocoaPods embeds and signs them into the bundle's Frameworks directory.
  s.vendored_libraries = ['libgit2.dylib', 'libssh2.1.dylib', 'libcrypto.3.dylib']

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end

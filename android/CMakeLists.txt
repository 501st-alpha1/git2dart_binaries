# CMakeLists.txt for Android platform
cmake_minimum_required(VERSION 3.10)

project(git2dart_binaries LANGUAGES C)

# For FFI plugins, we only need to bundle the native libraries
# Glob all .so files present in the ABI directory so that libgit2's runtime
# dependencies (libssh2, libssl, libcrypto) are bundled alongside it.
# Flutter will automatically include these in the APK under lib/${ANDROID_ABI}/
file(GLOB git2dart_bundled_so_files
  "${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/*.so"
)

set(git2dart_binaries_bundled_libraries
  ${git2dart_bundled_so_files}
  PARENT_SCOPE
)

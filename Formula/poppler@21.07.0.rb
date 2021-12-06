# 21.07.0
# Source: https://raw.githubusercontent.com/Homebrew/homebrew-core/master/Formula/poppler.rb
# Changes: cairo symbols, no bottle
class PopplerAT21070 < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base)"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-21.07.0.tar.xz"
  sha256 "e26ab29f68065de4d6562f0a3e2b5435a83ca92be573b99a1c81998fa286a4d4"
  license "GPL-2.0-only"
  head "https://gitlab.freedesktop.org/poppler/poppler.git"

  # https://gitlab.freedesktop.org/poppler/poppler/-/merge_requests/632
  # Publish internal cairo symbols within libpoppler library.
  patch :p1, "
diff --git a/CMakeLists.txt b/CMakeLists.txt
index d1d3653a..f5886709 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -324,6 +324,9 @@ endif()
 if(LCMS2_FOUND)
   include_directories(SYSTEM ${LCMS2_INCLUDE_DIR})
 endif()
+if(CAIRO_FOUND)
+  include_directories(SYSTEM ${CAIRO_INCLUDE_DIRS})
+endif()

 # Recent versions of poppler-data install a .pc file.
 # Use it to determine the encoding data path, if available.
@@ -458,6 +461,14 @@ set(poppler_SRCS
   splash/SplashXPath.cc
   splash/SplashXPathScanner.cc
 )
+if(CAIRO_FOUND)
+  set(poppler_SRCS ${poppler_SRCS}
+    poppler/CairoFontEngine.cc
+    poppler/CairoOutputDev.cc
+    poppler/CairoRescaleBox.cc
+  )
+  set(poppler_LIBS ${poppler_LIBS} ${CAIRO_LIBRARIES})
+endif()
 set(poppler_LIBS ${FREETYPE_LIBRARIES})
 if(FONTCONFIG_FOUND)
   set(poppler_LIBS ${poppler_LIBS} ${FONTCONFIG_LIBRARIES})
@@ -774,6 +785,9 @@ if(PKG_CONFIG_EXECUTABLE)
   if(ENABLE_GLIB)
     poppler_create_install_pkgconfig(poppler-glib.pc ${CMAKE_INSTALL_LIBDIR}/pkgconfig)
   endif()
+  if(CAIRO_FOUND)
+    poppler_create_install_pkgconfig(poppler-cairo.pc ${CMAKE_INSTALL_LIBDIR}/pkgconfig)
+  endif()
   if(ENABLE_CPP)
     poppler_create_install_pkgconfig(poppler-cpp.pc ${CMAKE_INSTALL_LIBDIR}/pkgconfig)
   endif()
"

  livecheck do
    url :homepage
    regex(/href=.*?poppler[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on "cmake" => :build
  depends_on "gobject-introspection" => :build
  depends_on "pkg-config" => :build
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "little-cms2"
  depends_on "nss"
  depends_on "openjpeg"
  depends_on "qt@5"

  uses_from_macos "gperf" => :build
  uses_from_macos "curl"

  conflicts_with "pdftohtml", "pdf2image", "xpdf",
    because: "poppler, pdftohtml, pdf2image, and xpdf install conflicting executables"

  resource "font-data" do
    url "https://poppler.freedesktop.org/poppler-data-0.4.10.tar.gz"
    sha256 "6e2fcef66ec8c44625f94292ccf8af9f1d918b410d5aa69c274ce67387967b30"
  end

  def install
    ENV.cxx11

    args = std_cmake_args + %w[
      -DBUILD_GTK_TESTS=OFF
      -DENABLE_BOOST=OFF
      -DENABLE_CMS=lcms2
      -DENABLE_GLIB=ON
      -DENABLE_QT5=ON
      -DENABLE_QT6=OFF
      -DENABLE_UNSTABLE_API_ABI_HEADERS=ON
      -DWITH_GObjectIntrospection=ON
    ]

    system "cmake", ".", *args
    system "make", "install"
    system "make", "clean"
    system "cmake", ".", "-DBUILD_SHARED_LIBS=OFF", *args
    system "make"
    lib.install "libpoppler.a"
    lib.install "cpp/libpoppler-cpp.a"
    lib.install "glib/libpoppler-glib.a"
    resource("font-data").stage do
      system "make", "install", "prefix=#{prefix}"
    end

    on_macos do
      libpoppler = (lib/"libpoppler.dylib").readlink
      [
        "#{lib}/libpoppler-cpp.dylib",
        "#{lib}/libpoppler-glib.dylib",
        "#{lib}/libpoppler-qt5.dylib",
        *Dir["#{bin}/*"],
      ].each do |f|
        macho = MachO.open(f)
        macho.change_dylib("@rpath/#{libpoppler}", "#{opt_lib}/#{libpoppler}")
        macho.write!
      end
    end
  end

  test do
    system "#{bin}/pdfinfo", test_fixtures("test.pdf")
  end
end
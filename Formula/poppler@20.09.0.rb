# 20.09.0
# Source: https://raw.githubusercontent.com/Homebrew/homebrew-core/master/Formula/poppler.rb
# Changes: cairo symbols, no bottle
class PopplerAT20090 < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base)"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-20.09.0.tar.xz"
  sha256 "4ed6eb5ddc4c37f2435c9d78ff9c7c4036455aea3507d1ce8400070aab745363"
  license "GPL-2.0-only"
  head "https://anongit.freedesktop.org/git/poppler/poppler.git"

  # https://gitlab.freedesktop.org/poppler/poppler/-/merge_requests/632
  # Publish internal cairo symbols within libpoppler library.
  patch :p1, "
diff --git a/CMakeLists.txt b/CMakeLists.txt
index e359288..94aad8b 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -283,6 +283,9 @@ endif()
 if(LCMS2_FOUND)
   include_directories(SYSTEM ${LCMS2_INCLUDE_DIR})
 endif()
+if(CAIRO_FOUND)
+  include_directories(SYSTEM ${CAIRO_INCLUDE_DIRS})
+endif()

 if(ENABLE_SPLASH)
   find_package(Boost 1.58.0)
@@ -427,6 +430,14 @@ if(ENABLE_SPLASH)
     splash/SplashXPathScanner.cc
   )
 endif()
+if(CAIRO_FOUND)
+  set(poppler_SRCS ${poppler_SRCS}
+    poppler/CairoFontEngine.cc
+    poppler/CairoOutputDev.cc
+    poppler/CairoRescaleBox.cc
+  )
+  set(poppler_LIBS ${poppler_LIBS} ${CAIRO_LIBRARIES})
+endif()
 if(FONTCONFIG_FOUND)
   set(poppler_LIBS ${poppler_LIBS} ${FONTCONFIG_LIBRARIES})
 endif()
"

  livecheck do
    url :homepage
    regex(/href=.*?poppler[._-]v?(\d+(?:\.\d+)*)\.t/i)
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
  depends_on "qt"

  uses_from_macos "curl"

  conflicts_with "pdftohtml", "pdf2image", "xpdf",
    because: "poppler, pdftohtml, pdf2image, and xpdf install conflicting executables"

  resource "font-data" do
    url "https://poppler.freedesktop.org/poppler-data-0.4.9.tar.gz"
    sha256 "1f9c7e7de9ecd0db6ab287349e31bf815ca108a5a175cf906a90163bdbe32012"
  end

  def install
    ENV.cxx11

    args = std_cmake_args + %w[
      -DBUILD_GTK_TESTS=OFF
      -DENABLE_CMS=lcms2
      -DENABLE_GLIB=ON
      -DENABLE_QT5=ON
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

    libpoppler = (lib/"libpoppler.dylib").readlink
    [
      "#{lib}/libpoppler-cpp.dylib",
      "#{lib}/libpoppler-glib.dylib",
      "#{lib}/libpoppler-qt5.dylib",
      *Dir["#{bin}/*"],
    ].each do |f|
      macho = MachO.open(f)
      macho.change_dylib("@rpath/#{libpoppler}", "#{lib}/#{libpoppler}")
      macho.write!
    end
  end

  test do
    system "#{bin}/pdfinfo", test_fixtures("test.pdf")
  end
end
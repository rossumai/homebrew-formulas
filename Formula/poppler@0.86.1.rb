# poppler-0.86.1
class PopplerAT0861 < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base)"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-0.86.1.tar.xz"
  sha256 "af630a277c8e194c31339c5446241834aed6ed3d4b4dc7080311e51c66257f6c"
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

  option "with-qt", "Build Qt5 backend"
  option "with-little-cms2", "Use color management system"
  option "with-nss", "Use NSS library for PDF signature validation"

  deprecated_option "with-qt4" => "with-qt"
  deprecated_option "with-qt5" => "with-qt"
  deprecated_option "with-lcms2" => "with-little-cms2"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "gobject-introspection"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "openjpeg"
  depends_on "qt" => :optional
  depends_on "little-cms2" => :optional
  depends_on "nss" => :optional

  conflicts_with "pdftohtml", "pdf2image", "xpdf",
    :because => "poppler, pdftohtml, pdf2image, and xpdf install conflicting executables"

  resource "font-data" do
    url "https://poppler.freedesktop.org/poppler-data-0.4.9.tar.gz"
    sha256 "1f9c7e7de9ecd0db6ab287349e31bf815ca108a5a175cf906a90163bdbe32012"
  end

  needs :cxx11 if build.with?("qt") || MacOS.version < :mavericks

  def install
    ENV.cxx11 if build.with?("qt") || MacOS.version < :mavericks

    args = std_cmake_args + %w[
      -DENABLE_UNSTABLE_API_ABI_HEADERS=ON
      -DENABLE_GLIB=ON
      -DBUILD_GTK_TESTS=OFF
      -DWITH_GObjectIntrospection=ON
    ]

    if build.with? "qt"
      args << "-DENABLE_QT5=ON"
    else
      args << "-DENABLE_QT5=OFF"
    end

    if build.with? "little-cms2"
      args << "-DENABLE_CMS=lcms2"
    else
      args << "-DENABLE_CMS=none"
    end

    system "cmake", ".", *args
    system "make", "install"
    resource("font-data").stage do
      system "make", "install", "prefix=#{prefix}"
    end

    libpoppler = (lib/"libpoppler.dylib").readlink
    ["#{lib}/libpoppler-cpp.dylib", "#{lib}/libpoppler-glib.dylib",
     *Dir["#{bin}/*"]].each do |f|
      macho = MachO.open(f)
      macho.change_dylib("@rpath/#{libpoppler}", "#{lib}/#{libpoppler}")
      macho.write!
    end
  end

  test do
    system "#{bin}/pdfinfo", test_fixtures("test.pdf")
  end
end

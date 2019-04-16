# poppler-0.62.0
# source: https://raw.githubusercontent.com/Homebrew/homebrew-core/695f3418708f57809fa84db570483ba79ed19096/Formula/poppler.rb
class PopplerAT0620 < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base)"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-0.62.0.tar.xz"
  sha256 "5b9a73dfd4d6f61d165ada1e4f0abd2d420494bf9d0b1c15d0db3f7b83a729c6"
  head "https://anongit.freedesktop.org/git/poppler/poppler.git"

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
    url "https://poppler.freedesktop.org/poppler-data-0.4.8.tar.gz"
    sha256 "1096a18161f263cccdc6d8a2eb5548c41ff8fcf9a3609243f1b6296abdf72872"
  end

  needs :cxx11 if build.with?("qt") || MacOS.version < :mavericks

  def install
    ENV.cxx11 if build.with?("qt") || MacOS.version < :mavericks

    args = std_cmake_args + %w[
      -DENABLE_XPDF_HEADERS=ON
      -DENABLE_GLIB=ON
      -DBUILD_GTK_TESTS=OFF
      -DWITH_GObjectIntrospection=ON
      -DENABLE_QT4=OFF
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

    # install extra cairo headers
    include.join("poppler").install "poppler/CairoFontEngine.h", "poppler/CairoOutputDev.h", "poppler/CairoRescaleBox.h"
  end

  test do
    system "#{bin}/pdfinfo", test_fixtures("test.pdf")
  end
end

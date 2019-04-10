# private Cairo headers for poppler-0.61.1
class PopplerPrivateCairoDevAT0611 < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base)"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-0.61.1.tar.xz"
  sha256 "1266096343f5163c1a585124e9a6d44474e1345de5cdfe55dc7b47357bcfcda9"

  def install
    # install extra cairo headers
    include.join("poppler").install "poppler/CairoFontEngine.h", "poppler/CairoOutputDev.h"
  end
end

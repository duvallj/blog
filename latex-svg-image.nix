{ mkDerivation, base, base64-bytestring, bytestring
, cryptohash-sha256, deepseq, directory, filepath, lib, parsec
, process, temporary, transformers
}:
mkDerivation {
  pname = "latex-svg-image";
  version = "0.2";
  src = latex-svg/latex-svg-image;
  libraryHaskellDepends = [
    base base64-bytestring bytestring cryptohash-sha256 deepseq
    directory filepath parsec process temporary transformers
  ];
  homepage = "http://github.com/phadej/latex-svg#readme";
  description = "A library for rendering LaTeX formulae as SVG using an actual LaTeX";
  license = lib.licenses.bsd3;
}

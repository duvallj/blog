{ mkDerivation, base, hakyll, latex-svg-image, latex-svg-pandoc
, lib, lrucache, pandoc-types
}:
mkDerivation {
  pname = "latex-svg-hakyll";
  version = "0.2";
  src = latex-svg/latex-svg-hakyll;
  libraryHaskellDepends = [
    base hakyll latex-svg-image latex-svg-pandoc lrucache pandoc-types
  ];
  homepage = "https://github.com/phadej/latex-svg#readme";
  description = "Use actual LaTeX to render formulae inside Hakyll pages";
  license = lib.licenses.bsd3;
}

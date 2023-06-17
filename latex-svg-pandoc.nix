{ mkDerivation, base, bytestring, directory, filepath
, latex-svg-image, lib, pandoc-types, text
}:
mkDerivation {
  pname = "latex-svg-pandoc";
  version = "0.2.1";
  src = latex-svg/latex-svg-pandoc;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    base bytestring directory filepath latex-svg-image pandoc-types
    text
  ];
  executableHaskellDepends = [ base latex-svg-image pandoc-types ];
  homepage = "http://github.com/phadej/latex-svg#readme";
  description = "Render LaTeX formulae in pandoc documents to images with an actual LaTeX";
  license = lib.licenses.bsd3;
  mainProgram = "latex-svg-filter";
}

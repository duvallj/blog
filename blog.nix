{ mkDerivation, base, binary, containers, hakyll
, hakyll-custom-goodies, latex-svg-hakyll, latex-svg-image
, latex-svg-pandoc, lib
}:
mkDerivation {
  pname = "blog";
  version = "0.3.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    base binary containers hakyll hakyll-custom-goodies
    latex-svg-hakyll latex-svg-image latex-svg-pandoc
  ];
  license = "unknown";
  mainProgram = "site";
}

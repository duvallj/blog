{ mkDerivation, base, binary, containers, hakyll
, hakyll-custom-goodies, latex-svg-hakyll, latex-svg-image
, latex-svg-pandoc, lib
}:
mkDerivation {
  pname = "blog";
  version = "0.4.0.1";
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

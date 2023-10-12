{ mkDerivation, base, containers, hakyll, lib, text, time }:
mkDerivation {
  pname = "hakyll-custom-goodies";
  version = "0.3.0.1";
  src = ./extra;
  libraryHaskellDepends = [ base containers hakyll text time ];
  description = "Some nice utilities I developed for my Hakyll site";
  license = lib.licenses.gpl3Only;
}

let
  config = {
    packageOverrides = pkgs: rec {
      haskellPackages = pkgs.haskellPackages.override {
        overrides = haskellPackagesNew: haskellPackagesOld: rec {
          hakyll =
            haskellPackagesNew.callPackage ./hakyll.nix { };

          hakyll-custom-goodies =
            haskellPackagesNew.callPackage ./extra.nix { };

          latex-svg-hakyll =
            haskellPackagesNew.callPackage ./latex-svg-hakyll.nix { };

          latex-svg-image =
            haskellPackagesNew.callPackage ./latex-svg-image.nix { };

          latex-svg-pandoc =
            haskellPackagesNew.callPackage ./latex-svg-pandoc.nix { };

          blog =
            haskellPackagesNew.callPackage ./blog.nix { };
        };
      };
    };
  };

  pkgs = import <nixpkgs> { inherit config; };

in
  {
    blog = pkgs.haskellPackages.blog;
  }

{
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    nixpkgs-22_11.url = "github:NixOS/nixpkgs/22.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    ## See https://input-output-hk.github.io/cardano-haskell-packages/
    CHaP = {
      url = "github:input-output-hk/cardano-haskell-packages?ref=repo";
      flake = false;
    };
  };

  outputs = { self, flake-utils, CHaP, haskellNix, nixpkgs, ...}@inputs:
    (flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        internal-lib = import ./internal-lib.nix;
        rootProject = internal-lib.make-haskell-nix-pkg {
          inherit (inputs) haskellNix CHaP;
          inherit pkgs;
          src = "${self}/vesting";
          compiler-nix-name = "ghc8107";
        };
        flake = rootProject.flake { };
        lang = if system == "x86_64-darwin" then "C" else "C.UTF-8";
      in
      {
        packages.vesting = flake.packages."vesting:lib:vesting";
        packages.default = flake.packages."certification:lib:certification";

        devShells.default = rootProject.shellFor {
          buildInputs = [
            ## For UTF-8 locales
            pkgs.glibcLocales
          ];
          LANG = lang;
        };

        legacyPackages = rootProject;
        iog.dapp = rootProject;
      })) // {
        iog.dapp = self.legacyPackages.x86_64-linux;
      };

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://cache.zw3rk.com"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "loony-tools:pr9m4BkM/5/eSTZlkQyRt57Jz7OMBxNSUiMC4FkcNfk="
    ];
    allow-import-from-derivation = true;
    accept-flake-config = true;
  };

}

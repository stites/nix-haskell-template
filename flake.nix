{
  inputs = {
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    stackageSrc = {
      url = "github:input-output-hk/stackage.nix";
      flake = false;
    };
    hackageSrc = {
      url = "github:input-output-hk/hackage.nix";
      flake = false;
    };
    utils.url = "github:numtide/flake-utils";
    devshell.url = "github:numtide/devshell";
  };

  outputs = inputs@{ self, nixpkgs, haskell-nix, utils, devshell, ... }:
    let
      name = "PACKAGE-NAME";
      compiler = "ghc8104"; # Not used for `stack.yaml` based projects.

      # This overlay adds our project to pkgs
      project-overlay = final: prev: {
        "${name}Project" = let
          supported-compilers = builtins.fetchurl {
            url = "https://raw.githubusercontent.com/input-output-hk/haskell.nix/master/docs/reference/supported-ghc-versions.md";
            sha256 = "sha256:1b1h8l6rbg9f31i8pmaskg95by1p6jjlribkyyklah0zyb8yv8aa";
          };

          in
            #assert compiler == supported-compilers;
            final.haskell-nix.project' {
              # 'cleanGit' cleans a source directory based on the files known by git
              src = prev.haskell-nix.haskellLib.cleanGit {
                inherit name;
                src = ./.;
              };

              compiler-nix-name = compiler; # Not used for `stack.yaml` based projects.
              projectFileName = "cabal.project"; # Not used for `stack.yaml` based projects.
            };
      };
    in
      { overlay = final: prev: {
          "${name}" = ("${name}Project-overlay" final prev)."${name}Project".flake {};
        };
      } // (utils.lib.eachSystem [ "x86_64-linux" ] (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              devshell.overlay
              haskell-nix.overlay
              (final: prev: {
                haskell-nix = prev.haskell-nix // {
                  sources = prev.haskell-nix.sources // {
                    hackage = inputs.hackageSrc;
                    stackage = inputs.stackageSrc;
                  };
                };
              })
              project-overlay
            ];
          };
          flake = pkgs."${name}Project".flake {};
        in flake // rec {

          packages.${name} = flake.packages."${name}:exe:${name}";

          defaultPackage = packages.${name};

          # This is used by `nix develop .` to open a shell for use with
          # `cabal`, `hlint` and `haskell-language-server`
          devShell = pkgs."${name}Project".shellFor {
            # Some you may need to get some other way.
            # buildInputs = with pkgs.haskellPackages;
            buildInputs = with pkgs; [gdb lldb];

            # Builds a Hoogle documentation index of all dependencies,
            # and provides a "hoogle" command to search the index.
            withHoogle = true;

            # probably unnessecary
            # ==================================
            # shellHook = ''
            #   export LD_LIBRARY_PATH=${lib.makeLibraryPath buildInputs}:$LD_LIBRARY_PATH
            #   export LANG=en_US.UTF-8
            # '';
            # LOCALE_ARCHIVE =
            #   if stdenv.isLinux
            #   then "${glibcLocales}/lib/locale/locale-archive"
            #   else "";

            # Prevents cabal from choosing alternate plans, so that
            # *all* dependencies are provided by Nix.
            exactDeps = true;

            tools = {
              cabal = "latest";
              hlint = "latest";
              haskell-language-server = "latest";
              ghcide = "latest";
              ghcid = "latest";
            };
          };
        }));
}

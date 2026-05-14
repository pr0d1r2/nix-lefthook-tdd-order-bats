{
  description = "Lefthook-compatible TDD order enforcer for bats, packaged as a Nix flake";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-dev-shell-agentic = {
      url = "github:pr0d1r2/nix-dev-shell-agentic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-unicode-lint = {
      url = "github:pr0d1r2/nix-lefthook-unicode-lint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-dev-shell-agentic,
      ...
    }@inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default =
          let
            isExcludedPath = pkgs.writeText "is-excluded-path.sh" (builtins.readFile ./is-excluded-path.sh);
            specPathForFile = pkgs.writeText "spec-path-for-file.sh" (
              builtins.readFile ./spec-path-for-file.sh
            );
          in
          pkgs.writeShellApplication {
            name = "lefthook-tdd-order-bats";
            runtimeInputs = [
              pkgs.git
              pkgs.gnused
              pkgs.coreutils
            ];
            text =
              builtins.replaceStrings
                [
                  "@IS_EXCLUDED_PATH@"
                  "@SPEC_PATH_FOR_FILE@"
                ]
                [
                  "${isExcludedPath}"
                  "${specPathForFile}"
                ]
                (builtins.readFile ./lefthook-tdd-order-bats.sh);
          };
      });

      devShells = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          shells = nix-dev-shell-agentic.lib.mkShells {
            inherit pkgs inputs;
            ciPackages = [
              self.packages.${system}.default
            ];
            shellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${shells.batsWithLibs}" ] (
              builtins.readFile ./dev.sh
            );
          };
        in
        shells
      );
    };
}

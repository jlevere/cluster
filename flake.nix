{
  description = "A Nix-flake-based development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        venvDir = ".venv";
        packages = with pkgs;
          [python312]
          ++ (with pkgs.python312Packages; [
            pip
            venvShellHook
            uv
            kubectl
            ansible-core
            pkgs.ansible-lint
            mkpasswd
            go-task
            kubernetes-helm
          ]);
      };
    });
  };
}

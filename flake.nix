{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
  }: let system = "x86_64-linux"; pkgs = nixpkgs.legacyPackages.${system}; in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [ pkgs.typst pkgs.saxonb_9_1 ];
    };
  };
}

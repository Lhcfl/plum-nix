{
  description = "Home Manager configuration of linca";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plum-nix.url = "path:..";
  };

  outputs =
    { nixpkgs, home-manager, plum-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations.test = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix plum-nix.homeModules.default ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}

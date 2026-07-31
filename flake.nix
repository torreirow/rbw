{
  description = "Unofficial Bitwarden CLI with background agent";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;
        in
        {
          rbw = pkgs.rustPlatform.buildRustPackage {
            pname = "rbw";
            inherit version;
            src = ./.;

            # No hash to maintain — Nix reads Cargo.lock directly.
            cargoLock.lockFile = ./Cargo.lock;

            nativeBuildInputs = with pkgs; [ installShellFiles ]
              ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkg-config ];

            # wayland is only needed for the clipboard feature on Linux.
            buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.wayland ];

            # Enable clipboard integration on Linux; macOS uses AppKit (no wayland).
            buildFeatures = pkgs.lib.optionals pkgs.stdenv.isLinux [ "clipboard" ];

            postInstall = ''
              installShellCompletion --cmd rbw \
                --bash <($out/bin/rbw gen-completions bash) \
                --zsh  <($out/bin/rbw gen-completions zsh) \
                --fish <($out/bin/rbw gen-completions fish)
            '';

            meta = with pkgs.lib; {
              description = "Unofficial Bitwarden CLI with background agent";
              homepage = "https://github.com/torreirow/rbw";
              license = licenses.mit;
              mainProgram = "rbw";
            };
          };
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.rbw);

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ rustc cargo clippy rustfmt ]
              ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkg-config wayland ];
          };
        });
    };
}

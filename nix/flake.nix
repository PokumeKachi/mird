{
    description = "Mird - Bevy game";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    outputs =
        { self, nixpkgs }:
        let
            systems = [ "x86_64-linux" ];

            forAllSystems = nixpkgs.lib.genAttrs systems;

            perSystem =
                system:
                let
                    pkgs = import nixpkgs { inherit system; };

                    runtimeLibs = with pkgs; [
                        alsa-lib
                        libudev-zero
                        libx11
                        libxcursor
                        libxi
                        libxrandr
                        libxkbcommon
                        wayland
                        vulkan-loader
                    ];

                    buildTools = with pkgs; [
                        pkg-config
                        cmake
                        rustc
                        cargo
                        rustfmt
                        clippy
                    ];

                    common = {
                        nativeBuildInputs = buildTools;
                        buildInputs = runtimeLibs;
                    };

                    runtimeLibraryPath = pkgs.lib.makeLibraryPath runtimeLibs;
                in
                {
                    inherit
                        pkgs
                        common
                        runtimeLibs
                        runtimeLibraryPath
                        ;
                };
        in
        {
            packages = forAllSystems (
                system:
                let
                    ps = perSystem system;
                in
                {
                    default = ps.pkgs.rustPlatform.buildRustPackage {
                        pname = "mird";
                        version = "0.1.0";

                        src = ps.pkgs.lib.cleanSource ./.;

                        cargoLock.lockFile = ./Cargo.lock;

                        inherit (ps.common)
                            nativeBuildInputs
                            buildInputs
                            ;

                        # Make dynamically linked libraries available
                        # when launching the packaged game.
                        postFixup = ''
                            patchelf \
                              --set-rpath "${ps.runtimeLibraryPath}" \
                              "$out/bin/mird"
                        '';
                    };
                }
            );

            devShells = forAllSystems (
                system:
                let
                    ps = perSystem system;
                in
                {
                    default = ps.pkgs.mkShell {
                        inherit (ps.common)
                            nativeBuildInputs
                            buildInputs
                            ;

                        LD_LIBRARY_PATH = ps.runtimeLibraryPath + ":" + (builtins.getEnv "LD_LIBRARY_PATH");
                    };
                }
            );
        };
}

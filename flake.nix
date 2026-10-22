{
  description = "PostgreSQL 18 OCI image built with Nix dockerTools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      postgres = pkgs.postgresql_18;
      image = pkgs.dockerTools.buildLayeredImage {
        name = "postgresql";
        tag = postgres.version;
        contents = [ postgres pkgs.dockerTools.fakeNss pkgs.bash ];

        config = {
          User = "10001:10001";
          WorkingDir = "/var/lib/postgresql/data";
          Entrypoint = [ "${postgres}/bin/postgres" ];
          Cmd = [ "-D" "/var/lib/postgresql/data" "-c" "unix_socket_directories=/tmp" ];
          Env = [ "PGDATA=/var/lib/postgresql/data" "HOME=/tmp" ];
          ExposedPorts = { "5432/tcp" = { }; };
          Volumes = { "/var/lib/postgresql/data" = { }; };
        };

        fakeRootCommands = ''
          mkdir -p ./var/lib/postgresql/data ./tmp
          chown -R 10001:10001 ./var/lib/postgresql
          chmod 0700 ./var/lib/postgresql/data
          chmod 1777 ./tmp
        '';
      };
    in {
      packages.${system} = {
        inherit image;
        default = image;
      };
      checks.${system} = { inherit image; };
    };
}

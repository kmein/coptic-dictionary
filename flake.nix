{
  description = "Coptic dictionary files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    kellia-dictionary.url = "github:KELLIA/dictionary";
    kellia-dictionary.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    kellia-dictionary,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = nixpkgs.lib;

    coptic-dictionary-xml = "${kellia-dictionary.outPath}/xml/Comprehensive_Coptic_Lexicon-v1.2-2020.xml";

    buildCopticDictionary = {wide ? false}: ''
      ${pkgs.typst}/bin/typst compile ${pkgs.writeText "coptic-dictionary.typ" ''
          #{
            // https://github.com/typst/typst/issues/199
            import "/${pkgs.runCommand "entries.typ" {} ''
              ${pkgs.saxonb_9_1}/bin/saxonb -s:${lib.escapeShellArg coptic-dictionary-xml} -xsl:${./tei2typst.xslt} -o:$out
            ''}": entries
            import "/${./render.typ}": render_entry

            show par: set block(spacing: 0mm)
            set page(columns: ${toString (if wide then 4 else 2)}, margin: 5%, flipped: ${if wide then "true" else "false"})
            set columns(gutter: 5pt)
            set text(10pt, lang:"de", hyphenate: auto)

            for entry in entries {
              render_entry(entry)
            }
          }
      ''} $out
    '';
  in {
    packages.${system} = rec {
      inherit coptic-dictionary-xml;

      coptic-stardict = pkgs.runCommand "coptic" {} ''
        mkdir $out
        ${pkgs.saxonb_9_1}/bin/saxonb -s:${lib.escapeShellArg coptic-dictionary-xml} -xsl:${./tei2babylon.xslt} -o:coptic.babylon
        PATH=${lib.makeBinPath [stardict-tools pkgs.dict]} babylon coptic.babylon
        mv coptic.{idx,ifo,syn,dict.dz} $out
      '';

      coptic-pdf-landscape = pkgs.runCommand "coptic-dictionary-landscape.pdf" {} (buildCopticDictionary {wide = true;});

      coptic-pdf = pkgs.runCommand "coptic-dictionary.pdf" {} (buildCopticDictionary {wide = false;});

      stardict-tools = pkgs.stdenv.mkDerivation {
        name = "stardict-tools";
        nativeBuildInputs = [
          pkgs.autoreconfHook
          pkgs.pkg-config
          pkgs.which
          pkgs.libtool
        ];
        buildInputs = [ pkgs.glib pkgs.zlib pkgs.gtk3 pkgs.libmysqlclient pkgs.pcre pkgs.libxml2];
        buildPhase = "make";
        configureFlags = ["--disable-dict"];
        env.NIX_CFLAGS_COMPILE = toString [
          "-Wno-error=format-security"
        ];
        patchPhase = ''
          ${pkgs.gnused}/bin/sed -i s/noinst_PROGRAMS/bin_PROGRAMS/ tools/src/Makefile.am
        '';
        installFlags = [ "INSTALL_PREFIX=$(out)" ];
        autoreconfPhase = ''
          patchShebangs ./autogen.sh
          ./autogen.sh
        '';
        installPhase = ''
          mkdir $out
          make install
        '';
        src = pkgs.fetchFromGitHub {
          owner = "huzheng001";
          repo = "stardict-3";
          rev = "96b96d89eab5f0ad9246c2569a807d6d7982aa84";
          hash = "sha256-zmqp2maKv2JZ5fwMVE7gIOg0BKdEKZ4UvTLC0suuBRw=";
        };
      };
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.typst
        pkgs.saxonb_9_1
        self.packages.${system}.stardict-tools
        pkgs.dict # dictzip
        (pkgs.python3.withPackages (py: [
          py.jupyter
          py.pandas
          py.numpy
          py.scipy
          py.seaborn
          py.matplotlib
        ]))
      ];
    };
  };
}

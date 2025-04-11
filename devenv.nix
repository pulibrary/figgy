{ pkgs, lib, config, inputs, ... }:

let
  podman_4_9 = import inputs.podman_4_9 { system = pkgs.stdenv.system; };
  gdal_3_6_4 = import inputs.gdal_3_6_4 { system = pkgs.stdenv.system; };
  tippecanoe_2_35_0 = import inputs.tippecanoe_2_35_0 { system = pkgs.stdenv.system; };
  officialpkgs = import inputs.officialpkgs { system = pkgs.stdenv.system; };
in
{
  # https://devenv.sh/basics/
  env.GREET = "devenv";
  env.lando_figgy_database_conn_host = "127.0.0.1";
  env.lando_figgy_database_conn_port = "9550";
  env.lando_figgy_database_creds_user = "postgres";
  env.lando_figgy_database_creds_password = "password";
  env.lando_figgy_test_solr_conn_host = "127.0.0.1";
  env.lando_figgy_test_solr_conn_port = "9551";
  env.lando_figgy_devopment_solr_conn_host = "127.0.0.1";
  env.lando_figgy_devopment_solr_conn_port = "9552";
  env.lando_redis_conn_host = "127.0.0.1";
  env.lando_redis_conn_port = "9553";
  env.TMPDIR = "/private/tmp";
  env.LD_LIBRARY_PATH = "${config.devenv.profile}/lib";
  env.FONTCONFIG_PATH = "${config.devenv.profile}/etc/fonts";

  # https://devenv.sh/packages/
  packages =
    [
      pkgs.git
      podman_4_9.podman
      officialpkgs.qemu
      officialpkgs.postgresql_15
      officialpkgs.wait4x
      officialpkgs.openssh
      officialpkgs.vips
      officialpkgs.jq
      officialpkgs.libffi
      officialpkgs.poppler
      officialpkgs.fontconfig
      officialpkgs.imagemagick6
      officialpkgs.tesseract4
      officialpkgs.mediainfo
      officialpkgs.ocrmypdf
      officialpkgs.lastpass-cli
      officialpkgs.openjpeg
      officialpkgs.unzip
      officialpkgs.zip
      officialpkgs.lsof
      officialpkgs.ffmpeg_4
      gdal_3_6_4.gdal
      tippecanoe_2_35_0.tippecanoe
    ];

  languages.ruby.enable = true;
  languages.ruby.version = "3.2.6";

  languages.python.enable = true;
  languages.python.venv.requirements = "cogeo-mosaic";
  languages.python.venv.enable = true;
  languages.python.version = "3.9.1";

  languages.javascript.enable = true;
  languages.javascript.package = officialpkgs.nodejs_22;
  languages.javascript.yarn.enable = true;

  languages.java.jdk.package = officialpkgs.jdk8;

  enterShell = ''
  '';


  processes.postgresql = {
    exec = ''
      podman -c devenv run -e POSTGRES_PASSWORD=password --rm --name figgy_db -p 9550:5432 postgres:15
      '';

    process-compose = {
      shutdown = {
        command = "podman stop figgy_db";
      };
    };
  };

  processes.test_solr = {
    exec = ''
      podman -c devenv run -v /mnt/$(pwd)/solr/config/:/figgy_core/conf --rm --name figgy_test_solr -p 9551:8983 solr:7 solr-precreate figgy-core-test /figgy_core
      '';

    process-compose = {
      shutdown = {
        command = "podman stop figgy_test_solr";
      };
    };
  };

  processes.dev_solr = {
    exec = ''
      podman -c devenv run -v /mnt/$(pwd)/solr/config/:/figgy_core/conf --rm --name figgy_dev_solr -p 9552:8983 solr:7 solr-precreate figgy-core-dev /figgy_core
      '';

    process-compose = {
      shutdown = {
        command = "podman stop figgy_dev_solr";
      };
    };
  };

  processes.redis = {
    exec = ''
      podman -c devenv run --rm --name figgy_redis -p 9553:6379 redis
      '';

    process-compose = {
      shutdown = {
        command = "podman stop figgy_redis";
      };
    };
  };

  processes.chrome = {
    exec = ''
      podman -c devenv run -e START_XVFB=true -e SE_NODE_MAX_SESSIONS=20 -e SE_NODE_OVERRIDE_MAX_SESSIONS=true --rm --name figgy_chrome -p 4445:4444 -p 5900:5900 -p 7900:7900 -v /dev/shm:/dev/shm seleniarm/standalone-chromium:114.0
      '';

    process-compose = {
      shutdown = {
        command = "podman stop figgy_chrome";
      };
    };
  };

  scripts.setup = {
    exec = ''
      devenv tasks run app:setup
    '';
    binary = "bash";
    description = "Prepare everything";
  };

  scripts.tests = {
    exec = ''
      setup
      ./bin/parallel_rspec_coverage
    '';
    binary = "bash";
    description = "Run tests";
  };

  scripts.poweroff = {
    exec = ''
      devenv processes down > /dev/null 2>&1 || true
      podman machine stop devenv > /dev/null 2>&1 || true
      echo "Boomshakalaka"
    '';
  };

  scripts.clean = {
    exec = ''
      poweroff
      podman machine rm devenv -y > /dev/null 2>&1 || true
      echo "All services stopped & deleted"
    '';
  };

  tasks = {
    "app:setup" = {
      exec = ''
        bin/vite build --clear --mode=test
      '';
      after = [ "app:db_setup" ];
    };
    "app:db_setup" = {
      exec = ''
        wait4x -q -t 5m tcp localhost:9551 localhost:9552 localhost:9553 localhost:9550
        PARALLEL_TEST_FIRST_IS_1=true RAILS_ENV=test rake parallel:setup || true
        RAILS_ENV=test rake db:create || true
        RAILS_ENV=test rake db:migrate || true
        RAILS_ENV=development rake db:create || true
        RAILS_ENV=development rake db:migrate || true
      '';
      after = [ "app:bundle" ];
    };
    "app:bundle" = {
      exec = ''
        bundle install
      '';
      after = [ "processes:start" ];
    };
    "app:yarn_install" = {
      exec = ''
        yarn install
      '';
      after = [ "processes:start" ];
    };
    "processes:start" = {
      exec = ''
        devenv processes up -d
      '';
      status = ''
        output=$(wait4x -q -t 5s tcp localhost:9551 localhost:9552 localhost:9553 localhost:9550)
      '';
      after = [ "podman:start" ];
    };
    "podman:init" = {
      exec = ''
        podman machine init -m 8192 -v $HOME:/mnt/$HOME devenv
        '';
      status = ''
        output=$(podman machine list --format json | jq '.[] | select(.Name=="devenv")' -e)
      '';
      before = [ "podman:start" ];
    };
    "podman:start" = {
      exec = ''
        podman machine start devenv
        '';
      status = ''
        output=$(podman machine list --format json | jq '.[] | select(.Name=="devenv").Running' -e)
        '';
    };
  };

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}

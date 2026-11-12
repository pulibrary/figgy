variable "branch_or_sha" {
  type    = string
  default = "main"
}

locals {
  job_name = "figgy-staging"
  image    = "ghcr.io/pulibrary/figgy:${var.branch_or_sha}"
  workers = {
    worker          = { count = 2, cpu = 4000, memory = 8192, command = "bundle exec sidekiq -c 5 -q high -q mailers -q default -q low -q super_low" }
    realtime-worker = { count = 2, cpu = 1000, memory = 2048, command = "bundle exec sidekiq -c 1 -q realtime" }
    bulk-worker     = { count = 2, cpu = 2000, memory = 4096, command = "bundle exec sidekiq -c 1 -q bulk -q bulk_low" }
    pubsub-worker   = { count = 1, cpu = 500, memory = 1024, command = "bundle exec rake figgy:fixity:run_worker" }
    pdf-watcher     = { count = 1, cpu = 500, memory = 1024, command = "bundle exec bin/pdf_watcher" }
    cron            = { count = 1, cpu = 1000, memory = 2048, command = "bundle exec whenever --roles db,worker_db --set environment=$RAILS_ENV > tmp/crontab && exec supercronic tmp/crontab" }
  }
  env = <<-EOF
    {{- with nomadVar "nomad/jobs/figgy-staging" -}}
    RAILS_ENV = 'staging'
    APPLICATION_HOST = 'figgy-staging.princeton.edu'
    APPLICATION_HOST_PROTOCOL = 'https'
    SECRET_KEY_BASE = '{{ .SECRET_KEY_BASE }}'
    REACT_APP_SECRET = '{{ .SECRET_KEY_BASE }}'
    REACT_APP_API_URL = 'https://figgy-staging.princeton.edu/browse'
    FIGGY_DB = 'figgy_staging'
    FIGGY_DB_HOST = 'figgy-db-staging1.princeton.edu'
    FIGGY_DB_USERNAME = '{{ .FIGGY_DB_USERNAME }}'
    FIGGY_DB_PASSWORD = '{{ .FIGGY_DB_PASSWORD }}'
    FIGGY_DB_RO_USERNAME = '{{ .FIGGY_DB_RO_USERNAME }}'
    FIGGY_DB_RO_PASSWORD = '{{ .FIGGY_DB_RO_PASSWORD }}'
    FIGGY_RABBIT_SERVER = '{{ .FIGGY_RABBIT_SERVER }}'
    FIGGY_REDIS_DB = '0'
    FIGGY_REDIS_PASSWORD = '{{ .FIGGY_REDIS_PASSWORD }}'
    FIGGY_READ_ONLY_MODE = '{{ .FIGGY_READ_ONLY_MODE }}'
    FIGGY_PUDL_ROOT = '{{ .FIGGY_PUDL_ROOT }}'
    FIGGY_AWS_ACCESS_KEY_ID = '{{ .FIGGY_AWS_ACCESS_KEY_ID }}'
    FIGGY_AWS_SECRET_ACCESS_KEY = '{{ .FIGGY_AWS_SECRET_ACCESS_KEY }}'
    SOLR_URL = 'http://lib-solr9-staging.princeton.edu:8983/solr/figgy-staging'
    PULMAP_SOLR_URL = 'http://lib-solr9-staging.princeton.edu:8983/solr/pulmap-staging'
    HONEYBADGER_API_KEY = '{{ .HONEYBADGER_API_KEY }}'
    INGEST_FOLDER_PATH = '/mnt/hydra_sources'
    ACTIVE_STORAGE_ROOT = '/mnt/diglibdata/hydra_binaries/active_storage/staging'
    STORAGE_CREDENTIALS = '/secrets/google_cloud_credentials.json'
    STORAGE_PROJECT = 'pulibrary-figgy-storage-1'
    GOOGLE_CLOUD_CREDENTIALS = '/secrets/google_cloud_credentials.json'
    GOOGLE_CLOUD_PROJECT = 'pulibrary-figgy-storage-1'
    READING_ROOM_IPS = '{{ .READING_ROOM_IPS }}'
    MAGICK_HEIGHT_LIMIT = '215MP'
    MAGICK_WIDTH_LIMIT = '215MP'
    MAGICK_AREA_LIMIT = '132GP'
    PYRAMIDAL_URL = 'https://iiif-cloud-staging.princeton.edu/iiif/2/'
    OCR_IN_PATH = '/rails/tmp/ocr_in'
    OCR_OUT_PATH = '/rails/tmp/ocr_out'
    OCR_ILLIAD_IN_PATH = '/rails/tmp/ocr_in'
    OCR_ILLIAD_OUT_PATH = '/mnt/hosted_illiad/RequestScans/images'
    CDL_IN_PATH = '/rails/tmp/cdl_in'
    ASPACE_URL = 'https://aspace-staging.princeton.edu/staff/api'
    ASPACE_USER = '{{ .ASPACE_USER }}'
    ASPACE_PASSWORD = '{{ .ASPACE_PASSWORD }}'
    TILESERVER_URL = 'https://map-tiles-staging.princeton.edu'
    PULFALIGHT_UNPUBLISHED_TOKEN = '{{ .PULFALIGHT_UNPUBLISHED_TOKEN }}'
    OPEN_GEODATA_URL = 'https://geodata-staging.lib.princeton.edu'
    RESTRICTED_GEODATA_URL = 'https://geodata-restricted-staging.lib.princeton.edu'
    NODE_OPTIONS = '--openssl-legacy-provider'
    PLAUSIBLE_API_KEY = '{{ .PLAUSIBLE_API_KEY }}'
    SMB_PLUM = '{{ .SMB_PLUM }}'
    SMB_PUDL = '{{ .SMB_PUDL }}'
    SMB_MAPLAB = '{{ .SMB_MAPLAB }}'
    SMB_NUMIS = '{{ .SMB_NUMIS }}'
    SMB_STUDIO = '{{ .SMB_STUDIO }}'
    SMB_MARQUAND = '{{ .SMB_MARQUAND }}'
    SMB_MENDEL = '{{ .SMB_MENDEL }}'
    SMB_MUDD = '{{ .SMB_MUDD }}'
    SMB_MICROFORMS = '{{ .SMB_MICROFORMS }}'
    SMB_ILLIAD = '{{ .SMB_ILLIAD }}'
    {{- end -}}
  EOF
  nfs_options = "addr=tigerdata-nfs.princeton.edu,nfsvers=3,mountport=2049,port=2049,nolock,proto=tcp"
  mounts = {
    "/opt/repository/files"                      = { type = "nfs", device = ":/figgy/staging/files", o = local.nfs_options }
    "/opt/repository/derivatives"                = { type = "nfs", device = ":/figgy/staging/derivatives", o = local.nfs_options }
    "/opt/repository/stream_derivatives"         = { type = "nfs", device = ":/figgy/staging/stream_derivatives", o = local.nfs_options }
    "/opt/repository/fallback_files"             = { type = "cifs", device = "//diglibdata1.princeton.edu/hydra/binaries/figgy_staging", o = "addr=diglibdata1.princeton.edu,uid=1001,gid=33,$${SMB_PLUM}" }
    "/opt/repository/fallback_stream_derivatives" = { type = "cifs", device = "//diglibdata1.princeton.edu/hydra/binaries/figgy_staging_stream_derivatives", o = "addr=diglibdata1.princeton.edu,uid=1001,gid=33,$${SMB_PLUM}" }
    "/mnt/diglibdata/hydra_binaries"             = { type = "cifs", device = "//diglibdata1.princeton.edu/hydra/binaries", o = "addr=diglibdata1.princeton.edu,uid=1001,gid=33,$${SMB_PLUM}" }
    "/mnt/diglibdata/pudl"                       = { type = "cifs", device = "//diglibdata1.princeton.edu/pudl", o = "addr=diglibdata1.princeton.edu,uid=1001,gid=33,$${SMB_PUDL}" }
    "/mnt/hydra_sources/ingest_scratch"          = { type = "cifs", device = "//diglibdata1.princeton.edu/hydra/binaries/ingest_scratch", o = "addr=diglibdata1.princeton.edu,uid=1001,gid=33,$${SMB_PLUM}" }
    "/mnt/hydra_sources/pudl"                    = { type = "cifs", device = "//diglibdata1.princeton.edu/pudl", o = "addr=diglibdata1.princeton.edu,uid=1001,$${SMB_PUDL}" }
    "/mnt/hydra_sources/maplab"                  = { type = "cifs", device = "//diglibdata1.princeton.edu/maplab", o = "addr=diglibdata1.princeton.edu,uid=1001,$${SMB_MAPLAB}" }
    "/mnt/hydra_sources/music"                   = { type = "cifs", device = "//diglibdata1.princeton.edu/music", o = "addr=diglibdata1.princeton.edu,uid=1001,gid=33,$${SMB_PLUM}" }
    "/mnt/hydra_sources/numismatics"             = { type = "cifs", device = "//diglibdata1.princeton.edu/numismatics", o = "addr=diglibdata1.princeton.edu,uid=1001,gid=33,$${SMB_NUMIS}" }
    "/mnt/hydra_sources/studio_new"              = { type = "cifs", device = "//lib-dps-server.princeton.edu/studio", o = "addr=lib-dps-server.princeton.edu,uid=1001,$${SMB_STUDIO}" }
    "/mnt/hydra_sources/marquand"                = { type = "cifs", device = "//lib-dps-server.princeton.edu/marquand", o = "addr=lib-dps-server.princeton.edu,uid=1001,$${SMB_MARQUAND}" }
    "/mnt/hydra_sources/mendel"                  = { type = "cifs", device = "//lib-dps-server.princeton.edu/mendel", o = "addr=lib-dps-server.princeton.edu,uid=1001,$${SMB_MENDEL}" }
    "/mnt/hydra_sources/mudd"                    = { type = "cifs", device = "//lib-dps-server.princeton.edu/mudd", o = "addr=lib-dps-server.princeton.edu,uid=1001,$${SMB_MUDD}" }
    "/mnt/hydra_sources/microforms"              = { type = "cifs", device = "//lib-dps-server.princeton.edu/microforms", o = "addr=lib-dps-server.princeton.edu,uid=1001,$${SMB_MICROFORMS}" }
    "/mnt/hydra_sources/archives"                = { type = "nfs", device = ":/pul/archives", o = local.nfs_options }
    "/mnt/hydra_sources/archives_bd"             = { type = "nfs", device = ":/pul/archives_bd", o = local.nfs_options }
    "/mnt/hydra_sources/bitcur-archives"         = { type = "nfs", device = ":/pul/bitcur-archives", o = local.nfs_options }
    "/mnt/hosted_illiad/RequestScans"            = { type = "cifs", device = "//lib-fileshare.princeton.edu/RequestScans", o = "addr=lib-fileshare.princeton.edu,uid=1001,gid=33,$${SMB_ILLIAD}" }
  }
  docker_mounts = [for target, options in local.mounts : {
    type   = "volume"
    target = target
    source = "${NOMAD_ALLOC_ID}${replace(target, "/", "-")}"
    volume_options = {
      driver_config = {
        name    = "local"
        options = [options]
      }
    }
  }]
  google_credentials = "{{ with nomadVar \"nomad/jobs/figgy-staging\" }}{{ .GOOGLE_CLOUD_CREDENTIALS_JSON }}{{ end }}"
}

job "figgy-staging" {
  region      = "global"
  datacenters = ["dc1"]
  node_pool   = "staging"
  type        = "service"

  group "web" {
    count          = 2
    shutdown_delay = "10s"
    network {
      port "http" { to = 3000 }
      dns {
        servers = ["172.17.0.1", "128.112.129.209", "8.8.8.8", "8.8.4.4"]
      }
    }
    service {
      name = "${local.job_name}-web"
      port = "http"
      tags = ["frontend", "logging"]
      check {
        type     = "http"
        port     = "http"
        path     = "/health.json"
        interval = "10s"
        timeout  = "5s"
      }
    }
    task "migrate" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
      driver = "docker"
      config {
        image       = local.image
        userns_mode = "host"
        command    = "bash"
        args       = ["-c", "if [ \"$NOMAD_ALLOC_INDEX\" -eq 0 ]; then bin/rails db:migrate; fi"]
        force_pull = true
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = local.env
      }
    }
    task "web" {
      driver = "docker"
      config {
        image       = local.image
        userns_mode = "host"
        ports      = ["http"]
        force_pull = true
        mount      = local.docker_mounts
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = local.env
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/google_cloud_credentials.json"
        change_mode = "restart"
        data        = local.google_credentials
      }
      resources {
        cpu    = 2000
        memory = 4096
      }
    }
  }

  dynamic "group" {
    for_each = local.workers
    labels   = [group.key]
    content {
      count = group.value.count
      network {
        dns {
          servers = ["172.17.0.1", "128.112.129.209", "8.8.8.8", "8.8.4.4"]
        }
      }
      task "worker" {
        driver       = "docker"
        kill_timeout = "30s"
        config {
          image       = local.image
          userns_mode = "host"
          command    = "bash"
          args       = ["-c", group.value.command]
          force_pull = true
          mount      = local.docker_mounts
        }
        template {
          destination = "${NOMAD_SECRETS_DIR}/env.vars"
          env         = true
          change_mode = "restart"
          data        = local.env
        }
        template {
          destination = "${NOMAD_SECRETS_DIR}/google_cloud_credentials.json"
          change_mode = "restart"
          data        = local.google_credentials
        }
        resources {
          cpu    = group.value.cpu
          memory = group.value.memory
        }
      }
    }
  }
}

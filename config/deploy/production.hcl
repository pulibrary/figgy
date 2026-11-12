variable "branch_or_sha" {
  type    = string
  default = "main"
}

locals {
  job_name = "figgy-production"
  image    = "ghcr.io/pulibrary/figgy:${var.branch_or_sha}"
  workers = {
    worker          = { count = 6, cpu = 4000, memory = 8192, command = "bundle exec sidekiq -c 10 -q high -q mailers -q default -q low -q super_low" }
    realtime-worker = { count = 6, cpu = 1000, memory = 2048, command = "bundle exec sidekiq -c 1 -q realtime" }
    bulk-worker     = { count = 6, cpu = 2000, memory = 4096, command = "bundle exec sidekiq -c 1 -q bulk -q bulk_low" }
    pubsub-worker   = { count = 1, cpu = 500, memory = 1024, command = "bundle exec rake figgy:fixity:run_worker" }
    pdf-watcher     = { count = 1, cpu = 500, memory = 1024, command = "bundle exec bin/pdf_watcher" }
    cron            = { count = 1, cpu = 1000, memory = 2048, command = "bundle exec whenever --roles db,worker_db --set environment=$RAILS_ENV > tmp/crontab && exec supercronic tmp/crontab" }
  }
  env = <<-EOF
    {{- with nomadVar "nomad/jobs/figgy-production" -}}
    RAILS_ENV = 'production'
    APPLICATION_HOST = 'figgy.princeton.edu'
    APPLICATION_HOST_PROTOCOL = 'https'
    SECRET_KEY_BASE = '{{ .SECRET_KEY_BASE }}'
    REACT_APP_SECRET = '{{ .SECRET_KEY_BASE }}'
    REACT_APP_API_URL = 'https://figgy.princeton.edu/browse'
    FIGGY_DB = 'figgy_production'
    FIGGY_DB_HOST = 'figgy-db-prod1.princeton.edu'
    FIGGY_DB_USERNAME = '{{ .FIGGY_DB_USERNAME }}'
    FIGGY_DB_PASSWORD = '{{ .FIGGY_DB_PASSWORD }}'
    FIGGY_DB_RO_USERNAME = '{{ .FIGGY_DB_RO_USERNAME }}'
    FIGGY_DB_RO_PASSWORD = '{{ .FIGGY_DB_RO_PASSWORD }}'
    FIGGY_RABBIT_SERVER = '{{ .FIGGY_RABBIT_SERVER }}'
    FIGGY_REDIS_DB = '1'
    FIGGY_REDIS_PASSWORD = '{{ .FIGGY_REDIS_PASSWORD }}'
    FIGGY_READ_ONLY_MODE = '{{ .FIGGY_READ_ONLY_MODE }}'
    FIGGY_PUDL_ROOT = '{{ .FIGGY_PUDL_ROOT }}'
    FIGGY_AWS_ACCESS_KEY_ID = '{{ .FIGGY_AWS_ACCESS_KEY_ID }}'
    FIGGY_AWS_SECRET_ACCESS_KEY = '{{ .FIGGY_AWS_SECRET_ACCESS_KEY }}'
    FIGGY_PYRAMIDAL_ACCESS = 'true'
    SOLR_URL = 'http://lib-solr9-prod.princeton.edu:8983/solr/figgy-production'
    PULMAP_SOLR_URL = 'http://lib-solr9-prod.princeton.edu:8983/solr/pulmap'
    HONEYBADGER_API_KEY = '{{ .HONEYBADGER_API_KEY }}'
    EZID_DEFAULT_SHOULDER = '{{ .EZID_DEFAULT_SHOULDER }}'
    EZID_USER = '{{ .EZID_USER }}'
    EZID_PASSWORD = '{{ .EZID_PASSWORD }}'
    INGEST_FOLDER_PATH = '/mnt/hydra_sources'
    ACTIVE_STORAGE_ROOT = '/mnt/diglibdata/hydra_binaries/active_storage/production'
    STORAGE_CREDENTIALS = '/secrets/google_cloud_credentials.json'
    STORAGE_PROJECT = 'pulibrary-figgy-storage-1'
    GOOGLE_CLOUD_CREDENTIALS = '/secrets/google_cloud_credentials.json'
    GOOGLE_CLOUD_PROJECT = 'pulibrary-figgy-storage-1'
    READING_ROOM_IPS = '{{ .READING_ROOM_IPS }}'
    MAGICK_HEIGHT_LIMIT = '215MP'
    MAGICK_WIDTH_LIMIT = '215MP'
    MAGICK_AREA_LIMIT = '132GP'
    PYRAMIDAL_URL = 'https://iiif-cloud.princeton.edu/iiif/2/'
    OCR_ILLIAD_IN_PATH = '/mnt/hosted_illiad/RequestScans/ocr_scan'
    OCR_ILLIAD_OUT_PATH = '/mnt/hosted_illiad/RequestScans/images'
    ASPACE_URL = 'https://aspace.princeton.edu/staff/api'
    ASPACE_USER = '{{ .ASPACE_USER }}'
    ASPACE_PASSWORD = '{{ .ASPACE_PASSWORD }}'
    TILESERVER_URL = 'https://map-tiles.princeton.edu'
    PULFALIGHT_UNPUBLISHED_TOKEN = '{{ .PULFALIGHT_UNPUBLISHED_TOKEN }}'
    OPEN_GEODATA_URL = 'https://geodata.lib.princeton.edu'
    RESTRICTED_GEODATA_URL = 'https://geodata-restricted.lib.princeton.edu'
    NODE_OPTIONS = '--openssl-legacy-provider'
    PLAUSIBLE_API_KEY = '{{ .PLAUSIBLE_API_KEY }}'
    {{- end -}}
  EOF
  google_credentials = "{{ with nomadVar \"nomad/jobs/figgy-production\" }}{{ .GOOGLE_CLOUD_CREDENTIALS_BASE64 | base64Decode }}{{ end }}"
}

job "figgy-production" {
  region      = "global"
  datacenters = ["dc1"]
  node_pool   = "production"
  type        = "service"

  group "web" {
    count          = 4
    shutdown_delay = "10s"
    network {
      port "http" { to = 3000 }
      dns {
        servers = ["172.17.0.1", "128.112.129.209", "8.8.8.8", "8.8.4.4"]
      }
    }
    volume "repository" {
      type   = "host"
      source = "figgy-repository"
    }
    volume "mnt" {
      type   = "host"
      source = "figgy-mnt"
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
      }
      volume_mount {
        volume           = "repository"
        destination      = "/opt/repository"
        propagation_mode = "host-to-task"
      }
      volume_mount {
        volume           = "mnt"
        destination      = "/mnt"
        propagation_mode = "host-to-task"
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
      volume "repository" {
        type   = "host"
        source = "figgy-repository"
      }
      volume "mnt" {
        type   = "host"
        source = "figgy-mnt"
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
        }
        volume_mount {
          volume           = "repository"
          destination      = "/opt/repository"
          propagation_mode = "host-to-task"
        }
        volume_mount {
          volume           = "mnt"
          destination      = "/mnt"
          propagation_mode = "host-to-task"
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

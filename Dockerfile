# syntax=docker/dockerfile:1
FROM node:24.16.0-trixie-slim AS node

FROM ruby:3.4.12-slim-trixie AS base
WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl ffmpeg file gdal-bin imagemagick libopenjp2-tools libpq5 libvips42t64 mediainfo \
      ocrmypdf postgresql-client python3-venv tesseract-ocr-all tippecanoe unzip zip && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN python3 -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir cogeo-mosaic

ARG TARGETARCH
ADD --chmod=755 https://github.com/aptible/supercronic/releases/download/v0.2.51/supercronic-linux-${TARGETARCH} /usr/local/bin/supercronic

COPY --from=node /usr/local/bin/node /usr/local/bin/node

RUN groupadd --system --gid 1001 deploy && \
    useradd deploy --uid 1001 --gid 1001 --create-home --shell /bin/bash

ENV PATH="/opt/venv/bin:$PATH" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV="production" \
    RAILS_LOG_TO_STDOUT="true" \
    MEDIAINFO_PATH="/usr/bin/mediainfo"


FROM base AS packages

COPY --from=node /opt /opt
RUN ln -s /opt/yarn-*/bin/yarn /usr/local/bin/yarn
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile


FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY --from=node /opt /opt
RUN ln -s /opt/yarn-*/bin/yarn /usr/local/bin/yarn

COPY Gemfile Gemfile.lock ./
RUN --mount=type=secret,id=sidekiq_pro \
    gem install -N bundler -v "$(tail -1 Gemfile.lock | tr -d ' ')" && \
    BUNDLE_GEMS__CONTRIBSYS__COM="$(cat /run/secrets/sidekiq_pro)" bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY --from=packages /rails/node_modules node_modules
COPY . .
RUN mkdir -p log tmp/pids && SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile && rm -rf node_modules


FROM base AS runtime

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y nginx && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    gem install -N foreman && \
    sed -i 's|pid /run|pid /rails/tmp/pids|' /etc/nginx/nginx.conf && \
    sed -i 's/access_log\s.*;/access_log \/dev\/stdout;/' /etc/nginx/nginx.conf && \
    sed -i 's/error_log\s.*;/error_log \/dev\/stderr info;/' /etc/nginx/nginx.conf && \
    mkdir -p /opt/repository && \
    chown 1001:1001 /var/lib/nginx /var/log/nginx/* /opt/repository

COPY <<-"EOF" /etc/nginx/sites-available/default
server {
  listen 3000 default_server;
  client_max_body_size 0;
  root /rails/public;

  location ~ /restricted_repository/(.*) {
    internal;
    alias /opt/repository/$1;
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Origin' always;
    aio threads;
  }

  location / {
    try_files $uri @backend;
  }

  location @backend {
    proxy_pass http://localhost:3001;
    proxy_http_version 1.1;
    proxy_set_header Host $http_host;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
    proxy_set_header X-Accel-Mapping /opt/repository/=/restricted_repository/;
    proxy_read_timeout 3600;
    proxy_buffering off;
  }
}
EOF

COPY <<-"EOF" /rails/Procfile.prod
nginx: /usr/sbin/nginx -g "daemon off;"
rails: bin/rails server -p 3001
EOF

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=packages /rails/node_modules/@mapnik /rails/node_modules/@mapnik
COPY --from=packages /rails/node_modules/node-gyp-build /rails/node_modules/node-gyp-build


FROM runtime AS ci

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential chromium chromium-driver firefox-esr git libpq-dev libyaml-dev lsof pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY --from=node /opt /opt
RUN ln -s /opt/yarn-*/bin/yarn /usr/local/bin/yarn

ENV RAILS_ENV="test" BUNDLE_WITHOUT="" RAILS_LOG_TO_STDOUT="" CI="true"
COPY Gemfile Gemfile.lock ./
RUN --mount=type=secret,id=sidekiq_pro \
    BUNDLE_GEMS__CONTRIBSYS__COM="$(cat /run/secrets/sidekiq_pro)" bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY --from=packages /rails/node_modules /rails/node_modules
COPY cloud_fixity/package.json cloud_fixity/yarn.lock cloud_fixity/
RUN cd cloud_fixity && yarn install --frozen-lockfile

COPY --from=build /rails /rails


FROM runtime AS production

COPY --from=build --chown=1001:1001 /rails /rails
USER 1001:1001

EXPOSE 3000
CMD ["foreman", "start", "--procfile=Procfile.prod"]

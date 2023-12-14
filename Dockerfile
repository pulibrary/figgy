# Compile tippecanoe
FROM debian:buster AS tippecanoe
RUN apt update -y && apt-get install -y build-essential sudo cmake wget git sqlite3 libsqlite3-dev gdal-bin libgdal-dev
RUN mkdir -p /opt/app/tmp
WORKDIR /opt/app
COPY ./bin/ci_tippecanoe_install.sh ./bin/
RUN rm -rf .git && rm -rf tests && sh ./bin/ci_tippecanoe_install.sh

## Assets ########################
FROM ruby:3.1.0-slim-buster AS assets
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH
ENV NVM_DIR /usr/local/nvm
ARG NODE_VERSION=18.18.0
ARG RAILS_ENV=production
ARG NODE_ENV=production
ARG SIDEKIQ_CREDENTIALS
ENV NODE_VERSION="${NODE_VERSION}"
ENV RAILS_ENV="${RAILS_ENV}"
ENV NODE_ENV="${NODE_ENV}"
ENV RAILS_LOG_TO_STDOUT true

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update -y && apt-get install -y --no-install-recommends curl
RUN mkdir -p /usr/local/nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Stage code
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY . .
RUN chmod 1777 /tmp

# Install dependencies
#
COPY --from=tippecanoe /opt/app/tmp/tippecanoe tmp/tippecanoe/
RUN sh ./bin/ci_mediainfo_install.sh \
  && apt-get install -y --no-install-recommends git sudo cmake sqlite3 libopenjp2-7 gdal-bin libgdal-dev tesseract-ocr tesseract-ocr-ita tesseract-ocr-eng mediainfo ffmpeg postgresql-client ocrmypdf lsof python3-pip imagemagick build-essential pkg-config libvips \
  && sh ./bin/ci_tippecanoe_install.sh \
  && rm -rf tmp/* \
  && pip3 install pip -U \
  && pip3 install setuptools -U \
  && pip3 install cogeo-mosaic \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean
RUN npm install --global yarn
# # Install Ruby/Node Dependencies
RUN gem install bundler
RUN bundle config --global frozen 1
RUN bundle config set --local without 'development test'
RUN bundle config gems.contribsys.com ${SIDEKIQ_CREDENTIALS}
RUN bundle install
RUN yarn install
RUN if [ "${RAILS_ENV}" != "development" ]; then \
  SECRET_KEY_BASE=1 rails assets:precompile; fi

## Application ####################

FROM ruby:3.1.0-slim-buster AS app
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH
ENV NVM_DIR /usr/local/nvm
ARG NODE_VERSION=18.18.0
ARG RAILS_ENV=production
ARG NODE_ENV=production
ENV NODE_VERSION="${NODE_VERSION}"
ENV RAILS_ENV="${RAILS_ENV}"
ENV NODE_ENV="${NODE_ENV}"
ENV RAILS_LOG_TO_STDOUT true

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update -y && apt-get install -y --no-install-recommends curl
RUN mkdir -p /usr/local/nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Stage code
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY . .
RUN chmod 1777 /tmp

# Install dependencies
#
COPY --from=tippecanoe /opt/app/tmp/tippecanoe tmp/tippecanoe/
RUN sh ./bin/ci_mediainfo_install.sh \
  && apt-get install -y --no-install-recommends git sudo cmake sqlite3 libopenjp2-7 gdal-bin libgdal-dev tesseract-ocr tesseract-ocr-ita tesseract-ocr-eng mediainfo libvips ffmpeg postgresql-client ocrmypdf lsof python3-pip imagemagick build-essential pkg-config \
  && sh ./bin/ci_tippecanoe_install.sh \
  && rm -rf tmp/* \
  && pip3 install pip -U \
  && pip3 install setuptools -U \
  && pip3 install cogeo-mosaic \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean
COPY --from=assets /usr/local/bundle /usr/local/bundle
COPY --from=assets /opt/app/public /opt/app/public
# Install mapnik
RUN npm install --global mapnik
# # Install Ruby/Node Dependencies
RUN gem install bundler
RUN bundle config --global frozen 1
RUN bundle config set --local without 'development test'
RUN bundle install

FROM cimg/ruby:3.1.0-browsers

RUN git clone https://github.com/pulibrary/figgy.git \
  && cd figgy \
  && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
  && wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null \
  && sudo apt update -y \
  && sudo sh ./bin/ci_mediainfo_install.sh \
  && sudo apt-get install gdal-bin libgdal-dev tesseract-ocr tesseract-ocr-ita tesseract-ocr-eng mediainfo ffmpeg postgresql-client-15 ocrmypdf lsof python3-pip python-is-python3 imagemagick libmagickwand-dev build-essential pkg-config glib2.0-dev libexpat1-dev \
  && sudo sh ./bin/ci_tippecanoe_install.sh \
  && sudo sh ./bin/ci_free_tds_install.sh \
  && sudo sh ./bin/ci_openjpeg_install.sh \
  && sudo sh ./bin/ci_vips_install.sh \
  && sudo pip3 install pip -U \
  && sudo pip3 install setuptools -U \
  && sudo pip3 install -U numpy \
  && sudo pip3 install cogeo-mosaic \
  && cd .. \
  && sudo rm -rf figgy

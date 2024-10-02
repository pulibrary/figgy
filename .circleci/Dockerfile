FROM cimg/ruby:3.1.6-browsers

RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
  && wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null
RUN sudo apt update -y \
  && sudo apt-get install gdal-bin libgdal-dev tesseract-ocr tesseract-ocr-ita tesseract-ocr-eng mediainfo ffmpeg postgresql-client-15 ocrmypdf lsof python3-pip python-is-python3 imagemagick libmagickwand-dev build-essential pkg-config glib2.0-dev libexpat1-dev
RUN mkdir bin
ADD bin ./bin/
RUN sudo sh ./bin/ci_mediainfo_install.sh
RUN sudo sh ./bin/ci_tippecanoe_install.sh
RUN sudo sh ./bin/ci_free_tds_install.sh
RUN sudo sh ./bin/ci_openjpeg_install.sh
RUN sudo sh ./bin/ci_vips_install.sh
RUN sudo pip3 install pip -U \
  && sudo pip3 install setuptools -U \
  && sudo pip3 install -U numpy \
  && sudo pip3 install cogeo-mosaic
RUN sudo rm -rf bin

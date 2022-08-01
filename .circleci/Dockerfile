FROM cimg/ruby:2.7.5-browsers

RUN git clone https://github.com/pulibrary/figgy.git \
  && cd figgy \
  && sudo apt update -y \
  && sudo sh ./bin/ci_mediainfo_install.sh \
  && sudo apt-get install gdal-bin libgdal-dev tesseract-ocr tesseract-ocr-ita tesseract-ocr-eng mediainfo ffmpeg postgresql-client ocrmypdf lsof python3-pip python-is-python3 imagemagick build-essential pkg-config glib2.0-dev libexpat1-dev \
  && sudo sh ./bin/ci_free_tds_install.sh \
  && sudo sh ./bin/ci_openjpeg_install.sh \
  && sudo sh ./bin/ci_vips_install.sh \
  && sudo pip3 install pip -U \
  && sudo pip3 install setuptools -U \
  && sudo pip3 install cogeo-mosaic \
  && cd .. \
  && sudo rm -rf figgy

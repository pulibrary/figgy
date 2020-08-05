apt-get install libpoppler-glib-dev
if [ ! -d "tmp/vips" ]; then
  mkdir -p -m 777 tmp && cd tmp
  wget --no-check-certificate https://github.com/libvips/libvips/releases/download/v8.9.1/vips-8.9.1.tar.gz -O vips.tar.gz
  tar -xzvf vips.tar.gz
  mv vips-8.9.1 vips
  cd vips
  ./configure && make
  sudo make install
  cd ../..
fi
cd tmp/vips && sudo make install && cd ../..

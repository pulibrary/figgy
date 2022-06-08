apt-get install libpoppler-glib-dev
if [ ! -d "tmp/openjpeg" ]; then
  mkdir -p -m 777 tmp && cd tmp
  wget --no-check-certificate https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.5.0.tar.gz -O openjpeg.tar.gz
  tar -xzvf openjpeg.tar.gz
  mv openjpeg-2.5.0 openjpeg
  cd openjpeg
  mkdir build
  cd build
  cmake .. -DCMAKE_BUILD_TYPE=Release && make
  sudo make install
  sudo ldconfig
  cd ../../..
fi
cd tmp/openjpeg/build && sudo make install && sudo ldconfig && cd ../../..

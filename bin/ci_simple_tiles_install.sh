if [ ! -d "tmp/simple-tiles" ]; then
  mkdir ~/downloads
  wget --no-check-certificate https://github.com/propublica/simple-tiles/archive/master.zip -O ~/downloads/simple-tiles.zip
  mkdir -p -m 777 tmp && cd tmp
  unzip ~/downloads/simple-tiles.zip
  mv simple-tiles-master simple-tiles
  cd simple-tiles
  ./configure -t $PWD && make
  sudo make install
  cd ../..
fi
cd tmp/simple-tiles && sudo make install && cd ../..
# Clean up after the build
if [ -d "simple-tiles" ]; then
  mv simple-tiles tmp/simple-tiles-build
fi

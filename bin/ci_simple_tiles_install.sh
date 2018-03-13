if [ ! -d "simple-tiles" ]; then
  mkdir ~/downloads
  wget --no-check-certificate https://github.com/propublica/simple-tiles/archive/master.zip -O ~/downloads/simple-tiles.zip
  unzip ~/downloads/simple-tiles.zip
  mv simple-tiles-master simple-tiles
  cd simple-tiles
  ./configure && make
  sudo make install
  cd -
fi
cd simple-tiles && sudo make install && cd -

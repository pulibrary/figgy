if [ ! -d "tmp/tippecanoe" ]; then
  mkdir -p -m 777 tmp && cd tmp
  git clone https://github.com/felt/tippecanoe.git
  cd tippecanoe
  make -j
  sudo make install
  sudo ldconfig
  cd ../..
fi
cd tmp/tippecanoe && sudo make install && sudo ldconfig && cd ../..

if [ ! -d "tmp/freetds-1.00.108" ]; then
  mkdir ~/downloads
  wget --no-check-certificate http://www.freetds.org/files/stable/freetds-1.00.108.tar.gz -O ~/downloads/freetds-1.00.108.tar.gz
  mkdir -p -m 777 tmp && cd tmp
  tar -xzf ~/downloads/freetds-1.00.108.tar.gz
  cd freetds-1.00.108
  ./configure --prefix=/usr/local --with-tdsver=7.3
  cd ../..
fi

cd tmp/freetds-1.00.108 && sudo make install && cd ../..

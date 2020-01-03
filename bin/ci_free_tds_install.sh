if [ ! -d "tmp/freetds-1.00.108" ]; then
  mkdir -p -m 777 tmp && cd tmp
  wget --no-check-certificate http://www.freetds.org/files/stable/freetds-1.00.108.tar.gz -O freetds-1.00.108.tar.gz
  tar -xzf freetds-1.00.108.tar.gz
  cd freetds-1.00.108
  ./configure --prefix=/usr/local --with-tdsver=7.3
  cd ../..
fi

cd tmp/freetds-1.00.108 && sudo make install && cd ../..

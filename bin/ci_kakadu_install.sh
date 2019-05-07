if [ ! -d "kakadu" ]; then
  mkdir ~/downloads
  # Get kakadu from temporary location until website is back online
  wget https://s3.amazonaws.com/kdubackupfiles/KDU78_Demo_Apps_for_Linux-x86-64_160226.zip -O ~/downloads/kakadu.zip
  # wget http://kakadusoftware.com/wp-content/uploads/2014/06/KDU77_Demo_Apps_for_Linux-x86-64_150710.zip -O ~/downloads/kakadu.zip
  unzip ~/downloads/kakadu.zip
  mv KDU78_Demo_Apps_for_Linux-x86-64_160226 kakadu
fi
sudo cp kakadu/*.so /usr/lib
sudo cp kakadu/* /usr/bin

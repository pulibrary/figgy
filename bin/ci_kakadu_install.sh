if [ ! -d "kakadu" ]; then
  mkdir ~/downloads
  wget http://kakadusoftware.com/wp-content/uploads/2014/06/KDU77_Demo_Apps_for_Linux-x86-64_150710.zip -O ~/downloads/kakadu.zip
  unzip ~/downloads/kakadu.zip
  mv KDU77_Demo_Apps_for_Linux-x86-64_150710 kakadu
fi
sudo cp kakadu/*.so /usr/lib
sudo cp kakadu/* /usr/bin

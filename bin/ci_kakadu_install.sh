if [ ! -d "kakadu" ]; then
  mkdir ~/downloads
  wget https://storage.googleapis.com/kdubackupfiles/KDU78_Demo_Apps_for_Linux-x86-64_160226.zip -O ~/downloads/kakadu.zip
  unzip ~/downloads/kakadu.zip
  mv KDU78_Demo_Apps_for_Linux-x86-64_160226 kakadu
fi
sudo cp kakadu/*.so /usr/lib
sudo cp kakadu/* /usr/bin

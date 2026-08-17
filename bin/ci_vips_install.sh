sudo apt-get update && sudo apt-get install -y \
  build-essential \
  meson \
  ninja-build \
  pkg-config \
  libglib2.0-dev \
  libpoppler-glib-dev

if [ ! -d "tmp/vips" ]; then
  mkdir -p tmp && cd tmp
  wget https://github.com/libvips/libvips/releases/download/v8.16.1/vips-8.16.1.tar.xz -O vips.tar.xz
  tar -xf vips.tar.xz
  mv vips-8.16.1 vips
  cd vips
  meson setup build --buildtype=release
  ninja -C build
  sudo ninja -C build install
  sudo ldconfig
  cd ../..
fi

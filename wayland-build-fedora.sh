# setup environment for local install:
TEST_PATH=`pwd`
export WLD=$TEST_PATH/install
export LD_LIBRARY_PATH=$WLD/lib
export PKG_CONFIG_PATH=$WLD/lib/pkgconfig/:$WLD/share/pkgconfig/
export PATH=$WLD/bin:$PATH

export ACLOCAL_PATH=$WLD/share/aclocal
export ACLOCAL="aclocal -I $ACLOCAL_PATH"

mkdir -p $WLD
mkdir -p $ACLOCAL_PATH

# dependencies for libwayland:
# Fedora
sudo yum install doxygen

# Ubuntu
#sudo apt-get install doxygen # or use --disable-documentation

# libwayland-*:
git clone git://anongit.freedesktop.org/wayland/wayland
cd wayland
./autogen.sh --prefix=$WLD
make && make install
cd ..

# dependencies for Mesa:
# "sudo apt-get build-dep mesa" will install these, but will also
# install unwanted items, such as wayland itself, and xcb prototypes
# that are too old.

# Fedora
sudo yum install autoconf automake bison debhelper dpkg-dev flex \
    systemd-devel libX11-devel libxcb-devel \
    libXdamage-devel libXext-devel libXfixes-devel libXxf86vm-devel \
    libxml2-python quilt.noarch imake libtool xorg-x11-proto-devel libdrm-devel \
    gcc-c++ xorg-x11-server-devel libXi-devel libXmu-devel libXdamage-devel git \
    expat-devel llvm-devel llvm-static libpciaccess-dev  libXfont-devel mtdev-devel \
    openssl-devel mesa-libGLES-devel mesa-libwayland-egl-devel mesa-libgbm-devel \
    libjpeg-turbo-devel pam-devel texlive-latex2man



# Ubuntu
#sudo apt-get install autoconf automake bison debhelper dpkg-dev flex \
#    libexpat1-dev libudev-dev libx11-dev libx11-xcb-dev \
#    libxdamage-dev libxext-dev libxfixes-dev libxxf86vm-dev \
#    linux-libc-dev pkg-config python-libxml2 quilt x11proto-dri2-dev \
#    x11proto-gl-dev xutils-dev

# Mesa required llvm-3.1, but newer versions are available.
# "apt-cache search 'llvm-[0-9.]*-dev'" will list them

# Ubuntu
#sudo apt-get install llvm-3.1-dev
#sudo ln -sf llvm-config-3.1 /usr/bin/llvm-config

#sudo apt-get install libpciaccess-dev # needed by drm
git clone git://anongit.freedesktop.org/git/mesa/drm
cd drm
./autogen.sh --prefix=$WLD
make && make install
cd ..

# needed by libxcb:
git clone git://anongit.freedesktop.org/xcb/proto
cd proto
./autogen.sh --prefix=$WLD
make && make install
cd ..

# needed by libxcb:
git clone git://anongit.freedesktop.org/xorg/util/macros
cd macros
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xcb/libxcb
cd libxcb
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/presentproto
cd presentproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/dri3proto
cd dri3proto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/lib/libxshmfence
cd libxshmfence
./autogen.sh --prefix=$WLD
make && make install
cd ..

# Mesa:
git clone git://anongit.freedesktop.org/mesa/mesa
cd mesa
./autogen.sh --prefix=$WLD --enable-gles2 --disable-gallium-egl \
    --with-egl-platforms=x11,wayland,drm --enable-gbm --enable-shared-glapi \
    --with-gallium-drivers=r300,r600,swrast,nouveau \
    --disable-llvm-shared-libs # this may be a bug in the llvm package
make && make install
cd ..

# The version of Cairo included with Ubuntu 12.04 has bugs that cause
# rendering errors in some Wayland clients (in particular the
# Xserver). Though not required, it may be a good idea to compile the
# newest version from source:
git clone git://anongit.freedesktop.org/pixman
cd pixman
./autogen.sh --prefix=$WLD
make -j 9 && make install
cd ..

git clone git://anongit.freedesktop.org/cairo
cd cairo
./autogen.sh --prefix=$WLD --enable-xcb
make -j 9 && make install
cd ..

# libinput dependencies:
#sudo apt-get install libmtdev-dev libpam0g-dev

git clone git://github.com/xkbcommon/libxkbcommon
cd libxkbcommon
./autogen.sh --prefix=$WLD --with-xkb-config-root=/usr/share/X11/xkb
make && make install
cd ..

git clone git://anongit.freedesktop.org/libevdev
cd libevdev
./autogen.sh --prefix=$WLD
make && make install
cd ..

# libinput:
git clone git://anongit.freedesktop.org/wayland/libinput
cd libinput
./autogen.sh --prefix=$WLD
make && make install
cd ..

# Weston dependencies:
git clone git://git.sv.gnu.org/libunwind
cd libunwind
autoreconf -i # note that autogen is not used
./configure --prefix=$WLD
make && make install
cd ..

# Weston and demo applications:
git clone git://anongit.freedesktop.org/wayland/weston
cd weston
./autogen.sh --prefix=$WLD --enable-libinput-backend --disable-setuid-install
make -j 9 && make install
cd ..

# XServer dependencies:
#sudo apt-get install libxfont-dev

git clone https://github.com/anholt/libepoxy.git
cd libepoxy
# The CPPFLAGS fixed a failure to find the local EGL header files
# This is not necessary if xproto is installed first
CPPFLAGS=-I$WLD/include ./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/glproto
cd glproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/xproto
cd xproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/xcmiscproto
cd xcmiscproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/lib/libxtrans
cd libxtrans
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/bigreqsproto
cd bigreqsproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/xextproto
cd xextproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/fontsproto
cd fontsproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/videoproto
cd videoproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/recordproto
cd recordproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/resourceproto
cd resourceproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/proto/xf86driproto
cd xf86driproto
./autogen.sh --prefix=$WLD
make && make install
cd ..

git clone git://anongit.freedesktop.org/xorg/lib/libxkbfile
cd libxkbfile
./autogen.sh --prefix=$WLD
make && make install
cd ..

# XWayland:
git clone git://anongit.freedesktop.org/xorg/xserver
cd xserver
./autogen.sh --prefix=$WLD --disable-docs --disable-devel-docs \
    --enable-xwayland --disable-xorg --disable-xvfb --disable-xnest \
    --disable-xquartz --disable-xwin
make && make install
cd ..

# Links needed so XWayland works:
mkdir -p $WLD/share/X11/xkb/rules
ln -s /usr/share/X11/xkb/rules/evdev $WLD/share/X11/xkb/rules/
ln -s /usr/bin/xkbcomp $WLD/bin/

# Weston configuration:
mkdir -p ~/.config
cp weston/weston.ini ~/.config
nano ~/.config/weston.ini # edit to set background and turn on xwayland.so module

# Needed by wayland for socket:
if test -z "${XDG_RUNTIME_DIR}"; then
    export XDG_RUNTIME_DIR=/tmp/${UID}-runtime-dir
    if ! test -d "${XDG_RUNTIME_DIR}"; then
        mkdir "${XDG_RUNTIME_DIR}"
        chmod 0700 "${XDG_RUNTIME_DIR}"
    fi
fi
# Run it in an X11 window:
weston

WLD=$HOME/wayland_work/install
export WLD
SOURCE=$HOME/wayland_work/source
export SOURCE

BUILD_WAYLAND=1
BUILD_GTK=0 # doesn't work with master
BUILD_QT=0 # doesn't work with master
BUILD_XWAYLAND=1

# Set to nothing to skip cleaning for faster but less reliable rebuilds.
CLEAN='git clean -x -f -d'
#CLEAN=


# You might want to put these in your ~/.bashrc
PKG_CONFIG_PATH=$WLD/lib/pkgconfig/:$WLD/share/pkgconfig/
export PKG_CONFIG_PATH
ACLOCAL="aclocal -I $WLD/share/aclocal"
export ACLOCAL
C_INCLUDE_PATH=$WLD/include
export C_INCLUDE_PATH
LIBRARY_PATH=$WLD/lib
export LIBRARY_PATH
PATH=$WLD/bin:$PATH # Needed by gtk for $WLD/bin/gdk-pixbuf-pixdata
export PATH

# Do *not* put this in your ~/.bashrc, it will break things.
LD_LIBRARY_PATH=$WLD/lib
export LD_LIBRARY_PATH

# Get some more debugging output
MESA_DEBUG=1
export MESA_DEBUG
EGL_LOG_LEVEL=debug
export EGL_LOG_LEVEL
LIBGL_DEBUG=verbose
export LIBGL_DEBUG
# This one is noisy.
#WAYLAND_DEBUG=1
#export WAYLAND_DEBUG

#EGL_PLATFORM=wayland
#export EGL_PLATFORM
#EGL_DRIVER=egl_gallium
#export EGL_DRIVER

# qt5
QTVER=qt5
#QTDIR=$WLD/qt/$QTVER
#PATH=$QTDIR/bin/:$PATH
#LD_LIBRARY_PATH=$QTDIR/lib/:$LD_LIBRARY_PATH
#PKG_CONFIG_PATH=$QTDIR/lib/pkgconfig/:$PKG_CONFIG_PATH
#QT_PLUGIN_PATH=$QTDIR/lib/plugins/
QMAKE_INCLUDE=$WLD/include
QMAKE_LIBDIR=$WLD/lib
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1
unset QTDIR
PATH="$SOURCE/qt5/qtbase/bin:$SOURCE/qt5/qtrepotools/bin:$PATH"
QT_QPA_PLATFORM=wayland # instead of args -platform wayland
export QTVER QTDIR PATH LD_LIBRARY_PATH PKG_CONFIG_PATH QT_PLUGIN_PATH QMAKE_INCLUDE QMAKE_LIBDIR PKG_CONFIG_ALLOW_SYSTEM_CFLAGS QTDIR PATH QT_QPA_PLATFORM



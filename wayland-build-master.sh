#!/bin/bash

# This builds and installs Wayland on Debian Wheezy machines with most video cards.

set -e # exit script if anything fails

# Change this to where you want everything installed:
WLD=$HOME/wayland_work/install
export WLD
SOURCE=$HOME/wayland_work/source
export SOURCE

# Change to 1 to build relevant stuff.  You'll need wayland built to
# build the others.  But you can enable only wayland, build it, then
# disable wayland and enable something else.  Or you can disable all of
# them to just run wayland (weston).
BUILD_WAYLAND=1
BUILD_GTK=0 # doesn't work with master
BUILD_QT=0 # doesn't work with master
BUILD_XWAYLAND=0

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



if [ "$XDG_RUNTIME_DIR" == "" ]
then
    XDG_RUNTIME_DIR=/tmp
    export XDG_RUNTIME_DIR
fi
GDK_BACKEND=wayland
export GDK_BACKEND

if [ ! -d $WLD ]
then
    mkdir -p $WLD
fi
if [ ! -d $WLD/share/aclocal ]
then
    mkdir -p $WLD/share/aclocal
fi
if [ ! -d $SOURCE ]
then
    mkdir -p $SOURCE
fi
cd $SOURCE


# Changes:
# 2010-11-20 Changes from André de Souza Pinto
# 2010-12-06 "set -e" instead of "set -u".  More aggressive git cleaning.
# 2010-12-29 --with-xkb-config-root, WAYLAND_DEBUG, 
#            gtk building stuff that doesn't work yet
# 2011-01-03 Upstream gtk git, reset --hard
# 2011-01-04 Conditional for building gtk instead of commenting out
# 2011-01-07 Don't reset to origin/master, build vte, added
#            gobject-introspection package required to build vte, added
#            gperf for gtk
# 2011-01-23 Added pixman git, new dep of cairo, stop using deprecated
#            --enable-gles-overlay
# 2011-01-26 Install rsvg-convert for new window icon, also start:
#            eventdemo, resizor, and simple-client
# 2011-01-31 Remove --disable-gallium-{i915,i965} from mesa build flags
# 2011-02-08 Update for wayland-egl.
# 2011-02-13 Stop building Gallium EGL driver, nolonger needed.
# 2011-02-14 Only do Ubuntu stuff if on Ubuntu.  Re-install
#            70-wayland.rules if previously installed but different.
#            Don't change XDG_RUNTIME_DIR if it's already set.
# 2011-02-16 Update for wayland repo split.
# 2011-04-02 Change build order to match instructions, thanks to creak
#            in #wayland.
# 2012-03-10 Non-functional attempt to update for Ubuntu Oneric.
# 2012-03-12 Made functional by adding flex, llvm-dev, libxcb-xfixes0-dev
#            libjpeg-dev to installed packages.
#            Changed weston's make install to use sudo.
# 2012-03-12 Cleaned up mesa build args, changed installprefix variable
#            from $installprefix to $WLD to match build instructions.
# 2012-03-14 Actually got wayland to run.
# 2012-03-14 Download to $SOURCE instead of $WLD.  Re-enabled building
#            cairo-gl - supposedly optional.  Update GTK build, might
#            be done, suspect gtk git bug.
# 2012-03-14 Preliminary xwayland stuff, didn't work.
# 2012-03-16 Add $WLD/bin to path to get latest gtk to build.  Switch back
#            to latest gtk.
# 2012-03-16 Cleanup cloning branches.
# 2012-03-21 Switch vte from branch vte-0-30 to vte-0-32 which apparently
#            works better.
# 2012-03-23 Added Qt + qtwebkit, not tested.  Fix apt-get install
#            for GTK+.  Add $BUILD_WAYLAND var so it's easier to skip.
# 2012-03-24 Builds fancybrowser (qtwebkit), doesn't run it, qt5
#            downloading not test.ed
# 2012-03-24 Re-enable set -e for everything but qt5 make.  Fixed running
#            webkit.
# 2012-03-24 Base running of vte and webkit on file existence, so it's
#            easier to use this script to just run everything.
# 2012-03-24 Only apt-get install packages for wayland if building
#            wayland.
# 2012-03-25 Updated xwayland build, still not working.  Added bison to
#            installed packags.
# 2012-04-06 Check out specific cairo commit before bug, also build
#            pango - new gtk dependency.
# 2012-04-06 Fixed pango git clone command.
# 2012-04-08 Install more ubuntu packages for QT5.
# 2012-04-15 Switch mesa back to master - 8.0 no-longer biulds against
#            drm master, and wayland 0.85 now builds against mesa master.
#            Problem reported by runeks.  Disabled Qt build by default
#            because it's so problematic, mostly the download.
# 2012-04-21 Added comment with the reason for the cairo checkout:
#            https://bugs.freedesktop.org/show_bug.cgi?id=48221
# 2012-04-24 Update master build script from 0.85 build script.
# 2012-04-25 Build XWayland stuff, works.
# 2012-04-25 Update Intel DDX checkout to branch xwayland-1.12.
# 2012-05-10 Add a couple missing X dependencies.
# 2012-07-31 Fixed missing "cd .." before xf86-video-wlshm, reported
#            by scientes.
# 2012-09-05 Stop checking out old cairo commit, update repos for xserver,
#            intel, wlshm, and ati/radeon.  Tested on Ubuntu Quantal.
# 2012-09-06 Build more stuff from source because Oneric's versions
#            are too old:  xcb-proto, libxcb (xcb-glx), inputproto,
#            libpciaccess, glproto, randrproto.  These can be resolved
#            with packages in Quantal.  Tested on Ubuntu Oneric.
# 2012-10-24 Convert from Ubuntu to Debian, because Ubuntu has become
#            ad-ware:  http://www.chaosreigns.com/journal/320767.html
#            Also install packages: doxygen libxcursor-dev (weston).
#            Remove --xserver from weston command for now.  Comment out
#            xcb/proto build due to bug:
#            https://bugs.freedesktop.org/show_bug.cgi?id=56375
#            Remove libxcb due to dependency on xcb/proto git.

# Should I install Debian packages?
if [ -e /etc/debian_version ]
then
    if [ $BUILD_WAYLAND == '1' ]
    then
        sudo apt-get install libffi-dev libexpat1-dev libpciaccess-dev xutils-dev libx11-dev libxext-dev libxdamage-dev libx11-xcb-dev libxcb-glx0-dev libudev-dev build-essential git xkb-data autoconf libtool llvm libcairo2-dev flex llvm-dev libxcb-xfixes0-dev libjpeg-dev libxcb-dri2-0-dev libgdk-pixbuf2.0-dev bison libmtdev-dev libpam0g-dev doxygen libxcursor-dev
    fi
    if [ $BUILD_GTK == '1' ]
    then
        sudo apt-get install gtk-doc-tools gobject-introspection libpango1.0-dev gperf
    fi
    if [ $BUILD_QT == '1' ]
    then
        sudo apt-get install curl ruby apache2 libapache2-mod-php5 libicu-dev libxt-dev libgail-dev libsqlite3-dev libxslt1-dev libgeoclue-dev libgstreamer-plugins-base0.10-dev libedit-dev libxcb-icccm4 libxcb-icccm4-dev libxcb-image0 libxcb-image0-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-sync0 libxcb-sync0-dev 
    fi
    if [ $BUILD_XWAYLAND == '1' ]
    then
        sudo apt-get install libxfont-dev libxkbfile-dev x11proto-bigreqs-dev x11proto-composite-dev x11proto-fonts-dev x11proto-randr-dev x11proto-record-dev x11proto-resource-dev x11proto-scrnsaver-dev x11proto-video-dev x11proto-xcmisc-dev x11proto-xf86dri-dev
    fi
fi

# 2012-03-12 mesa   flex
# 2012-03-12 mesa   llvm-dev
# 2012-03-12 weston libxcb-xfixes0-dev No package 'xcb-xfixes' found
# 2012-03-12 weston libjpeg-dev        configure: error: libjpeg not found
# 2012-03-13 mesa   libxcb-dri2-0-dev  EGL drivers missing egl_dri2
# GTK:
# 2012-03-14 glib   gtk-doc-tools      *** No GTK-Doc found, please install it ***
# 2012-03-14 gtk    gobject-introspection gdk/Makefile.am:187: HAVE_INTROSPECTION does not appear in AM_CONDITIONAL
# 2012-03-14 gtk    libpango1.0-dev No package 'pango' found
# 2012-03-14 ?      gperf  You need to install GNU gperf
# xwayland:
# 2012-03-14 xserver x11proto-xcmisc-dev No package 'xcmiscproto' found
# 2012-03-14 xserver x11proto-bigreqs-dev No package 'bigreqsproto' found
# 2012-03-14 xserver x11proto-randr-dev No package 'randrproto' found
# 2012-03-14 xserver x11proto-fonts-dev No package 'fontsproto' found
# 2012-03-14 xserver x11proto-video-dev No package 'videoproto' found
# 2012-03-14 xserver x11proto-composite-dev No package 'compositeproto' found
# 2012-03-14 xserver x11proto-record-dev No package 'recordproto' found
# 2012-03-14 xserver x11proto-resource-dev No package 'resourceproto' found
# 2012-03-14 xserver libxkbfile-dev No package 'xkbfile' found
# 2012-03-14 xserver libxfont-dev No package 'xfont' found
# 2012-04-22 weston  libmtdev-dev No package 'mtdev' found
# 2012-04-22 weston  libpam0g-dev configure: error: weston-launch requires pam
# 2012-04-22 xserver x11proto-xcmisc-dev No package 'xcmiscproto' found
# 2012-04-22 xserver x11proto-bigreqs-dev No package 'bigreqsproto' found
# 2012-04-22 xserver x11proto-fonts-dev No package 'fontsproto' found
# 2012-04-22 xserver x11proto-video-dev No package 'videoproto' found
# 2012-04-22 xserver x11proto-record-dev package 'recordproto' found
# 2012-04-22 xserver x11proto-resource-dev No package 'resourceproto' found
# 2012-04-22 xserver libxfont-dev No package 'xfont' found           
# 2012-04-22 xserver x11proto-xf86dri-dev No package 'xf86driproto' found
# 2012-04-22 xserver x11proto-scrnsaver-dev No package 'scrnsaverproto' found


if [ $BUILD_WAYLAND == '1' ]
then
    echo "Building wayland.";

    # Wayland libraries, required by Mesa
    if [ ! -d wayland ]
    then
        git clone http://anongit.freedesktop.org/git/wayland/wayland.git #-b 0.85
    else
        cd wayland
        $CLEAN
        git pull
        #     git checkout 0.85
        git checkout master
        cd ..
    fi
    cd wayland/
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    # Needed for wayland on nouveau and ATI
    if [ ! -d drm ]
    then
        git clone http://anongit.freedesktop.org/git/mesa/drm.git
    else
        cd drm
        $CLEAN
        git pull
        cd ..
    fi
    cd drm
    ./autogen.sh --prefix=$WLD --enable-nouveau-experimental-api
    make
    make install
    cd ..

    # Needed for libX11 and xproto
    if [ ! -d macros ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/util/macros.git
    else
        cd macros
        $CLEAN
        git pull
        cd ..
    fi
    cd macros
    ./autogen.sh --prefix=$WLD
    make install
    cd ..

    # Needed for mesa
    if [ ! -d glproto ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/proto/glproto.git
    else
        cd glproto
        $CLEAN
        git pull
        cd ..
    fi
    cd glproto
    ./autogen.sh --prefix=$WLD
    make install
    cd ..

    # Needed for mesa
    if [ ! -d dri2proto ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/proto/dri2proto.git
    else
        cd dri2proto
        $CLEAN
        git pull
        cd ..
    fi
    cd dri2proto
    ./autogen.sh --prefix=$WLD
    make install
    cd ..

    # xcb/proto py-compile bug: https://bugs.freedesktop.org/show_bug.cgi?id=56376
    #  # needed for libxcb: No package 'xcb-proto' found
    #  if [ ! -d proto ]
    #  then
    #     git clone git://anongit.freedesktop.org/xcb/proto
    #  else
    #     cd proto
    #     $CLEAN
    #     git pull
    #     cd ..
    #  fi
    #  cd proto
    #  ./autogen.sh --prefix=$WLD
    #  make install
    #  cd ..
    #
    #  # Needed for mesa: Requested 'xcb-glx >= 1.8.1' but version of XCB GLX is 1.7
    #  if [ ! -d libxcb ]
    #  then
    #     git clone git://anongit.freedesktop.org/xcb/libxcb
    #  else
    #     cd libxcb
    #     $CLEAN
    #     git pull
    #     cd ..
    #  fi
    #  cd libxcb
    #  ./autogen.sh --prefix=$WLD
    #  make install
    #  cd ..


    # Needed for wayland
    if [ ! -d mesa ]
    then
        # 8.0 no-longer biulds against drm master, and wayland 0.85 now builds against mesa master - 2012-04-15
        git clone http://anongit.freedesktop.org/git/mesa/mesa.git
    else
        cd mesa
        $CLEAN
        git pull
        #git checkout 8.0
        git checkout master
        cd ..
    fi
    cd mesa
    # Now using egl_dri2 for everything.
    ./autogen.sh --prefix=$WLD --enable-gles2 --disable-gallium-egl --with-egl-platforms=wayland,x11,drm --enable-gbm --enable-shared-glapi --with-gallium-drivers=r300,r600,swrast,nouveau
    # Nouveau build problem:
    #./autogen.sh --prefix=$WLD --enable-gles2 --disable-gallium-egl --with-egl-platforms=wayland,x11,drm --enable-gbm --enable-shared-glapi --with-dri-drivers=swrast,i965,radeon

    make
    make install
    cd ..

    # Needed for libxkbcommon
    if [ ! -d xproto ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/proto/xproto.git
    else
        cd xproto
        $CLEAN
        git pull
        cd ..
    fi
    cd xproto
    ./autogen.sh --prefix=$WLD
    make install
    cd ..

    # Needed for libxkbcommon
    if [ ! -d kbproto ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/proto/kbproto.git
    else
        cd kbproto
        $CLEAN
        git pull
        cd ..
    fi
    cd kbproto/
    ./autogen.sh --prefix=$WLD
    make install
    cd ..

    # Needed for libxkbcommon
    if [ ! -d libX11 ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/lib/libX11.git
    else
        cd libX11
        $CLEAN
        git pull
        cd ..
    fi
    cd libX11
    ./autogen.sh --prefix=$WLD
    make install
    cd ..

    # Needed for wayland
    if [ ! -d libxkbcommon ]
    then
            git clone http://anongit.freedesktop.org/git/xorg/lib/libxkbcommon.git
    else
        cd libxkbcommon
        $CLEAN
        git pull
        #     git checkout for-weston-0.85
        git checkout master
        cd ..
    fi
    cd libxkbcommon/
    ./autogen.sh --prefix=$WLD --with-xkb-config-root=/usr/share/X11/xkb
    make
    make install
    cd ..

    # Needed for cairo
    if [ ! -d pixman ]
    then
        git clone http://anongit.freedesktop.org/git/pixman.git
    else
        cd pixman
        $CLEAN
        git pull
        cd ..
    fi
    cd pixman
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    # Needed for wayland
    if [ ! -d cairo ]
    then
        git clone http://anongit.freedesktop.org/git/cairo
        cd cairo
        # https://bugs.freedesktop.org/show_bug.cgi?id=48221
        #git checkout aed5a1cf1e38ae451d2aeaf0a56aa1248b42c0fa
        cd ..
    else
        cd cairo
        #git checkout aed5a1cf1e38ae451d2aeaf0a56aa1248b42c0fa
        $CLEAN
        git pull
        cd ..
    fi
    cd cairo
    ./autogen.sh --prefix=$WLD --enable-gl --enable-xcb
    make
    make install
    cd ..

    # Wayland demo applications (compositor, terminal, flower, etc.)
    if [ ! -d weston ]
    then
        git clone http://anongit.freedesktop.org/git/wayland/weston.git
    else
        cd weston
        $CLEAN
        git pull
        #     git checkout 0.85
        git checkout master
        cd ..
    fi
    cd weston
    #./autogen.sh --prefix=$WLD
    ./autogen.sh --prefix=$WLD --disable-setuid-install # To remove need for sudo
    make
    #sudo make install # Because weston is installed setuid root
    make install # Need to enable --disable-setuid-install above to use this.
    cd ..

    # No-longer used?
    # # The one file that needs to be installed outside of ~/install/ .
    # #diff -q wayland/compositor/70-wayland.rules /etc/udev/rules.d/70-wayland.rules
    # #if [ $? -eq 1 ] && [ -d /etc/udev/rules.d ]
    # #then
    #    sudo cp -a wayland-demos/compositor/70-wayland.rules /etc/udev/rules.d/
    #    sudo udevadm trigger --subsystem-match=drm --subsystem-match=input
    # #fi
fi

if [ $BUILD_GTK == '1' ]
then
    echo "Building GTK with vte."

    if [ ! -d glib ]
    then
        git clone https://git.gnome.org/glib
    else
        cd glib
        $CLEAN
        git pull
        cd ..
    fi
    cd glib
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    if [ ! -d atk ]
    then
        git clone https://git.gnome.org/atk
    else
        cd atk
        $CLEAN
        git pull
        cd ..
    fi
    cd atk
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    if [ ! -d pango ]
    then
        git clone https://git.gnome.org/pango
    else
        cd pango
        $CLEAN
        git pull
        cd ..
    fi
    cd pango
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    # As of 2012-03-14, gtk git is saying:
    # Requested 'gdk-pixbuf-2.0 >= 2.25.2' but version of GdkPixbuf is 2.24.0
    if [ ! -d gdk-pixbuf ]
    then
        git clone https://git.gnome.org/gdk-pixbuf
    else
        cd gdk-pixbuf
        $CLEAN
        git pull
        cd ..
    fi
    cd gdk-pixbuf
    ./autogen.sh --prefix=$WLD --without-libtiff # Is it worth grabbing libtiff?
    make
    make install
    cd ..

    if [ ! -d gtk+ ]
    then
        #git clone git://anongit.freedesktop.org/~krh/gtk --branch wayland-backend
        #git clone git://git.gnome.org/gtk+ --branch gdk-backend-wayland
        git clone https://git.gnome.org/gtk+
        #      git checkout 12e661c801d34d8759e781e51bfd902a99e3538a
    else
        cd gtk+
        $CLEAN
        git pull
        #      git checkout 12e661c801d34d8759e781e51bfd902a99e3538a
        cd ..
    fi
    cd gtk+
    #./autogen.sh --prefix=$WLD --enable-wayland-backend --enable-x11-backend
    ./autogen.sh --prefix=$WLD --enable-wayland-backend
    make
    make install
    cd ..

    if [ ! -d vte ]
    then
        git clone https://git.gnome.org/vte -b vte-0-32
    else
        cd vte
        $CLEAN
        git pull
        git checkout vte-0-32
        cd ..
    fi
    cd vte
    ./autogen.sh --prefix=$WLD --with-gtk=3.0 # --with-gtk=3.0 nolonger needed?
    make
    make install
    cd ..
fi


if [ $BUILD_QT == '1' ]
then
    echo "Building qt5 with webkit.";

    if [ ! -d qt5 ]
    then
        git clone https://gitorious.org/qt/qt5 # 0:38.56elapsed
        cd qt5
        perl init-repository # 1:00:19elapsed 46:53.51elapsed
    else
        cd qt5
    fi
    cd qtwayland
    git clean -xfd
    git checkout 0.85
    cd ..
    #./configure -confirm-license -developer-build -opensource -nomake examples -nomake tests -prefix $WLD/qt5 # 0:48.11elapsed
    #./configure -confirm-license -opensource -nomake examples -nomake tests -prefix $WLD/qt5 # 0:48.11elapsed
    ./configure -confirm-license -developer-build -opensource -nomake examples -nomake tests # 0:48.11elapsed # works, but only installs to $SOURCE
    set +e # I think qt5's make always returns non-zero :(
    make # 37:43.72elapsed
    #   make install 
    #   make module-qtwebkit # shouldn't be necessary, but sometimes is?
    #   make install 
    make module-qtwayland # 0:14.01elapsed
    #   PATH=$WLD/qt5:$PATH # Who ever heard of needing to set this for
    #   QTDIR=$WLD/qt5      # make install to work?  Doesn't help :(
    #   export PATH QTDIR
    make install # 2:18.32elapsed
    set -e
    cd ..
fi


if [ $BUILD_XWAYLAND == '1' ]
then
    if [ ! -d inputproto ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/proto/inputproto.git
    else
        cd inputproto
        $CLEAN
        git pull
        cd ..
    fi
    cd inputproto
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    if [ ! -d libpciaccess ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/lib/libpciaccess.git
    else
        cd libpciaccess
        $CLEAN
        git pull
        cd ..
    fi
    cd libpciaccess
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    if [ ! -d glproto ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/proto/glproto.git
    else
        cd glproto
        $CLEAN
        git pull
        cd ..
    fi
    cd glproto
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    if [ ! -d randrproto ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/proto/randrproto.git
    else
        cd randrproto
        $CLEAN
        git pull
        cd ..
    fi
    cd randrproto
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    if [ ! -d xserver ]
    then
        git clone http://anongit.freedesktop.org/git/xorg/xserver.git -b xwayland-1.12
    else
        cd xserver
        $CLEAN
        git pull
        git checkout xwayland-1.12
        cd ..
    fi
    cd xserver
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    if [ ! -d xf86-video-intel ]
    then
        #git clone git://people.freedesktop.org/~krh/xf86-video-intel -b xwayland-1.12
        git clone http://anongit.freedesktop.org/git/xorg/driver/xf86-video-intel.git -b xwayland
    else
        cd xf86-video-intel
        $CLEAN
        git pull
        git checkout
        cd ..
    fi
    cd xf86-video-intel
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    if [ ! -d xf86-video-wlshm ]
    then
        git clone http://cgit.collabora.com/git/user/daniels/xf86-video-wlshm.git
        sed -i -e s/hosted.h/xwayland.h/ xf86-video-wlshm/src/wlshm.h
    else
        cd xf86-video-wlshm
        $CLEAN
        #      git pull
        cd ..
    fi
    cd xf86-video-wlshm
    ./autogen.sh --prefix=$WLD
    make
    make install
    cd ..

    # Radeon
    if [ ! -d xf86-video-ati ]
    then
        #git clone https://github.com/timon37/xf86-video-ati
        git clone https://github.com/RAOF/xf86-video-ati -b xwayland
    else
        cd xf86-video-ati
        $CLEAN
        git pull
        cd ..
    fi
    cd xf86-video-ati
    ./autogen.sh --prefix=$WLD
    make
    make install

    cd ..

    if [ ! -e $WLD/share/X11/xkb/rules/evdev ]
    then
        mkdir -p $WLD/share/X11/xkb/rules
        ln -s /usr/share/X11/xkb/rules/evdev $WLD/share/X11/xkb/rules/
    fi
    if [ ! -e $WLD/bin/xkbcomp ]
    then
        ln -s /usr/bin/xkbcomp $WLD/bin/
    fi
fi

echo -e "\nRunning weston, the example wayland compositor."

#$WLD/bin/weston --xserver &
$WLD/bin/weston &
echo "Sleeping 2 seconds so the compositor is actually running by the time I run other stuff."
sleep 2
#$SOURCE/weston/clients/clickdot &
#$SOURCE/weston/clients/dnd &
#$SOURCE/weston/clients/eventdemo &
$SOURCE/weston/clients/flower &
#$SOURCE/weston/clients/image &
#$SOURCE/weston/clients/resizor &
#$SOURCE/weston/clients/screenshot &
#$SOURCE/weston/clients/simple-egl &
#$SOURCE/weston/clients/simple-shm &
#$SOURCE/weston/clients/simple-touch &
#$SOURCE/weston/clients/smoke &
#$SOURCE/weston/clients/view &
#$SOURCE/weston/clients/weston-desktop-shell &
#$SOURCE/weston/clients/weston-tablet-shell &
#$SOURCE/weston/clients/weston-terminal &
$WLD/bin/weston-terminal &



#   $SOURCE/gtk+/tests/testgtk &

if [ -e $WLD/bin/vte2_90 ]
then
    echo "Running vte, a gtk+ terminal client."
    $WLD/bin/vte2_90 &
else
    echo "vte terminal client isn't installed."
fi

# Run webkit web browser!
if [ -e $SOURCE/qt5/qtwebkit-examples-and-demos/examples/webkit/fancybrowser/fancybrowser ]
then
    echo "Running fancybrowser / qtwebkit."
    $SOURCE/qt5/qtwebkit-examples-and-demos/examples/webkit/fancybrowser/fancybrowser &
else
    echo "QtWebKit web browser isn't installed.";
fi

if [ -e $WLD/bin/Xorg ]
then
    echo "Running X.org rootless as DISPLAY=:2"
    $WLD/bin/Xorg -config bah/xorg.conf -wayland -rootless :2 &
    echo "Running xterm via rootless X.org"
    #   DISPLAY=:2
    #   export DISPLAY
    "xterm -display :2 &";
fi

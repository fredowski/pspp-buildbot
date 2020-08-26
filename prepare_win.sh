#!/bin/bash -xve

# Finish the setup of the opensuse windows cross compile machine

cd

sudo zypper install -y gcc perl \
        pkg-config git unzip curl libtool \
        make \
        glibc-locale

# gettext crashes on xgettext 0.19.8.1 on opensuse
gettext=gettext-0.21
curl -Lo gettext.tar.xz https://ftp.gnu.org/pub/gnu/gettext/$gettext.tar.xz
tar xf gettext.tar.xz
cd gettext-0.21
./configure --prefix=/usr --libdir=/usr/lib64
make -j4
sudo make install
cd


# Cross Compile setup for pspp
sudo zypper -n addrepo -G https://download.opensuse.org/repositories/windows:mingw:win64/\
openSUSE_Leap_15.2/windows:mingw:win64.repo

sudo zypper -n refresh

sudo zypper install -y mingw64-cross-gcc makeinfo wget wine glib2-devel \
     mingw64-cross-pkgconf mingw64-glib2-tools mingw64-hicolor-icon-theme \
     mingw64-libgsl-devel mingw64-gtk3-devel \
     mingw64-libtool \
     mingw64-win_iconv-devel mingw64-gdb dos2unix \
     mingw64-readline-devel \
     mingw64-libxml2-devel

sudo chown -R pspp:users /usr/x86_64-w64-mingw32

#Adwaita icon theme
curl -Lo adwaita.tar.xz https://download.gnome.org/sources/\
adwaita-icon-theme/3.34/adwaita-icon-theme-3.34.3.tar.xz
tar xf adwaita.tar.xz
cd adwaita-icon-theme-3.34.3
mingw64-configure
mingw64-make -j4
mingw64-make install
cd

# gtksourceview3 is not on opensuse
curl -Lo gtks.tar.xz https://download.gnome.org/sources/gtksourceview/3.24/gtksourceview-3.24.10.tar.xz
tar xf gtks.tar.xz
cd gtksourceview-3.24.10
mingw64-configure
mingw64-make -j4
mingw64-make install
cd



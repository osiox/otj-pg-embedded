#!/bin/bash -ex
# NB: This is the *server* version, which is not to be confused with the client library version.
# The important compatibility point is the *protocol* version, which hasn't changed in ages.
VERSION=9.6.6-3
#VERSION=9.5.10-2

POSTGIS_VERSION_WIN=pg96-2.5.1x64
#POSTGIS_VERSION_WIN=pg95-2.3.5x64

apt-get update && apt-get install -y postgresql-9.6-postgis-2.3

RSRC_DIR=$PWD/target/generated-resources

[ -e $RSRC_DIR/.repacked ] && echo "Already repacked, skipping..." && exit 0

cd `dirname $0`

PACKDIR=$(mktemp -d -t wat.XXXXXX)

OSX_DIST=dist/postgresql-$VERSION-osx-binaries.zip
WINDOWS_DIST=dist/postgresql-$VERSION-win-binaries.zip

WINDOWS_POSTGIS_DIST=dist/postgis-bundle-$POSTGIS_VERSION_WIN.zip

mkdir -p dist/ target/generated-resources/
[ -e $OSX_DIST ] || wget -O $OSX_DIST "http://get.enterprisedb.com/postgresql/postgresql-$VERSION-osx-binaries.zip"
[ -e $WINDOWS_DIST ] || wget -O $WINDOWS_DIST "http://get.enterprisedb.com/postgresql/postgresql-$VERSION-windows-x64-binaries.zip"

[ -e $WINDOWS_POSTGIS_DIST ] || wget -O $WINDOWS_POSTGIS_DIST "https://winnie.postgis.net/download/windows/pg96/buildbot/postgis-bundle-$POSTGIS_VERSION_WIN.zip"

# Linux distribution
mkdir -p $PACKDIR/pgsql/share/postgresql $PACKDIR/pgsql/lib $PACKDIR/pgsql/bin
cp -r /usr/share/postgresql/9.6/* $PACKDIR/pgsql/share/postgresql
cp -r /usr/lib/postgresql/9.6/lib/* $PACKDIR/pgsql/lib
cp -r /usr/lib/postgresql/9.6/bin/* $PACKDIR/pgsql/bin
pushd $PACKDIR/pgsql
tar cJf $RSRC_DIR/postgresql-Linux-x86_64.txz \
  share/postgresql \
  lib \
  bin
popd

rm -fr $PACKDIR && mkdir -p $PACKDIR

# OSX distribution
unzip -q -d $PACKDIR $OSX_DIST
pushd $PACKDIR/pgsql
tar cJf $RSRC_DIR/postgresql-Darwin-x86_64.txz \
  share/postgresql \
  lib/*.dylib \
  lib/postgresql/*.so \
  bin/initdb \
  bin/pg_ctl \
  bin/postgres
popd

rm -fr $PACKDIR && mkdir -p $PACKDIR

# Windows distribution with postgis extension
unzip -q -d $PACKDIR $WINDOWS_DIST
unzip -q -d $PACKDIR $WINDOWS_POSTGIS_DIST
cp -r $PACKDIR/postgis-bundle-$POSTGIS_VERSION_WIN/* $PACKDIR/pgsql
pushd $PACKDIR/pgsql
tar cJf $RSRC_DIR/postgresql-Windows-x86_64.txz \
  share \
  lib/iconv.lib \
  lib/libxml2.lib \
  lib/ssleay32.lib \
  lib/ssleay32MD.lib \
  lib/*.dll \
  bin/initdb.exe \
  bin/pg_ctl.exe \
  bin/postgres.exe \
  bin/*.dll \
  gdal-data \
  utils
popd

rm -rf $PACKDIR
touch $RSRC_DIR/.repacked

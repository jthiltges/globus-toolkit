#!/bin/sh

VERSION="3.9.3rc1"
TAGOPTS="-t2=HEAD -t3=HEAD"
INSTALLER="gt${VERSION}-wsrf-source-installer"
GPT="fait_accompli/gpt-3.2autotools2004-src.tar.gz"

mkdir $INSTALLER

./make-packages.pl $TAGOPTS --bundles=gt2-threaded,gt2-unthreaded,globus-rls-server,gt4-java-ws-core,gt4-mds,gt4-delegation,gt4-rft,gt4-gram,gt4-cas,gt4-c-ws-core --version=$VERSION --installer=install-wsrf $@

if [ $? -ne 0 ]; then
   echo "ERROR"
   exit 1
fi

mkdir $INSTALLER/bundles
cp bundle-output/*.tar.gz $INSTALLER/bundles
cp bundle-output/install-wsrf $INSTALLER
chmod +x $INSTALLER/install-wsrf
cp $GPT $INSTALLER

# make the dir where the GRAM scheduler bundles will go
mkdir $INSTALLER/schedulers

# build the PBS bundle
rm -fr *-output
./make-packages.pl -n --bundles=gt4-gram-pbs --version=$VERSION
cp bundle-output/*.tar.gz  $INSTALLER/schedulers

# build the Condor bundle
rm -fr *-output
./make-packages.pl -n --bundles=gt4-gram-condor --version=$VERSION
cp bundle-output/*.tar.gz  $INSTALLER/schedulers

# build the LSF bundle
rm -fr *-output
./make-packages.pl -n --bundles=gt4-gram-lsf --version=$VERSION
cp bundle-output/*.tar.gz  $INSTALLER/schedulers

if [ -d contrib ]; then
    cp -Rp contrib $INSTALLER
fi

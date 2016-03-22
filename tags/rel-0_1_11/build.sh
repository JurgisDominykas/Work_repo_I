#!/bin/bash

# DEFINITIONS (currently only hardcoded)
PACKAGE=FieldTree
LOCALOTRS=/opt/otrs3
REMOTESRV=muiline.com
REMOTEOTRS=/opt/otrs-vanilla
REMOTEUSR=skirsdeda
# remote otrs package repository (relative to user home directory)
REMOTEPKGREPO=public_html/software/otrs-packages-repo

svn up
# TODO: padaryti kad automatiskai padidintu package'o versija / atnaujintu package'o failu sarasa
sudo $LOCALOTRS/bin/otrs.PackageManager.pl -a build -p ./$PACKAGE.sopm -d ./ -o ./
read -s -p "Remote server password: " SSHPASS && echo
export SSHPASS
curl -T ./$PACKAGE-*.opm -u $REMOTEUSR:$SSHPASS ftp://$REMOTESRV/$REMOTEPKGREPO/
VER=`sshpass -V | head -n 1 | sed 's/.*\([0-9]\.[0-9]\{2\}\).*/\1/'`
if [[ "$VER" < "1.05" ]]; then
    echo "sshpass 1.05 or newer needed! Quitting."
    exit
fi
sshpass -e ssh $REMOTEUSR@$REMOTESRV "sudo $REMOTEOTRS/bin/otrs.PackageManager.pl -a index -d /home/$REMOTEUSR/$REMOTEPKGREPO > /home/$REMOTEUSR/$REMOTEPKGREPO/otrs.xml"
unset SSHPASS
mv -f ./$PACKAGE-*.opm ./build/
svn add ./build/* -q
svn commit

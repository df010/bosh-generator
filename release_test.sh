#!/bin/bash -x
#$1 release folder
#$2 packages order
#$3 jobs order
#$4 properties yml for job spec

CURRENT_FOLDER=`pwd`
REL_FOLDER=`cd $1;pwd`
DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

PKG_IN_ORDER=`echo $2 | tr "," " "`
sudo mkdir -p /var/vcap
sudo chown vcap:vcap -R /var/vcap
rm -rf /var/vcap/*

#sudo adduser --disabled-password --gecos "" vcap
mkdir -p /var/vcap/store
mkdir /var/vcap/build
mkdir /var/vcap/monit
cp -r $REL_FOLDER/jobs /var/vcap/build
cp -r $REL_FOLDER/packages /var/vcap/build
cp -r $REL_FOLDER/src /var/vcap/build
chown -R vcap  /var/vcap

$DIR/packaging.sh $2
$DIR/start_jobs.sh $DIR $3 $CURRENT_FOLDER/$4







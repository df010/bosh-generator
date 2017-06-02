#!/bin/bash -x
#$1 release folder
#$2 packages order
#$3 jobs order
#$4 properties yml for job spec

CURRENT_FOLDER=`pwd`
REL_FOLDER=`cd $1;pwd`
DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

PKG_IN_ORDER=`echo $2 | tr "," " "`
sudo rm -rf /var/vcap/*

#sudo adduser --disabled-password --gecos "" vcap
sudo mkdir -p /var/vcap/store
sudo mkdir /var/vcap/build
sudo mkdir /var/vcap/monit
sudo cp -r $REL_FOLDER/jobs /var/vcap/build
sudo cp -r $REL_FOLDER/packages /var/vcap/build
sudo cp -r $REL_FOLDER/src /var/vcap/build
sudo chown -R vcap  /var/vcap

sudo $DIR/packaging.sh $2
sudo $DIR/start_jobs.sh $DIR $3 $CURRENT_FOLDER/$4







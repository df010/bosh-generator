#!/bin/bash  -x
echo `whoami`
echo $PATH
set +x 
#source /home/vcap/.bash_profile
ARG1=$1
ARG2=$2
ARG3=$3
#shift
#shift
#shift
#source /home/vcap/.rvm/scripts/rvm
#rvm use 2.1.5
#set -x 
cd /var/vcap/build 
JOB_IN_ORDER=`echo $ARG2 | tr "," " "`
if [ -z "$JOB_IN_ORDER" ];then 
   JOB_IN_ORDER=`ls -1  jobs/|xargs echo`
fi

cd $ARG1
bundle install

for job in $JOB_IN_ORDER; do

   bundle exec job_render.rb  /var/vcap/build/jobs/$job/ /var/vcap/jobs/$job/ $ARG3
   cp /var/vcap/build/jobs/$job/monit /var/vcap/jobs/$job/
done

chmod +x /var/vcap/jobs/*/bin/*
if [[ "`uname`" == "Darwin" ]]; then
  tar -xvf tools/monit-*macos*.tar.gz -C /var/vcap/monit/
else
  tar -xvf tools/monit-*linux*.tar.gz -C /var/vcap/monit/
fi

cp tools/monitrc /var/vcap/monit/
chmod 700 /var/vcap/monit/monitrc
cp tools/monit.user /var/vcap/monit/
/var/vcap/monit/monit-*/bin/monit -I -c /var/vcap/monit/monitrc

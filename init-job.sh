#!/bin/bash -x

#init-job.sh RELEASE_FOLDER

RELEASE_FOLDER=`cd $1;pwd`
DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

prop () {
  echo -e  "  $1:\n    default: 1\n    description: $1\n"
}
consume () {
  echo -e "- name: peers\n  type: peers_type\n"
}

process_def () {
  jobname=$1
  file=`basename $2`
  ctl_file=`echo $file|sed "s/\.erb$//"`
  p_name=`echo $ctl_file|sed "s/_ctl$//"`
echo -e "check process $p_name\n\
  with pidfile /var/vcap/sys/run/$jobname/$p_name.pid\n\
  start program \"/var/vcap/jobs/$jobname/bin/$ctl_file start\"\n\
  stop program \"/var/vcap/jobs/$jobname/bin/$ctl_file stop\"\n\
  group vcap\n"
}

map_template () {
  file=`basename $1`
  map=`echo $file|sed "s/\.erb$//"`
  head -n 1 $1|grep -e "^#\!" > /dev/null
  if [[ "$?" == "0" ]]
  then
    echo "  ${file}: bin/${map}"
  else
    echo "  ${file}: config/${map}"
  fi
}

init_job () {
  echo "haha $1"
  jobname=`echo $1|cut -d"/" -f2`
  export -f map_template
  export -f prop
  export -f consume
  templates=`find jobs/${jobname}/templates -depth 1 -type f|xargs -I % bash -c "map_template %"`
  packages=`ls -1 packages|xargs -I % echo "- %"`
  props=`find jobs/${jobname}/templates -depth 1 -type f|xargs cat|\
  sed 's/</\n</g'|sed -n 's/.*<%= *p(\(.*\)) *%>.*/\1/p'|tr -d '"' |tr -d "'" |uniq|\
  xargs -I % bash -c "prop %"`

  consumes=`find jobs/${jobname}/templates -depth 1 -type f|xargs cat|\
  sed 's/</\n</g'|sed -n 's/.*<%.*link(\(.*\)).*%>.*/\1/p'|tr -d '"' |tr -d "'" |uniq|\
  xargs -I % bash -c "consume %"`

#   folder=`echo $1|cut -d"/" -f2`
#   file=`echo $1|cut -d"/" -f3`
#   mkdir -p packages/$folder

cat > $1/spec <<EOA
---
name: $jobname

templates:
$templates

packages:
$packages

provides:
$consumes

consumes:
$consumes

properties:
$props
EOA

file=`basename $1`
map=`echo $file|sed "s/\.erb$//"`
processes=`find jobs/${jobname}/templates -depth 1|xargs grep "start)"|cut -d":" -f1|xargs -I % bash -c "process_def ${jobname} %"`

cat > $1/monit <<EOB
$processes
EOB
}


export -f init_job
export -f map_template
export -f prop
export -f consume
export -f process_def

cd $RELEASE_FOLDER
#sed -n 's/.*<%= *p(\(.*\)) *%>.*/\1/p' redis.conf.erb|tr -d '"' |tr -d "'"
#cat pp|sed 's/</\n</g'
find jobs -depth 1 -type d -exec bash -c "init_job {}" \;
cd -

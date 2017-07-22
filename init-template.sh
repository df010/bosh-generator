#!/bin/bash -x

#init-template.sh RELEASE_FOLDER
#init-template.sh RELEASE_FOLDER odb #service tile with On Demand service Broker

RELEASE_FOLDER=`cd $1;pwd`
DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
ODB=$2

rel_name (){
  release_name=`grep final_name config/final.yml|cut -d":" -f2|sed "s/ *//g"`
  [[ "$release_name" == "" ]] && release_name=`grep "^name" config/final.yml|cut -d":" -f2|sed "s/ *//g"`
  echo $release_name
}

job_type () {
  job_name=$1
  props=`cat jobs/$job_name/spec|awk 'x==1 {print $0} /properties:/ {x=1}'|\
  grep "^  [a-zA-Z0-9]"|sed "s/ *//g"|sed "s/://g"|sort|\
  awk -F "\." 'prev==$1 {print "      "$2": 1"}; prev!=$1 {print "    "$1":";print "      "$2": 1"}; {prev=$1} '`
echo -e "- name: $job_name\n\
  templates:\n\
  - $job_name\n\
  manifest:
$props\n"
}

jobs-n (){
  ls -1 jobs|xargs -I % echo - %
}
jobs-instances () {
  echo ""
  ls -1 jobs|xargs -I % bash -c 'echo -e "        - name: %\n          instances: 1"'
}
odb () {
  release_name=`rel_name`
  if [[ "$ODB" == odb ]]
  then
    echo -e "ondemand_job_types:\n\
- name: register-broker
  manifest:
    broker_name: $release_name
- name: deregister-broker
  manifest:
    broker_name: $release_name
- name: broker\n\
  multiple_network: false\n\
  input_mappings:\n\
  binding_credentials:\n\
  - name: ip\n\
    datatype: array\n\
    value: job[*].ip\n\
  manifest:\n\
    service_deployment:\n\
      releases:\n\
      - name: $release_name\n\
        version: latest\n\
        jobs:\n\
        `jobs-n`\n\
    service_catalog:\n\
      id: `uuidgen`\n\
      service_name: $release_name\n\
      service_description: $release_name\n\
      plans:\n\
      - name: standard\n\
        plan_id: `uuidgen`\n\
        description: $release_name\n\
        instance_groups:\n\
        `jobs-instances`"
  fi

}

init_template () {
release_name=`rel_name`
export -f job_type
export -f rel_name
mkdir -p manifests
job_types=`ls -1 jobs|xargs -I % bash -c "job_type %"`
cat > manifests/template.yml <<EOA
---
job_types:
$job_types
`odb`
name: $release_name
description: $release_name
product_version: 1.0.1
stemcell_version: '3363.20'
icon_image: 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
EOA
sed -i "/^[ ]*$/d" manifests/template.yml
}

cd $RELEASE_FOLDER
export -f job
export -f rel_name
export -f jobs-n
export -f jobs-instances
init_template
cd -

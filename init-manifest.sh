#!/bin/bash -x

#init-manifest.sh RELEASE_FOLDER

RELEASE_FOLDER=`cd $1;pwd`
DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

rel_name (){
  release_name=`grep final_name config/final.yml|cut -d":" -f2|sed "s/ *//g"`
  [[ "$release_name" == "" ]] && release_name=`grep "^name" config/final.yml|cut -d":" -f2|sed "s/ *//g"`
  echo $release_name
}

init_cloud_config () {
release_name=`rel_name`
mkdir -p manifests
cat > manifests/bosh_lite_cloud_config.yml <<EOA
vm_types:
- name: medium
  cloud_properties:
    ram: 128
disk_types:
- name: ten
  disk_size: 3000
  cloud_properties: {}

networks:
- name: ${release_name}-network
  subnets:
  - cloud_properties:
      name: random
    range: 10.244.11.0/24
    reserved:
    - 10.244.11.1

compilation:
  cloud_properties:
    name: random
  network: ${release_name}-network
  reuse_compilation_vms: true
  workers: 1
EOA
}

job () {
  job_name=$1
  release_name=`rel_name`
  props=`cat jobs/$job_name/spec|awk 'x==1 {print $0} /properties:/ {x=1}'|\
  grep "^  [a-zA-Z0-9]"|sed "s/ *//g"|sed "s/://g"|sort|\
  awk -F "\." 'prev==$1 {print "      "$2": 1"}; prev!=$1 {print "    "$1":";print "      "$2": 1"}; {prev=$1} '`
echo -e "- name: $job_name\n\
  instances: 1\n\
  templates:\n\
  - name: $job_name\n\
    release: *release_name\n\
  properties:
$props
  vm_type: medium\n\
  persistent_disk_type: ten\n\
  stemcell: trusty\n\
  networks:\n\
  - name: &network_name ${release_name}-network\n"
}

init_deployment () {
release_name=`rel_name`
export -f job
export -f rel_name
mkdir -p manifests
jobs=`ls -1 jobs|xargs -I % bash -c "job % $release_name"`
cat > manifests/bosh_lite_manifest.yml <<EOA
name: ${release_name}-deployment
releases:
  - name: &release_name ${release_name}
    version: latest

stemcells:
- alias: trusty
  os: ubuntu-trusty
  version: latest

jobs:
$jobs

update:
  canaries: 1
  max_in_flight: 10
  canary_watch_time: 1000-30000
  update_watch_time: 1000-30000
EOA
}

cd $RELEASE_FOLDER
export -f job
export -f rel_name
init_cloud_config
init_deployment
cd -

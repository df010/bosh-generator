#!/bin/bash -x
combine () {
    jobstart=$(( 1 + `grep -n "^job_types" $1|cut -d":" -f1` ))

    formstart=$(( 1 + `grep -n "^form_types" $1|cut -d":" -f1` ))
    jobend=$((formstart - 2))
    
    sed -n "$jobstart,${jobend}p" $1>$TMP_DIR/jobs.yml
    sed -n "$formstart,\$p" $1>$TMP_DIR/forms.yml


    jobstart=$((`grep -n "^job_types" $2|cut -d":" -f1`))
    sed -i -e  "${jobstart}r $TMP_DIR/jobs.yml" $2
    
    formstart=$((`grep -n "^form_types" $2|cut -d":" -f1`))
    sed -i -e  "${formstart}r $TMP_DIR/forms.yml" $2
}

release_file() {
  RELEASE_NAME=`cat config/final.yml|grep name:|cut -d" " -f2`
  DEV_RELEASE=`ls -1  dev_releases/$RELEASE_NAME/*.tgz|sort -V -r|head -1`
  FINAL_RELEASE=`ls -1  releases/$RELEASE_NAME/*.tgz|sort -V -r|head -1`
  RELEASE=$DEV_RELEASE;

#  echo "final release is:: "+$FINAL_RELEASE
#  echo "dev release is:: "+$DEV_RELEASE

  [[ "$FINAL_RELEASE" != "" ]] && if [[ "$RELEASE" == "" ]]; then
     RELEASE=$FINAL_RELEASE;
  elif [ $FINAL_RELEASE -nt $DEV_RELEASE ]; then
     RELEASE=$FINAL_RELEASE;
  fi
  echo $RELEASE
}

REL_FOLDER=$1
VERSION=$2
REL_FOLDER=`cd $REL_FOLDER;pwd`
DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
export TMP_DIR=$(mktemp -d)
cd $REL_FOLDER

PRODUCT_NAME=`grep "^name:" manifests/template.yml|cut -d" " -f2`
if [[ -z $VERSION ]]; then
  num=`sed -n 's/product_version: [0-9]\+\.[0-9]\+\.\(.*\)/\1/p' manifests/template.yml`
  num=$((num+1))
  sed  -i "s/\(product_version: [0-9]\+\.[0-9]\+\.\).*/\1$num/" manifests/template.yml
  echo "updated num is "$num
else
  sed -i "s/\(product_version: \).*/\1$VERSION/" manifests/template.yml
  echo "updated version is "$VERSION
fi
PRODUCT_VERSION=`grep "^product_version:" manifests/template.yml|cut -d" " -f2`
echo "provddd "$PRODUCT_VERSION
mkdir -p build
rm -rf build/*
mkdir -p build/metadata
cp $DIR/templates/base.yml.erb $TMP_DIR/template.yml.erb
grep -q "^ondemand_job_types" $REL_FOLDER/manifests/template.yml;
ONDEMAND=$?
[[ ! -z $ONDEMAND ]] &&  combine $DIR/templates/ondemand.yml.erb $TMP_DIR/template.yml.erb
#cat $TMP_DIR/template.yml.erb
export LOAD_PATH=$DIR
[[ ! -z $ONDEMAND ]] && $DIR/lib/gen_metadata.rb $TMP_DIR/template.yml.erb $REL_FOLDER/`release_file` config > $TMP_DIR/config.yml.erb
#cat $TMP_DIR/config.yml.erb

[[ ! -z $ONDEMAND ]] && { cmp --silent $TMP_DIR/config.yml.erb  $REL_FOLDER/jobs/ondemand/templates/config.yml.erb || { \
  cp -r $DIR/template-release/jobs/ondemand $REL_FOLDER/jobs; \
  cp $TMP_DIR/config.yml.erb $REL_FOLDER/jobs/ondemand/templates/; \
  bosh create-release --tarball; \
} }
#cat $TMP_DIR/template.yml.erb
$DIR/lib/gen_metadata.rb $TMP_DIR/template.yml.erb $REL_FOLDER/`release_file` |sed -e "/^ *$/d" > build/metadata/metadata.yml

mkdir -p build/releases
rm -rf build/releases/*

[[ ! -z $ONDEMAND ]] && cp $DIR/releases/** build/releases/


ls -1  build/releases|while read rel;do \
rel2=`echo $rel|sed "s/\([a-zA-Z0-9]\)-\([0-9]\+\)/\1 \2/1"`; \
echo "- name: "`echo $rel2|cut -d" " -f1`; \
echo "  file: "`echo $rel`; \
echo "  version: "`basename $(echo $rel2|cut -d" " -f2) .tgz`; \
done > $TMP_DIR/releases.yml
cat $TMP_DIR/releases.yml
release_start=`grep -n "^releases:" build/metadata/metadata.yml|cut -d":" -f1`

sed -i -e  "${release_start}r $TMP_DIR/releases.yml" build/metadata/metadata.yml

cp `release_file` build/releases/


mkdir -p build/migrations/v1
cp migrations/v1/* build/migrations/v1/

cd build
zip -r ${PRODUCT_NAME}.${PRODUCT_VERSION}.pivotal *
cd -
    
#rm -rf $TMP_DIR

#!/bin/bash
REL_FILE=$1
TARGET=$2
TARGET=`cd ${TARGET:-"."}; pwd`
echo $TARGET
tar -xf $REL_FILE -C $TARGET
mkdir -p $TARGET/src
pushd $TARGET/packages
ls *.tgz -1|xargs -I % bash -c '
    FOLDER=`echo %|cut -d. -f 1`;\
    mkdir -p ../src/$FOLDER; 
    mkdir -p $FOLDER; 
    tar -xf % -C ../src/$FOLDER;\
    mv ../src/$FOLDER/packaging $FOLDER;\
    ' 
rm *.tgz
popd

START_LINE=$(( `grep -n "^packages:" release.MF|cut -d: -f 1` + 1 ))
END_LINE=`grep -n "^jobs:" release.MF|cut -d: -f 1`
sed -n "$START_LINE,${END_LINE}p" $TARGET/release.MF|grep -v "^  version:\|^  fingerprint:\|^  sha1:"|{ while IFS='' read -r line || [[ -n "$line" ]]; do \
    [[ "name:" == `echo "$line"|tr -s ' '|cut -d' ' -f 2` ]] && { \
        [[ "$PKG_NAME" == "" ]] || echo -e "files:\n- $PKG_NAME/**/*" >> $TARGET/packages/$PKG_NAME/spec; \
        PKG_NAME=`echo "$line"|tr -s ' '|cut -d' ' -f 3`; \
        echo "---" > $TARGET/packages/$PKG_NAME/spec; \
    }; \
    echo "${line:2}" >> $TARGET/packages/$PKG_NAME/spec; \
done }
[[ "$PKG_NAME" == "" ]] || echo -e "files:\n- $PKG_NAME\/\*\*\/\*" >> $TARGET/packages/$PKG_NAME/spec;

pushd $TARGET/jobs
ls *.tgz -1|xargs -I % bash -c '
    FOLDER=`echo %|cut -d. -f 1`;\
    mkdir -p $FOLDER; 
    tar -xf % -C $FOLDER;
    mv $FOLDER/job.MF $FOLDER/spec
    '
rm *.tgz
popd

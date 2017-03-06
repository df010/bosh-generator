#!/bin/bash -x
REL_FOLDER=`cd $1;pwd`
DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
cd $DIR/template-release
find -type f|xargs -I % rm $REL_FOLDER/%
cd -

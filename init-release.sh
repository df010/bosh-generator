#!/bin/bash -x

#init-release REL_FOLDER Empty redis
REL_FOLDER=`cd $1;pwd`
DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

OPTION=$2
PS3='Please enter your choice: '
options=("Empty" "Legacy Broker" "On Demand Broker")
[[ "$OPTION" == "" ]] && select opt in "${options[@]}"
do
    case $opt in
        "Empty")
            OPTION=1;
            break;
            ;;
        "Legacy Broker")
            OPTION=2;
            break;
            ;;
        "On Demand Broker")
            OPTION=3;
            ;;
        *) echo invalid option; exit 1;;
    esac
done

case $OPTION in
    1)  cp -r $DIR/template-release/config $REL_FOLDER;;
    2)  cp -r $DIR/template-release/* $REL_FOLDER;;
    3)  exit 0;;
    *)  exit 1;;
esac
RELEASE_NAME=$3
[[ "$RELEASE_NAME" == "" ]] && RELEASE_NAME=`basename $REL_FOLDER`
[[ "$RELEASE_NAME" == *-release ]] && RELEASE_NAME=${RELEASE_NAME::-8}

sed -i "s/name: NAME/name: $RELEASE_NAME/g" $REL_FOLDER/config/final.yml

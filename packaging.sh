#!/bin/bash  -x
echo `whoami`
echo $PATH


cd /var/vcap/build 
PKG_IN_ORDER=`echo $1 | tr "," " "`
if [ -z "$PKG_IN_ORDER" ];then 
   PKG_IN_ORDER=`ls -1  packages/|xargs echo`
fi

cd /var/vcap/build/src
echo "pkg in order: "$PKG_IN_ORDER
for pkg in $PKG_IN_ORDER; do
  cd $pkg
  export BOSH_INSTALL_TARGET=/var/vcap/packages/$pkg
  mkdir -p $BOSH_INSTALL_TARGET 
  bash /var/vcap/build/packages/$pkg/packaging
  cd ..
done

cp  -R /var/vcap/build/* /var/vcap/




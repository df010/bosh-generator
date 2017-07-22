#!/bin/bash -x

#init-package.sh RELEASE_FOLDER

RELEASE_FOLDER=`cd $1;pwd`
DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

# cddk_packaging () {
# }
# #
# # mk_packaging () {
# #
# # }

init_pkg () {
  folder=`echo $1|cut -d"/" -f2`
  file=`echo $1|cut -d"/" -f3`
  mkdir -p packages/$folder
cat > packages/$folder/spec <<EOA
---
name: ${folder}
dependencies: []
files:
- ${folder}/**/*
EOA
echo $file
 # || "$file" == "*.tgz"
if [[ "$file" == *.tar.gz  ]]
then
  to_folder=${file::-7}
elif [[ "$file" == *.tgz ]]
then
  to_folder=${file::-4}
fi

if [[ "$file" == *.tar.gz || "$file" == *.tgz ]]
then
  cat >> packages/$folder/packaging <<EOB
set -e
tar -xvf $folder/$file
(
  set -e
  cd $to_folder
  ./configure --prefix=\${BOSH_INSTALL_TARGET}
  make
  make install
)
EOB
else
  cat >> packages/$folder/packaging <<EOC
set -e
cp -a $folder/$file \${BOSH_INSTALL_TARGET}
EOC
fi

}

export -f init_pkg
rm -rf packages/*
find src -type f ! -name '.*'|xargs -I % bash -c "init_pkg %"

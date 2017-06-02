#!/usr/local/bin/bash -ex
bosh2 create-release --force $1  --tarball a.tgz
#tar -xOf a.tgz release.MF |sed -n -e "s/^version: //p" -e "s/^name: //p"|xargs|read name version
read name version <<< `tar -xOf a.tgz release.MF |sed -n -e "s/^version: //p" -e "s/^name: //p"|xargs`
echo $name
echo $version

[[ "$name" ==  ""  || "$version" ==  "" ]] && exit 3
RELEASE=releases
[[ "$1" == "" ]] && RELEASE=dev_releases;
mv a.tgz $RELEASE/$name/$name-$version.tgz

#!/bin/bash

usage () {
  echo "Usage: transform.sh xslt-file tei-directory"
  echo "Example: transform.sh p4top5.xsl ./tei"
  echo
  exit 1
}

if [ ! -f "$1" ]; then
  usage
fi

if [ ! -d "$2" ]; then
  usage
fi

xsl=$1
dir=$2

for f in $dir/*.xml; do
  echo $f
  cp $f tmp.xml
  saxon tmp.xml $xsl | xmllint --format --noent --encode UTF-8 - > $f
  rm tmp.xml
done

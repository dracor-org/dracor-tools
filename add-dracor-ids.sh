#!/bin/bash

usage () {
  echo "Usage: add-ids.sh prefix directory"
  echo "Example: add-ids.sh foo ./tei"
  exit 1
}

if [ -z "$1" ]; then
  usage
fi

if [ ! -d "$2" ]; then
  usage
fi

prefix=$1
dir=$2

n=0;

for f in $dir/*.xml; do
  n=$(($n + 1));
  printf -v j "%06d" $n;
  echo $j $f;
  perl -pi -e "s|</publicationStmt>|  <idno type=\"dracor\" xml:base=\"https://dracor.org/id/\">$prefix$j</idno></publicationStmt>|" $f;
done

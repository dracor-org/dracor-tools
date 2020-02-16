#!/bin/bash

for f in tei/*.xml; do
  echo $f
  cp $f tmp.xml
  xsltproc p4top5.xsl tmp.xml | xmllint --format --noent --encode UTF-8 - > $f
  rm tmp.xml
done

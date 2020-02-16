#!/bin/bash

for f in tei/*.xml; do
  echo $f
  cp $f tmp.xml
  xmllint --format --noent --encode UTF-8 tmp.xml > $f
  rm tmp.xml
done

# fix dangling end tags, e.g.
#
# <div>
#   <p>Lorem ipsum...
# </p>
# </div>
#
# becomes
#
# <div>
#   <p>Lorem ipsum...</p>
# </div>

#perl -0700 -pi -e 's|([^>\s])\s*\n</([a-zA-Z]+)>\n|$1</$2>\n|g' tei/*.xml

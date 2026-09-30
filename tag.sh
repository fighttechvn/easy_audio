#!/bin/bash

VERSION_NAME=1.0.0
VERSION_CODE=1
# yyyyy/MM/dd:HH
# DATE=25093020
DATE=$(date +"%Y%m%d%H")

TAG_NAME="prod_${VERSION_NAME}_${DATE}_${VERSION_CODE}"

echo "Creating tag: $TAG_NAME"

git tag $TAG_NAME
git push origin $TAG_NAME

# flutter build apk --build-name=1.0.3 --build-number=581

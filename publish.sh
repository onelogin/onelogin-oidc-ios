#!/bin/bash

DESTDIR=~/TestXCFrameworkBuild

removeDirectory()
{
    if [ -d "$1" ]; then
        rm -rf "$1"
    fi
}

cleanup()
{
    removeDirectory "${DESTDIR}/OLOidc-iphonesimulator.xcarchive"
    removeDirectory "${DESTDIR}/OLOidc-iphoneos.xcarchive"
}

if [ ! -d "${DESTDIR}" ] ; then
    mkdir "${DESTDIR}"
else
    cleanup
    removeDirectory "${DESTDIR}/OLOidc.xcframework"
fi

xcodebuild archive \
 -scheme OLOidc \
 -archivePath "${DESTDIR}/OLOidc-iphoneos.xcarchive" \
 -sdk iphoneos \
 SKIP_INSTALL=NO

xcodebuild archive \
 -scheme OLOidc \
 -archivePath "${DESTDIR}/OLOidc-iphonesimulator.xcarchive" \
 -sdk iphonesimulator \
 SKIP_INSTALL=NO

xcodebuild -create-xcframework \
 -framework "${DESTDIR}/OLOidc-iphonesimulator.xcarchive/Products/Library/Frameworks/OLOidc.framework" \
 -framework "${DESTDIR}/OLOidc-iphoneos.xcarchive/Products/Library/Frameworks/OLOidc.framework" \
 -output "${DESTDIR}/OLOidc.xcframework"


cd "${DESTDIR}/OLOidc.xcframework"

# https://developer.apple.com/forums/thread/123253
find . -name "*.swiftinterface" -exec sed -i -e 's/OLOidc\.//g' {} \;

cleanup

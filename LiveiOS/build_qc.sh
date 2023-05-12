#!/bin/bash
set -ex

# This scripts allows you to upload a binary to the iTunes Connect Store and do it for a specific app_id
# Because when you have multiple apps in status for download, xcodebuild upload will complain that multiple apps are in wait status

# Requires application loader to be installed
# See https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SubmittingTheApp.html
# Itunes Connect username & password
USER=hai.nguyenv@s3corp.com.vn
PASS=Nh260486
TEAMID=ZR6QDY93JK #LinhLe

# App id as in itunes store create, not in your developer account
APP_ID='1303458876' #BUUP

# SCHEME TARGET
SCHEME=SanTube
WORKSPACE=“SanTube”


IPA_FILE=builds/$SCHEME.ipa

BUILDSDIR=builds
# Remove previous builds
test -d ${BUILDSDIR} && rm -rf ${BUILDSDIR}
mkdir ${BUILDSDIR}
cat <<EOM > builds/exportPlist.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>teamID</key>
        <string>$TEAMID</string>
        <key>method</key>
        <string>app-store</string>
        <key>uploadBitcode</key>
        <true/>
</dict>
</plist>
EOM

if [ "$WORKSPACE" == "" ]
then
	echo "Build CodeProj"
	xcodebuild -scheme $SCHEME -archivePath builds/$SCHEME.xcarchive archive
else
	echo "Build WorkSpace"
	xcodebuild -workspace "SanTube.xcworkspace" -scheme $SCHEME -archivePath builds/$SCHEME.xcarchive archive
fi

xcrun xcodebuild -exportArchive -exportOptionsPlist builds/exportPlist.plist -archivePath builds/$SCHEME.xcarchive -exportPath builds

# Start upload IPA file to iTunes
IPA_FILENAME=$(basename $IPA_FILE)
MD5=$(md5 -q $IPA_FILE)
BYTESIZE=$(stat -f "%z" $IPA_FILE)

TEMPDIR=builds/itsmp
# Remove previous temp
test -d ${TEMPDIR} && rm -rf ${TEMPDIR}
mkdir ${TEMPDIR}
mkdir ${TEMPDIR}/mybundle.itmsp

# You can see this debug info when you manually do an app upload with the Application Loader
# It's when you click activity

cat <<EOM > ${TEMPDIR}/mybundle.itmsp/metadata.xml
<?xml version="1.0" encoding="UTF-8"?>
<package version="software4.7" xmlns="http://apple.com/itunes/importer">
    <software_assets apple_id="$APP_ID">
        <asset type="bundle">
            <data_file>
                <file_name>$IPA_FILENAME</file_name>
                <checksum type="md5">$MD5</checksum>
                <size>$BYTESIZE</size>
            </data_file>
        </asset>
    </software_assets>
</package>
EOM

cp ${IPA_FILE} $TEMPDIR/mybundle.itmsp

/Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/itms/bin/iTMSTransporter -m upload -f ${TEMPDIR} -u "$USER" -p "$PASS" -v detailed

test -d ${BUILDSDIR} && rm -rf ${BUILDSDIR}
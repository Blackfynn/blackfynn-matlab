#!/bin/bash

BUILD_DIR="build"
[ -d $BUILD_DIR ] || mkdir ${BUILD_DIR}

echo "Copying jars..."
javac -cp ../java/protobuf-java-3.5.1.jar ../java/*.java -d . -source 1.8 -target 1.8
jar cf blackfynio.jar blackfynn/*.class

# Get build version of toolbox
tag=$(git describe --tags); echo "$tag">version.txt

echo -e "Running matlab build..."
matlab -nodisplay -nodesktop -r "run ./createToolbox.m"
#/Applications/MATLAB_R2017b.app/bin/matlab -nodisplay -nodesktop -r "run ./createToolbox.m"


[ -f build/blackfynn.mltbx ] || { echo "ERROR: build failed /build/blackfynn.mltbx doesn't exist." && exit 1; }

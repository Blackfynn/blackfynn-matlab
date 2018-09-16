#!/bin/bash

rm -rf ../build || true

echo "Copying jars..."
javac -cp ../java/protobuf-java-3.5.1.jar ../java/*.java -d . -source 1.8 -target 1.8
jar cf blackfynio.jar blackfynn/*.class

echo -e "Running matlab build..."
matlab -nodisplay -nodesktop -r "run ./createToolbox.m"

[ -f build/blackfynn.mltbx ] || { echo "ERROR: build failed ../build/blackfynn.mltbx doesn't exist." && exit 1; }

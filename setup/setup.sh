#!/bin/bash

BUILD_DIR="build"

javac -cp ../java/protobuf-java-3.5.1.jar ../java/*.java -d . -source 1.8 -target 1.8
jar cf blackfynio.jar blackfynn/*.class

[ -d ${BUILD_DIR} ] || mkdir ${BUILD_DIR}

matlab -nodisplay -nodesktop -r "run ./createToolbox.m"

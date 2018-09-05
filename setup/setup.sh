#!/bin/bash
javac -cp ../java/protobuf-java-3.5.1.jar ../java/*.java -d . -source 1.8 -target 1.8
jar cf blackfynio.jar blackfynn/*.class
/Applications/MATLAB_R2017b.app/bin/matlab -nodisplay -nodesktop -r "run ./createToolbox.m"

#javac -cp ../java/protobuf-java-3.5.1.jar ../java/*.java -d ../build -source 1.8 -target 1.8
#jar cf ../java/blackfynio.jar ../build/blackfynn/*.class

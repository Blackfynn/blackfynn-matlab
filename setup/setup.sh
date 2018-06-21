#!/bin/bash
javac -cp ../java/protobuf-java-3.5.1.jar ../java/*.java -d ../build -source 1.8 -target 1.8
jar cf ../java/blackfynio.jar ../build/blackfynn/*.class
/Applications/MATLAB_R2017b.app/bin/matlab -nodisplay -nodesktop -r "run ./createToolbox.m"
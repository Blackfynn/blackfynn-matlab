% This script creates the toolbox from the project file
projectFile = 'blackfynn.xml';
outputFile = 'build/blackfynn';

matlab.addons.toolbox.packageToolbox(projectFile,outputFile)

quit()

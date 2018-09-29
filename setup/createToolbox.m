% This script creates the toolbox from the project file
projectFile = 'blackfynn2.prj';
outputFile = 'build/blackfynn';

addpath('../');
newVersion = Blackfynn.toolboxVersion();
matlab.addons.toolbox.toolboxVersion(projectFile, newVersion);
matlab.addons.toolbox.packageToolbox(projectFile, outputFile)
quit()

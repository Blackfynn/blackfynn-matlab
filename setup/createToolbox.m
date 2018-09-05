% This script creates the toolbox from the project file
projectFile = '../build/blackfynnio.prj';
outputFile = '../build/blackfynn';
matlab.addons.toolbox.packageToolbox(projectFile,outputFile)
quit()
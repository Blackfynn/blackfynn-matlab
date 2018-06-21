% This script creates the toolbox from the project file
projectFile = 'blackfynnio.prj';
outputFile = 'blackfynn';
matlab.addons.toolbox.packageToolbox(projectFile,outputFile)
quit()
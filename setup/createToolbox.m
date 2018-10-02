% This script creates the toolbox from the project file
projectFile = 'blackfynn.prj';
outputFile = 'build/blackfynn';

% Get version from Github tag (saved in version.txt)
h = fopen('build/matlab_version.txt');
newVersion = fscanf(h,'%s');
[a,b]=regexp(newVersion,'(\d+\.)+\d');
newVersion = newVersion(a:b);
if isempty(newVersion)
    newVersion = '1.0';
end

if newVersion(1) == '0'
    newVersion(1) = '1';
end

% Set version and build toolbox
matlab.addons.toolbox.toolboxVersion(projectFile, newVersion);
matlab.addons.toolbox.packageToolbox(projectFile, outputFile)
quit()

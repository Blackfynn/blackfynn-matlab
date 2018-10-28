% This script creates the toolbox from the project file
projectFile = 'blackfynn.prj';
outputFile = 'build/blackfynn';

% % Run tests
% setupFolder = pwd;
% cd ../tests
% out = runtests();
% if ~all([out.Passed])
%     quit()
% end
% cd(setupFolder);

% Get version from Github tag (saved in version.txt)
h = fopen('build/matlab_version.txt');
newVersion = fscanf(h,'%s');
fprintf(2,'MATLAB building from: %s\n',newVersion);
[a,b]=regexp(newVersion,'(\d+\.)+\d');
newVersion = newVersion(a:b);
if isempty(newVersion)
    newVersion = '1.0';
end

% Make sure that version is > 1, per Matlab convention.
if newVersion(1) == '0'
    newVersion(1) = '1';
end

% Set version and build toolbox
matlab.addons.toolbox.toolboxVersion(projectFile, newVersion);
matlab.addons.toolbox.packageToolbox(projectFile, outputFile)
quit()

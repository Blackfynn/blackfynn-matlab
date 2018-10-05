# blackfynn-matlab

This repository contains the source code for the Blackfynn MATLAB client.

[![Build Status](https://travis-ci.org/Blackfynn/blackfynn-matlab.svg?branch=master)](https://travis-ci.org/Blackfynn/blackfynn-matlab)

## Installation

The Blackfynn MATLAB client can be installed using two methods:

1. Using the MATLAB Toolbox installer (recommended)
2. Directly from the source code (must be able to compile Java files from the command line)

## Downloading and installing toolbox (recommended)
In order to install the latest release of the MATLAB client，follow the instructions on the Matlab quickstart quide: [MATLAB installation guide](http://help.blackfynn.com/developer-tools/matlab/installing-the-matlab-client). This method automatically handles the Java dependencies and adds the client to the MATLAB path. 

## Installing toolbox from source code

1. Download, or checkout the source code from the source code repository [MATLAB client repository](https://github.com/Blackfynn/blackfynn-matlab)
2. (Only for download) Extract contents of the downloaded file into a folder
3. Modify the [MATLAB_LOC] variable in the setup.sh script to point to your local MATLAB executable.
4. Run the setup script:

```shell
>> cd setup
>> ./setup.sh
```

5. Open the resulting toolbox installer to install the local toolbox. 

### Using toolbox directly from source code 

Instead of installing the toolbox in MATLAB, you can also just point your MATLAB path to the root of the toolbox folder. This can be useful if you are actively developing functionality for the toolbox. You will have to run the setup script to compile the JAVA files, but you can skip step 5 and instead:

5. Add the compiled JAVA libraries to your MATLAB static Java classpath:

```matlab
>> cd(prefdir)
>> edit javaclasspath.txt
```

then add this lines (update path) and restart MATLAB:
```matlab
/.../blackfynn-matlab/java/blackfynio.jar
/.../blackfynn-matlab/java/matlab-websocket-1.4.jar
/.../blackfynn-matlab/java/protobuf-java-3.5.1.jar
```

5. Add the path of the Blackfynn client folder to the MATLAB path or work from the toolbox folder. This can be done in MATLAB as follows:

```matlab
>> addpath('/Users/preferred-path/blackfynn-matlab');
```

**NOTE:** For detailed information about changing the MATLAB java classpath, refer to the [MATLAB Documentation](https://www.mathworks.com/help/matlab/ref/javaclasspath.html).

## Documentation

For more details about the client, please refer to the [documentation pages](http://help.blackfynn.com/developer-tools#matlab).

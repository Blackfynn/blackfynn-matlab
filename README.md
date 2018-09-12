# blackfynn-matlab

This repository contains the source code for the Blackfynn MATLAB client.

[![Build Status](https://travis-ci.org/Blackfynn/blackfynn-matlab.svg?branch=master)](https://travis-ci.org/Blackfynn/blackfynn-matlab)

## Installation

The Blackfynn MATLAB client can be installed using two methods:

1. Using the MATLAB Toolbox installer (recommended)
2. Directly from the source code (must be able to compile Java files from the command line)

## Installing the Blackfynn Toolbox (recommended)
In order to install the latest release of the MATLAB client，follow the instructions on the Matlab quickstart quide: [MATLAB installation guide](http://docs.blackfynn.io/clients/matlab/quickstart.html#installation). This method automatically handles the Java dependencies and adds the client to the MATLAB path. 

## Installing the client from source code

### Downloading and adding to MATLAB path

1. Download, or checkout the source code from the source code repository [MATLAB client repository](https://github.com/Blackfynn/blackfynn-matlab)
2. (Only for download) Extract contents of the downloaded file into a folder
3. Add the path of the Blackfynn client folder to the MATLAB path. This can be done in MATLAB as follows:

```shell
>> addpath('/Users/preferred-path/blackfynn-matlab');
```

### Compiling supporting Java libraries

The MATLAB client relies on Java libraries and requires Java version 1.7 or higher. In order to complete the installation, the Java code must be compiled and added to the MATLAB Java path. Follow these steps:

1. Find out what Java version MATLAB is using:

```shell
>> version -java
```

2. From the system's command line, change directory to the location of the Java code:

```shell
cd /Users/preferred-path/blackfynn-matlab/java
```

3. Compile the Java code targeting the specific Java version:

```shell
javac *.java -d build/ -target [JAVA-VERSION-GOES-HERE]
```

For instance, if the Java version for MATLAB is 1.8, you can compile the code like this:

```shell
javac *.java -d build/ -target 1.8
``` 

4. Add the compiled code to your MATLAB dynamic Java path:

```shell
>> javaaddpath('/Users/preferred-path/blackfynn-matlab/java/build');
```

**NOTE:** These instructions add the Java libraries to MATLAB's dynamic Java path. You will have to add this path every time you start a new MATLAB session or recompile the Java code. You can also add the code to the static path if you do not want to add the Java path for each new MATLAB session. To add the code to the static path, refer to the [MATLAB Documentation](https://www.mathworks.com/help/matlab/ref/javaclasspath.html).

## Documentation

For more details about the client, please refer to the [documentation pages](http://docs.blackfynn.io/clients/matlab/index.html).

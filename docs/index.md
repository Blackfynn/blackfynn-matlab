---
title: "Getting started with the MATLAB Toolbox"
keywords: MATLAB Blackfynn
tags: [getting_started,installation,setup]
sidebar: matlab_docs_sidebar
permalink: index.html
summary: The MATLAB toolbox for Blackfynn allows users to programmatically interact with the Blackfynn platform from MATLAB. This page describes how to install the toolbox and how to configure it to connect to an account on the Blackfynn platform.
---

The MATLAB toolbox for Blackfynn allows users to programmatically interact with the Blackfynn platform from MATLAB.


## Installing the MATLAB Client

There are two ways to install the MATLAB toolbox. The preferred method is to download the precompiled toolbox and use the installer to make the toolbox available in MATLAB. Alternatively, you can install directly from the sourcecode of the toolbox after downloading or cloning the MATLAB toolbox repository. Use this if you plan to develop new features for the toolbox. 

### A. Installing precompiled toolbox (preferred)

The preferred method of installing the MATLAB toolbox is by downloading the latest precompiled version of the client. In order to install the client, please follow these simple steps.

#### 1. Install the Blackfynn Agent
* The Blackfynn MATLAB Toolbox is dependent on the Blackfynn Agent which is installed separately. The Agent provides the functionality to upload data and facilitates performent streaming of data from the the Blackfynn servers to local clients. Please follow the instructions to [install the Blackfynn Agent](/developer-tools/blackfynn-agent/installing-the-blackfynn-cli-and-agent).  

#### 2. Install the MATLAB Toolbox
* [Download the latest version of the MATLAB toolbox](http://data.blackfynn.io/public-downloads/blackfynn-matlab/latest/blackfynn.mltbx)
* Open the downloaded mltbx file and click install (you must have MATLAB already installed for the automatic installation to take place)

{% include image.html file="installtoolbox.png" alt="InstallScreen" caption="Screenshot of toolbox installation screen" max-width=400%}


### B. Installing from source code

#### a. Compile MATLAB Toolbox locally
* Download, or checkout the source code from the source code repository [MATLAB client repository](https://github.com/Blackfynn/blackfynn-matlab)
* (Only for download) Extract contents of the downloaded file into a folder
* Modify the [MATLAB_LOC] variable in the setup.sh script to point to your local MATLAB executable.
* Run the setup script:

```shell
>> cd setup
>> ./setup.sh
```

* Open the resulting toolbox installer to install the local toolbox. 

#### b. Adding sourcecode location to the MATLAB path 

* Download, or checkout the source code from the source code repository [MATLAB client repository](https://github.com/Blackfynn/blackfynn-matlab)
* (Only for download) Extract contents of the downloaded file into a folder
* Modify the [MATLAB_LOC] variable in the setup.sh script to point to your local MATLAB executable.
* Add the compiled JAVA libraries to your MATLAB static Java classpath:

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
>> addpath('/.../blackfynn-matlab');
```

{% include note.html content="For detailed information about changing the MATLAB java classpath, refer to the [MATLAB Documentation](https://www.mathworks.com/help/matlab/ref/javaclasspath.html)." %}



## Configuring the MATLAB Toolbox

In order to access your data programmatically, you'll have to create an API Token and secret using in the platform. You can find instructions on how to create this [here](http://help.blackfynn.com/developers/overview/creating-an-api-key-for-the-blackfynn-clients). Once you have generated an API token and secret in the platform, you will be able to configure your client and set up a profile from the MATLAB command line by using ```Blackfynn.setup```

``` matlab
>> Blackfynn.setup
Enter a profile name: testName
Provide API key: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx
Provide API secret: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx
Make sure you copy and paste the credentials that you generated from the platform to the API key and secret respectively. Once you have installed the Matlab client, and configured the client for your account, you can start to interact with the data on our platform. 
```

{% include links.html %}

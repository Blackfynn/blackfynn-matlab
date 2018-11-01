---
title: The Basics
keywords: tutorial, beginner, login
last_updated: October 17, 2018
summary: "Tutorial 1: Configuring and getting started with the MATLAB toolbox"
sidebar: matlab_docs_sidebar
permalink: tutorial1.html
folder: matlabDocs
---

## Introduction

Congratulations, you have installed the Blackfynn toolbox. Now, let's configure the toolbox to use your credentials to access your account on the Blackfynn platform and use the MATLAB toolbox to login to your account and navigate one of your datasets.

## Configuring the MATLAB toolbox

In order to access your data programmatically, you'll have to create an API Token and secret using in the platform. You can find instructions on how to create this [here](http://help.blackfynn.com/developers/overview/creating-an-api-key-for-the-blackfynn-clients). Once you have generated an API token and secret in the platform, you will be able to configure your client and set up a profile from the MATLAB command line by using the command ```Blackfynn.setup```.

```text
>> Blackfynn.setup
Enter a profile name: testName
Provide API key: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx
Provide API secret: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx
Make sure you copy and paste the credentials that you generated from the platform to the API key and secret respectively. Once you have installed the Matlab client, and configured the client for your account, you can start to interact with the data on our platform. 
```

This will store your API key and secret in a config.ini file inside your home folder ```~/.blackfynn/config.ini```. You can use this method to store multiple profiles, corresponding to different accounts on the Blackfynn platform (see [Blackfynn/setup](blackfynn_setup.html)). Alternatively, you can manually edit the ```config.ini``` file using a text editor. Details on the format of this file can be found [here](http://help.blackfynn.com/developers/overview/blackfynn-advanced-configuration-settings).

## Creating a session and navigating a dataset

To initialyze a session, create an object of type ```Blackfynn```:

```text
>> bf = Blackfynn()

bf = 

  Blackfynn with properties:

     profile: [1×1 struct]
    datasets: [1×50 BFDataset]
>>
```

This will use your default profile to establish a session on the Blackfynn platform. If you have multiple profiels, you can specify the profile explicitly:

```text
>> bf = Blackfynn('profileName');
```

You can list all your available profiles using

```text
>> bf.profiles
[profile 1]
[otherProfile]

>>
```

The variable **bf** now represents an active session on the Blackfynn platform. You can see that, in this case, my account has access to 50 datasets. The profile provide information on the user that is logged in.

To see the contents of the first dataset, simply access the datasets property

```text
>> ds = bf.datasets(1)

ds = 

  BFDataset with properties:

    description: 'This is an example dataset'
         models: [1×8 BFModel]
          items: [1×11 BFBaseDataNode]
           name: 'My test dataset'
>>
```

We see the contents of the dataset, including the 8 models that were defined for the dataset and the contents of the root folder of the data catalog. 

In addition to accessing existing datasets on the platform, you can also use the MATLAB toolbox to create a new empty dataset. In the **bf** object, you can use the ```createDataset``` method to create a new dataset on the platform.

```text
>> new_ds = bf.createDataset('TestDataset', 'Description for my dataset')

new_ds = 

  BFDataset with properties:

    description: 'Description for my dataset'
         models: [0×0 BFModel]
          items: [0×0 BFBaseDataNode]
           name: 'TestDataset'
>>
```

## Getting help on classes and methods
Each of the classes in the Blackfynn toolbox has a number of methods that you can use to access/manipulate, or create data and metadata on the platform. Use the ```methods``` function to see all methods available for objects of the **BFDataset** class.

```text
>> methods(ds)
BFDataset Methods:
 BFDataset           Constructor of the BFDataset class
 createfolder        creates a new folder within the object
 createModel         Creates a model in the dataset
 gotoSite            Opens the Blackfynn platform in an external browser
 listitems           Returns list of items in the dataset or collection.
 methods             Shows all methods associated with the object
 update              updates dataset on the platform

>>
```

To get information on a specific method, click on the name of the method or type: ```help <class-name>.<method-name>```. 

This concludes this tutorial, you should now be able to access your datasets on the Blackfynn platform, create new datasets on the platform, and discover the methods that are available for each of the Blackfynn models.



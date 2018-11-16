---
title: Uploading Files
keywords: tutorial, beginner, login
last_updated: October 17, 2018
summary: "Tutorial 3: Uploading files to Blackfynn using MATLAB."
sidebar: matlab_docs_sidebar
permalink: tutorial3.html
folder: matlabDocs
---

## Introduction
This tutorial describes how you can use the MATLAB client to upload files to the Blackfynn platform. The MATLAB client leverages the (Blackfynn Agent)[https://developer.blackfynn.io/agent/index.html] to upload the files and provides intuitive helper functions to directly upload files from a MATLAB script or the console. 

This tutorial assumes that the user has installed the Blackfynn MATLAB toolbox and the Blackfynn Agent.

## Uploading files
{% include tip.html content="Download a small set of files that you can use for this tutorial [here](http://data.blackfynn.io/tutorials/example_data.zip)" %}

In order to upload files to the Blackfynn platform, users have to specify the dataset that the files should be uploaded to. First, create a Blackfynn session and navigate to a particular dataset. 


```text
>> bf = Blackfynn();
>> ds = bf.datasets(1)

ds = 

  BFDataset with properties:

    description: 'This is an example dataset'
         models: [1×8 BFModel]
          items: [1×11 BFBaseDataNode]
           name: 'My test dataset'
>>
```

Now that we have a variable representing the dataset ```ds```, we can use the ```upload``` method to upload files to this dataset. 

```text
>> ds.upload('~/Downloads/example_data');

The following 10 files will be uploaded to "N:dataset:xxxxxxxx-xxxx-xxxx-xxxxx-xxx":

[blackfynn] (PDF, 838.97 kB)
    "/Downloads/example_data/blackfynn.pdf" (838.97 kB)

[table2] (Tabular, 49 B)
    "/Downloads/example_data/table2.csv" (49 B)

[T2] (MRI, 2.68 MB)
    "/Downloads/example_data/T2.nii.gz" (2.68 MB)

[testData] (TimeSeries, 2.21 MB)
    "/Downloads/example_data/testData.ns2" (662.63 kB)
    "/Downloads/example_data/testData.nev" (1.55 MB)

[small_region] (Slide, 1.94 MB)
    "/Downloads/example_data/small_region.svs" (1.94 MB)

    ...

Queued 10 files
```

If you want to upload files to a specific folder id the dataset, you can specify a path as an optional argument. If the folder, or nested folders don't exist yet, they will be created automatically.  Let's upload the same data to the 'exp1/trial1' folder. 

```text
>> ds.upload('~/Downloads/example_data', 'folder', 'exp1/trial1');
```


## Advanced options to select specific files

You can use the ```include``` and ```exclude``` optional input arguments to filter the files that should be uploaded to the platform. Both parameters are string that follow glob style pattern expansion. Below, a number of examples are provided for various usecases.


1. Include only files with certain extentions:
```text
>> ds.upload('~/Downloads/example_data', 'include', '*.dcm');
>> ds.upload('~/Downloads/example_data', 'include', '{*.dcm,*.pdf}');
``` 

2. Exclude hidden .DS_Store file in the folder:
```text
>> ds.upload('~/Downloads/example_data', 'exclude', '*.DS_Store');
```



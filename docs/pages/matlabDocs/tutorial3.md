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
This tutorial describes how you can use the MATLAB client to upload files to the Blackfynn platform. The MATLAB client leverages the [Blackfynn Agent](https://developer.blackfynn.io/agent/index.html) to upload the files and provides intuitive helper functions to directly upload files from a MATLAB script or the console. 

This tutorial assumes that the user has installed the Blackfynn MATLAB toolbox, the Blackfynn agent and has completed [tutorial 2](tutorial2.html).

## Uploading files
{% include tip.html content="Download a small set of files that you can use for this tutorial [here](http://data.blackfynn.io/tutorials/example_data_simple.zip)" %}

In order to upload files to the Blackfynn platform, users have to specify the dataset that the files should be uploaded to. We will be uploading the sample files to the dataset that was created in tutorial 2. Let's connect to the platform and get the dataset that we previously created.

```text
>> bf = Blackfynn();
>> ds = bf.datasets(1)

BFDataset with properties:

    description: 'This is a dataset for the second tutorial.'
         models: [1×3 BFModel]
          items: [0×0 BFBaseDataNode]
           name: 'tutorial2'
           type: 'DataSet'
>>
```
{% include note.html content="If you have multiple datasets, alter the above commands to make sure you selected the right dataset." %}

Now that we have a variable representing the dataset ```ds```, we can use the ```upload``` method to upload the test files to this dataset. Make sure you download and unzip the test files into a folder.

```text
>> ds.upload('~/Downloads/example_data');

The following 12 files will be uploaded to "N:dataset:xxxxxxxx-xxxx-xxxx-xxxxx-xxx":

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

Queued 12 files
```

If you want to upload files to a specific folder id the dataset, you can specify a path as an optional argument. If the folder, or nested folders don't exist yet, they will be created automatically.  Let's upload the same data to the 'exp1/trial1' folder. 

```text
>> ds.upload('~/Downloads/example_data', 'folder', 'exp1/trial1')

ds = 

  BFDataset with properties:

    description: ''
         models: [1×3 BFModel]
          items: [1×11 BFDataPackage]
           name: 'tutorial_matlab'
           type: 'DataSet'

```

We can see that the dataset now contains 11 items, each representing an uploaded package. 

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

## Linking a file to a metadata record
Once files are on the platform, you can associate them with metadata records that you created. Let's add some of the uploaded files to the records that were previously created in [tutorial 2](tutorial2.html). You can use the ```linkFiles``` command.

Link one of the files to the first trial that we created in tutorial 2. ```trials``` is a variable that contains the list of ```trial``` object we created before.

```text
>> trials(1).linkFile(ds.items(1))

ans = 

 BFRecord(trial) with properties: 

                 name: 'Trial 1'
    stimulationperiod: 300
```

The file is now associated with this trial and you can retrieve the file for the record using the ```getFiles``` command.

```text
>> trials(1).getFiles()

ans = 

  BFTabular with properties:

    name: 'table2'
    type: 'Tabular'
```

This completes the tutorial. We discussed how to upload files from within MATLAB and how to link uploaded files to existing metadata records. Please make sure to read the entire documentation for these commands as additional functionality beyond the scope of this tutorial is available.






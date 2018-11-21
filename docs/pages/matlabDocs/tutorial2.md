---
title: Metadata management
keywords: tutorial, beginner, login
last_updated: October 17, 2018
summary: "Tutorial 2: Creating a new dataset and congiguring the models to capture metadata."
sidebar: matlab_docs_sidebar
permalink: tutorial2.html
folder: matlabDocs
---

## Introduction
This tutorial describes how you can use the Blackfynn platform to create a new dataset and specify the stucture of your metadata. Metadat on the Blackfynn platform is captured in models that can be linked to eachother. In this tutorial, we will create a number of models typical to an experimental Neuroscience laboratory. If you want, you can replace the models that we are creating by models that are more appropriate for the data that you want to manage in your dataset.

## Creating models for your dataset
First, let's login and create a new dataset for this tutorial

```text
>> bf = Blackfynn()

>> ds = bf.createDataset('tutorial2','This is a dataset for the second tutorial.')

ds = 

  BFDataset with properties:

    description: 'This is a dataset for the second tutorial.'
         models: [0×0 BFModel]
          items: [0×0 BFBaseDataNode]
           name: 'tutorial2'
           type: 'DataSet'

```

You can see that we created a new dataset that contains no models, and no items (files). Next, we will create three models:

 * **subject** a model capturing information about subjects
 * **experiment** representing an experiment 
 * **trial** representing a trial within an experiment

```text
>> m1 = ds.createModel('Subject', 'This represents a subject in my dataset');
>> m2 = ds.createModel('Experiment', 'This represents an experiment in my dataset');
>> m3 = ds.createModel('trial', 'This represents a trial in my dataset');
```

We can verify in the dataset that it now contains three models:

```text
>> ds

ds = 

  BFDataset with properties:

    description: 'This is a dataset for the second tutorial.'
         models: [1×3 BFModel]
          items: [0×0 BFBaseDataNode]
           name: 'tutorial2'
           type: 'DataSet'
```

When we want to store metadata on the Blackfynn platform, we create records for specific models. These records contain the metadata that is specific to the data. Therefore, we need to define what metadata should be captured in each model. We do that by defining properties. Let's add some properties to each of the models.

First, we include properties for the Subject model: 1) Name (text), 2) Species (text), and 3) Age (number). In this tutorial, let's limit the Species to be one of ['human' 'feline' 'canine'] and Age to be an integer number of months.

```text
>> prop1 = m1.addProperty('Name', 'String', 'The name of the subject');
>> prop2 = m1.addProperty('Species', 'String', 'The species of the subject', 'enum', {'human' 'feline' 'canine'});
>> prop3 = m1.addProperty('Age', 'Double', 'The age in months')

```
and now properties for the Experiment and the trial:

```text
>> m2.addProperty('Name', 'String', 'The name of the experiment');
>> m2.addProperty('type', 'String', 'The type of the experiment');

>> m3.addProperty('Name', 'String', 'The name of the trial');
>> m3.addProperty('StimulationPeriod', 'Double', 'Duration of stimulation is miliseconds');

```

Finally, let's setup how the models relate to eachother. In this dataset, let's assume that a subject **participates** in an experiment, and that each experiment **contains** multiple trials. Of course, you can add any number of other relationships between the models. 

```text
>> m1.createRelationship(m2, 'ParticipatesIn');
>> m2.createRelationship(m3, 'Contains')

ans = 

  BFRelationship with properties:

           from: [1×1 BFModel]
             to: [1×1 BFModel]
           name: 'ParticipatesIn'
    description: ''
```

We now have created the models and relationships that define how metadat for this dataset is organized. In the next section, we will populate the database with some records for each model and link the records to eachother using the defined relationships. 

## Creating and linking records

Metadata records contain the actual information that you want to capture. In this example, we will create 1 subject, 1 experiment and 2 trials. Typical datasets obviously contain many more records. Records are created from the model objects. Let's start by creating a subject for our experiment.

```text
>> subj = m1.createRecords(struct('name', 'Subject 1', 'species', 'human', 'age', 24))

ans = 

 BFRecord(subject) with properties: 

       type: 'subject'
        age: 24
       name: 'Subject 1'
    species: 'human'

```

Next, we will create the experiment:

```text
>> exp = m2.createRecords(struct('name', 'Experiment 1', 'type', 'Chronic Stim protocol'))

ans = 

 BFRecord(experiment) with properties: 

    type: 'Chronic Stim protocol'
    name: 'Experiment 1'
```

and finally, 2 trials:

```text
>> records(1) = struct('name', 'Trial 1', 'stimulationperiod', 300);
>> records(2) = struct('name', 'Trial 2', 'stimulationperiod', 600);
>> trials = m3.createRecords(records);
```

All the records are now created. Next, we can link the records using the relationships that we defined earlier. First, we link the subject to the experiment, and then the experiment to the trials.

```text
>> subj.link(exp, 'ParticipatesIn');
>> exp.link(trials, 'Contains')
```

This completes the metadata tutorial. We defined models and relationships, followed by the creation of records for each of those nodels. Finally, we linked the records using the relationships. You can open the web application to see how this is represented in the platform or use the MATLAB toolbox to navigate over the linked records. 

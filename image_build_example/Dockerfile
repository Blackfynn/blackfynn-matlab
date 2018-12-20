FROM openjdk:8u171-jdk as base

ENV ML_PATH /usr/local/MATLAB

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:${ML_PATH}/runtime/glnxa64:${ML_PATH}/bin/glnxa64:${ML_PATH}/sys/os/glnxa64:${ML_PATH}/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:${ML_PATH}/sys/java/jre/glnxa64/jre/lib/amd64/server:${ML_PATH}/sys/java/jre/glnxa64/jre/lib/amd6

COPY ./MATLAB /usr/local/MATLAB

WORKDIR /usr/local/MATLAB

RUN adduser --gecos '' vagrant

#!/bin/bash

JH="${1?'please specify desired JAVA_HOME'}"


export JAVA_HOME=$JH

# TODO: remove any paths that contain java or do not exist
export PATH=$JAVA_HOME/bin:$PATH

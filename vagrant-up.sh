#!/bin/bash

export K8S_NODE_OS=ubuntu
export K8S_NODES=1
export VAGRANT_DEFAULT_PROVIDER=virtualbox
#export HTTP_PROXY=http://proxy-wsa.esl.cisco.com:80 
#export HTTPS_PROXY=http://proxy-wsa.esl.cisco.com:80 

vagrant up 

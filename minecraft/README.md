# Dedicated Storage (RWO) Demo Application

## Introduction

The Minecraft app contained in this folder can be used to demo
how a RWO PVC can be used by applications in an IBM Storage Fusion
of Red Hat OpenShift Data Foundation enabled cluster.

The application uses:

* `quay.io/vcppds7878/minecraft-server:latest` as a container image

## Building your own container image

To build your own container image: Go to `https://github.com/itzg/docker-minecraft-server`

:exclamation: __Make sure your registry repo is accessible (public) if the OpenShift cluster does not have a specific pull-secret.__

## Deploying your application

To deploy the application and use it perform the following:

* `oc create -f ./minecraft-app.yaml`
* `oc get route -n minecraft`
* Use a Minecraft client application connect to this server


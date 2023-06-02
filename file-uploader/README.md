# Shared Storage (RWX) Demo Application

## Introduction

The File Uploader app contained in this folder can be used to demo
how a RWX PVC can be used by applications in an IBM Storage Fusion
of Red Hat OpenShift Data Foundation enabled cluster.

The application uses:

* `quay.io/vcppds7878/file-uploader:latest` as a container image

## Deploying your application

To deploy the application and use it perform the following:

* `cd {the directory where you cloned the repo}/file-uploader`
* `oc create -f ./file-uploader-app.yaml`
* `oc get route -n file-uploader-rwx`
* Point your web browser to the route

![File Uploader Web Page](file-uploader-ui.png)

:exclamation: __You can only upload one (1) file at a time.__

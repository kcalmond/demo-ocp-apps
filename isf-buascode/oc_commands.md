# Command examples

## Wait for BU storage location to come online

```
echo "Wating to wait for the BSL to come online"
while true
do
   bslstatus=$(oc get backupstoragelocations.data-protection.isf.ibm.com bsl-myaws-endpoint -n ibm-spectrum-fusion-ns -o jsonpath --template="{.status.phase}")
   if [ "x${bslstatus}" == "xConnected" ]
   then
      echo "Backup Storage Location Connected"
      break
   else
      echo "Backup Storage Location not Connected yet"
      sleep 1
   fi
done
```

## Check status of backup

```
$ oc get backup.data-protection.isf.ibm.com -n ibm-spectrum-fusion-ns -o 'custom-columns=NAME:.metadata.name,APP:.spec.application,POLICY:.spec.backupPolicy,STATUS:.status.phase'

NAME                                          APP                 POLICY         STATUS
file-uploader-rwx-cli-external-202306071953   file-uploader-rwx   cli-external   Completed
```

## Application Restore
```
$ oc delete project file-uploader-rwx
```

## Check Restore Status
```
$ oc get restore.data-protection.isf.ibm.com -n ibm-spectrum-fusion-ns -o 'custom-columns=NAME:.metadata.name,BACKUP:.spec.backup,STATUS:.status.phase'
NAME                                 BACKUP                                        STATUS
file-uploader-rwx-restore-external   file-uploader-rwx-cli-external-202306071953   Completed 
```

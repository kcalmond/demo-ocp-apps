# Why Backup as Code?
## From the developer's seat

With container orchestration platforms, the end user is expected to be able to create an application and the tooling that goes with so that upon deployment, not only the applications comes online but the application can be natively integrated with the environment where it runs and leverages all of the services provided by the platform at will. Such services should include backup and restore for stateful applications and should be shipped together with the application (e.g. via the application GitHub repository).

## From the infrastructure team's seat

As mentioned above, container orchestration platform are natively designed to be self contained and self service and therefor, it would be ludicrous to expect the infrastructure team to grant access to a resource every time it is needed. In these environment the application is expected to be granted access automatically to said requested resources, based on rules and fences created by the infrastructure team. Such rules and fences to safeguard the platform would include topics like:

* Storage quotas (maximum number of bytes or files an application can use)
* Compute resources (maximum amount of memory or CPU an application can consume)
* Security (userid and grouped assigned to applications together with specific Security Constraints)

However, the infrastructure team does not operate a single Red Hat OpenShift cluster and it would be inconceivable to picture the deployment of all rules, fences and services  being performed one cluster at a time via a graphical user interface. This is where backup as code comes into play.

Not only the developers can leverage the backup and restore services via custom resources and integrate these functionalities with the application code they are creating but the infrastructure can actually configure those services in the same way to reach the level of industrialization required in large environments.

# Let's do this
## Infrastructure configuration

The infrastructure team will be responsible for defining:

* Where the application data and metadata being backed up is physically stored
* How often the application will be backed up
* How long the application backup will be kept

For this example we will use an external Amazon S3 bucket as an endpoint for what is know as the IBM Storage Fusion Backup Storage Location. To configure the BackupStorageLocation custom resource you will need the following information:

* The type of S3 endpoint (multiple offered by IBM Storage Fusion e.g. aws, cos, s3, ...)
* The name of the S3 bucket where the backup will store everything
* The credentials required to connect to the S3 endpoint
* Some optional parameters depending on the type of S3 endpoint (e.g. the Region name for AWS)

### Step 1 - Store your S3 credentials
[1_store_S3_cred.yaml]()

    cat <<EOF | oc create -f -
    ---
    apiVersion: v1
    kind: Secret
    data:
      access-key-id: {insert_your_aws_access_key_id}
      secret-access-key: {insert_your_aws_secret_access_key}
    metadata:
      name: bsl-myaws-secret
      namespace: ibm-spectrum-fusion-ns
    type: Opaque
    EOF 

### Step 2 - Create the Backup Storage Location
[2_create_bu_location.yaml]()

    cat <<EOF | oc create -f -
    ---
    apiVersion: data-protection.isf.ibm.com/v1alpha1
    kind: BackupStorageLocation
    metadata:
      name: bsl-myaws-endpoint
      namespace: ibm-spectrum-fusion-ns
    spec:
      type: aws
      credentialName:  bsl-myaws-secret
      provider: isf-backup-restore
      params:
        region: {region_name}
        bucket: {bucket_name}
        endpoint: https://{endpoint_fqdn}
    EOF 

### Step 3 - Wait for the Backup Storage Location to come online

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

### Step 4 - Create External Backup Policy (using external S3 endpoint)
[4_create_external_S3_policy.yaml]()

    cat <<EOF | oc create -f -
    ---
    apiVersion: data-protection.isf.ibm.com/v1alpha1
    kind: BackupPolicy
    metadata:
      name: cli-external
      namespace: ibm-spectrum-fusion-ns
    spec:
      backupStorageLocation: bsl-myaws-endpoint
      provider: isf-backup-restore
      retention:
        number: 5
        unit: weeks
      schedule:
        cron: 00 6  * * 0
        timezone: America/Los_Angeles
    EOF 

You can alter the scheduling example using CRON standards. The above will schedule a backup every Sunday. Such a backup policy can be used to restore the application to a different namespace or different cluster as the backup is being kept outside of the original Red Hat OpenShift namespace.

### Step 5 - Create internal backup policy (using namespace scoped snapshots)
[5_create_internal_bu_policy.yaml]()

    cat <<EOF | oc create -f -
    ---
    apiVersion: data-protection.isf.ibm.com/v1alpha1
    kind: BackupPolicy
    metadata:
      name: cli-internal
      namespace: ibm-spectrum-fusion-ns
    spec:
      backupStorageLocation: isf-dp-inplace-snapshot
      provider: isf-backup-restore
      retention:
        number: 7
        unit: days
      schedule:
        cron: '00 6  * * * '
        timezone: America/Los_Angeles
    EOF 

You can alter the scheduling example using CRON standards. The above will schedule a backup every day of the week.
Application configuration

The only thing that must be perform is to assign the correct backup policy to the application namespace.

### Step 6.a - Assign the external backup policy
[6.a.assign_external_bu_policy]()

    cat <<EOF | oc create -f -
    apiVersion: data-protection.isf.ibm.com/v1alpha1
    kind: PolicyAssignment
    metadata:
      name: file-uploader-rwx-cli-external
      namespace: ibm-spectrum-fusion-ns
    spec:
      application: file-uploader-rwx
      backupPolicy: cli-external
      runNow: true
    EOF 

N.B.: The runNow: true parameter will cause a backup to start immediately upon the assignment of the backup policy to the application namespace.

### Step 6.b  - Assign the internal backup policy
[6.b.assign_internal_bu_policy]()

    cat <<EOF | oc create -f -
    apiVersion: data-protection.isf.ibm.com/v1alpha1
    kind: PolicyAssignment
    metadata:
      name: file-uploader-rwx-cli-internal
      namespace: ibm-spectrum-fusion-ns
    spec:
      application: file-uploader-rwx
      backupPolicy: cli-internal
      runNow: false
    EOF 

### Check the status of your backup

    $ oc get backup.data-protection.isf.ibm.com -n ibm-spectrum-fusion-ns -o 'custom-columns=NAME:.metadata.name,APP:.spec.application,POLICY:.spec.backupPolicy,STATUS:.status.phase'
    NAME                                          APP                 POLICY         STATUS
    file-uploader-rwx-cli-external-202306071953   file-uploader-rwx   cli-external   Completed 

Application restore

To test the restore of an application then becomes an easy set of task.

### Delete the entire application namespace

    $ oc delete project file-uploader-rwx 

### Step 7 - Initiate the restore
[7_start_restore.yaml]()

    cat <<EOF | oc create -f -
    ---
    apiVersion: data-protection.isf.ibm.com/v1alpha1
    kind: Restore
    metadata:
      name: file-uploader-rwx-restore-external
      namespace: ibm-spectrum-fusion-ns
    spec:
      backup: $(oc get backup.data-protection.isf.ibm.com -n ibm-spectrum-fusion-ns | grep "cli-external" | awk '{ print $1 }')
    EOF 

### - Check the restore status


    $ oc get restore.data-protection.isf.ibm.com -n ibm-spectrum-fusion-ns -o 'custom-columns=NAME:.metadata.name,BACKUP:.spec.backup,STATUS:.status.phase'
    NAME                                 BACKUP                                        STATUS
    file-uploader-rwx-restore-external   file-uploader-rwx-cli-external-202306071953   Completed 


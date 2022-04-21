**************************
### FRESH INSTALLATION ###
**************************

```
$ sudo su
$ ./k3s-installer.sh
$ ./annotationlab-installer.sh
```
##### Note: Incase of Redhat installation, the server will reboot after k3s installation. SSH into the server and then continue installation of Annotation Lab #####

The last command will generate some commands which can be executed to get secrets of the installation.

Copy the output to a file for future use.

Use `admin` username and get password using one of the commands from above output.


***********************
### UPGRADE VERSION ###
***********************
```
$ sudo su
$ ./annotationlab-updater.sh
```

***********************
### WORK OVER PROXY ###
***********************

#### CUSTOM CA CERTIFICATE ####

You can provide a custom CA certificate chain to be included into the deployment. To do it add `--set-file custom_cacert=./cachain.pem` options to
`helm install/upgrade` command inside `annotationlab-installer.sh` and `annotationlab-updater.sh` files.

cachain.pem must include certifcates in the following format:
```
-----BEGIN CERTIFICATE-----
....
-----END CERTIFICATE-----
```

#### PROXY ENV VARIABLES ####

You can provide a proxy to use for external communications. To do it add `--set proxy.http=[protocol://]<host>[:port]`, `--set proxy.https=[protocol://]<host>[:port]`, `--set proxy.no=<comma-separated list of hosts/domains>` commands inside `annotationlab-installer.sh` and `annotationlab-updater.sh` files.

******************
### TLS ###
******************

##### Notice: you must already have a created or purchased certificate and domain name associated with your server public IP address #####

#### ENABLE TLS FOR DOMAIN ####

You can enable tls for you domain by changing annotationlab-install.sh (if you installing annotationlab) or annotationlab-upgrade.sh (if you upgrading existing cluster). Step-by-step instruction below.

##### 1. Disable default backend. #####
Find and remove this line:
```
    --set ingress.defaultBackend=true \
```
or just change it to false:
```
    --set ingress.defaultBackend=false \
```

##### 2. Enable ingress to use domain name and TLS. #####
replace this line:
```
    --set 'ingress.hosts[0].host=domain.tld' \
```
with 4 other lines:
```
    --set ingress.hosts[0].host='CHANGE_ME' \
    --set ingress.hosts[0].path='/' \
    --set ingress.tls[0].hosts[0]='CHANGE_ME' \
    --set ingress.tls[0].secretName=annotationlab-tls \
```
don't forget to replace CHANGE_ME with your domain name.

##### 3. Create kubernetes TLS secret: #####
in terminal run:
```
kubectl create secret tls annotationlab-tls --cert path/to/your/tls.cert --key path/to/your/tls.key
```

##### Notice: You also must to change annotationlab-upgrade.sh before upgrade. #####

**************************
### BACKUP AND RESTORE ###
**************************

#### BACKUP ####

You can enable daily backups by adding several variables with --set option to helm command in `annotationlab-updater.sh`:
```
backup.enable=true
backup.files=true
backup.s3_access_key="<ACCESS_KEY>"
backup.s3_secret_key="<SECRET_KEY>"
backup.s3_bucket_fullpath="<FULL_PATH>"
```

*Notice:* Files backups enabled by default. If you don't need to backup files, you have to change
```
backup.files=true
```

to

```
backup.files=false
```

File backup will save your `/images` and `/models` directories and add it to the backup .tar archive.

`<ACCESS_KEY>` - your access key for aws s3 access

`<SECRET_KEY>` - your secret key for aws s3 access

`<FULL_PATH>` - full path to your backup in s3 bucket (f.e. s3://example.com/path/to/my/backup/dir)

#### SECRET ####
*Notice:* On restoring the backup from the dump in differnt machine, backup of the secret is required.
```
$ cd backup-secret
$ sudo ./backup-secrets.sh
$ aws s3 cp secrets s3://bucket_name/
```

#### RESTORE ####

##### DATABASE #####
To restore annotationlab from backup you need new clear installation of annotationlab. Do it with `annotationlab-install.sh`.
Next you need to download latest backup from your s3 bucket and move and archive to `restore/database/` directory. 
Next go to the `restore/database/` directory and execute script 'restore_all_databases.sh' with name of your backup archive as argument. For example:

```
cd restore/database/
sudo ./restore_all_databases.sh 2022-01-07-annotationlab-all-databases.tar.xz
```

*Notice:* You need `xz` and `bash` installed to execute this script.
*Notice:* This script works only with backups created by annotationlab backup system.
*Notice:* Run this scripts with `sudo` command

After database restore complete you can check logs in `restore_log` directory created by restore script.

##### FILES #####

Download your files backup and move it to `restore/files` directory. Go to `restore/files` directory and execute script 'restore_files.sh' with name of your backup archive as argument. For example:
```
cd restore/files/
sudo ./restore_files.sh 2022-01-07-annotationlab-files.tar
```
#### SECRET ####

Download your secret backup and move it to `restore/secret` directory. Go to `restore/secret` directory and execute script 'restore-admin-keycloak-cred.sh' with secret as an argument. For example:
```
$ cd restore/secret
$ ./restore-secrets.sh <keycloak_admin_secret> <keycloak_client_secret> <flask_secret>
```
*Notice:* You need `bash` installed to execute this script.
*Notice:* This script works only with backups created by annotationlab backup system.
*Notice:* Run this scripts with `sudo` command

##### Reboot #####
After restoring database and files, reboot AnnotationLab:
```
sudo reboot
```



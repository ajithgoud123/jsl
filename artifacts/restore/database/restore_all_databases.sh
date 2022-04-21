#!/bin/bash
BACKUP_ARCHIVE_NAME=$1

DATE=$(date '+%F')
tar -xf $BACKUP_ARCHIVE_NAME

ALAB_DATABASE_POD_NAME=$(kubectl get pod -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=postgresql -o custom-columns=":metadata.name")
KEYCLOAK_DATABASE_POD_NAME=$(kubectl get pod -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=keycloak-postgres -o custom-columns=":metadata.name")
AIRFLOW_DATABASE_POD_NAME=$(kubectl get pod -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=airflow-postgresql -o custom-columns=":metadata.name")

LOGDIR="restore_logs"

KEYCLOAK_LOG_FILE=$LOGDIR/$DATE-keycloak.log
ANNOTATIONLAB_LOG_FILE=$LOGDIR/$DATE-annotationlab.log
AIRFLOW_LOG_FILE=$LOGDIR/$DATE-airflow.log

if [ ! -d "$LOGDIR" ]; then
  mkdir $LOGDIR
fi

if [ ! -f "$ANNOTATIONLAB_LOG_FILE" ]; then
  touch $ANNOTATIONLAB_LOG_FILE
fi

echo "START-RESTORING-$DATE" >> $ANNOTATIONLAB_LOG_FILE
kubectl cp tmp/backup/annotationlab.tar $ALAB_DATABASE_POD_NAME:/tmp/annotationlab.tar
kubectl exec $ALAB_DATABASE_POD_NAME -- /bin/bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_restore -U annotationlab -c -d annotationlab -v "/tmp/annotationlab.tar"' &>> $ANNOTATIONLAB_LOG_FILE
echo "########END-RESTORING########" >> $ANNOTATIONLAB_LOG_FILE
if [ $? -eq 0 ]; then
  echo "Annotationlab database restored sucessfully"
else
  echo "Annotationlab database restore failed. Please see logs in $ANNOTATIONLAB_LOG_FILE"
fi

if [ ! -f "$KEYCLOAK_LOG_FILE" ]; then
  touch $KEYCLOAK_LOG_FILE
fi

echo "START-RESTORING-$DATE" >> $KEYCLOAK_LOG_FILE
kubectl cp tmp/backup/keycloak.tar $KEYCLOAK_DATABASE_POD_NAME:/tmp/keycloak.tar
kubectl exec $KEYCLOAK_DATABASE_POD_NAME -- /bin/bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_restore -U keycloak -c -d keycloak -v "/tmp/keycloak.tar"' &>> $KEYCLOAK_LOG_FILE
echo "########END-RESTORING########" >> $KEYCLOAK_LOG_FILE
if [ $? -eq 0 ]; then
  echo "Keycloak database restored sucessfully"
else
  echo "Keycloak database restore failed. Please see logs in $KEYLOAK_LOG_FILE"
fi

if [ ! -f "$AIRFLOW_LOG_FILE" ]; then
  touch $AIRFLOW_LOG_FILE
fi

echo "START-RESTORING-$DATE" >> $AIRFLOW_LOG_FILE
kubectl cp tmp/backup/airflow.tar $AIRFLOW_DATABASE_POD_NAME:/tmp/airflow.tar
kubectl exec $AIRFLOW_DATABASE_POD_NAME -- /bin/bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_restore -U airflow -c -d airflow -v "/tmp/airflow.tar"' &>> $LOGDIR/$DATE-airflow.log
echo "########END-RESTORING########" >> $AIRFLOW_LOG_FILE
if [ $? -eq 0 ]; then
  echo "Airflow database restored sucessfully"
else
  echo "Airflow database restore failed. Please see logs in $AIRFLOW_LOG_FILE"
fi


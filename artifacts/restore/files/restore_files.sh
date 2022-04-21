#!/bin/bash
BACKUP_ARCHIVE_NAME=$1

tar -xf $BACKUP_ARCHIVE_NAME

ALAB_POD_NAME=$(kubectl get pod -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=annotationlab -o jsonpath={..metadata.name})

if [ -z "$(ls -A images)" ]; then
   echo "images directory is empty."
else
  echo "images directory is not empty, restoring..."
  kubectl cp images $ALAB_POD_NAME:/
fi

if [ -z "$(ls -A models)" ]; then
   echo "models directory is empty."
else
  echo "models directory is not empty, restoring..."
  kubectl cp models $ALAB_POD_NAME:/
fi


if [ $? -eq 0 ]; then
  echo "Annotationlab files restored sucessfully"
else
  echo "Annotationlab files restore failed."
fi

echo "Cleanup..."
rm -rf {models,images}
echo "DONE"

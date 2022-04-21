#!/bin/bash
set -e
kubectl get secret $(kubectl get secret -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=keycloak -o custom-columns=":metadata.name") --template={{.data.password}} | base64 --decode  > ./secrets/admin-keycloak-cred.txt
kubectl get secret $(kubectl get secret -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=annotationlab -o custom-columns=":metadata.name") --template={{.data.KEYCLOAK_CLIENT_SECRET_KEY}}|base64 --decode > ./secrets/keycloak-client-secret.txt
kubectl get secret $(kubectl get secret -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=annotationlab -o custom-columns=":metadata.name") --template={{.data.FLASK_SECRET_KEY}}|base64 --decode > ./secrets/flask-secret-key.txt
 

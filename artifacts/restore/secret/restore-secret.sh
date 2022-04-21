#!/bin/bash
set -e
keycloak_admin_secret=$1
keycloak_client_secret=$2
flask_secret=$3

display_usage()
{
   echo "Error: Pass secrets as an argument"
   echo "Usage: $0 keycloak_admin_secret keycloak_client_secret flask_secret"
   exit 1
}

if [ $# -ne 3 ]; then
    display_usage
fi
kubectl get secret $(kubectl get secret -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=keycloak -o custom-columns=":metadata.name") -o json | jq --arg keycloak_admin_secret "$(echo $keycloak_admin_secret | base64)" '.data["password"]=$keycloak_admin_secret' | kubectl apply -f - 
kubectl get secret $(kubectl get secret -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=annotationlab -o custom-columns=":metadata.name") -o json | jq --arg keycloak_client_secret "$(echo $keycloak_client_secret | base64)" '.data["KEYCLOAK_CLIENT_SECRET_KEY"]=$keycloak_client_secret' | kubectl apply -f -
kubectl get secret $(kubectl get secret -l app.kubernetes.io/instance=annotationlab,app.kubernetes.io/name=annotationlab -o custom-columns=":metadata.name") -o json | jq --arg flask_secret "$(echo $flask_secret | base64)" '.data["FLASK_SECRET_KEY"]=$flask_secret' | kubectl apply -f -

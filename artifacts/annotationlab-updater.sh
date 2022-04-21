#!/usr/bin/env bash
set -euo pipefail

if [ ! -f annotationlab-*.tgz ]; then
    echo "Please make sure there is a annotationlab-*.tgz helm chart package in the same directory as this installer."
    exit 1
fi

ANNOTATIONLAB_VERSION=$(ls annotationlab-*.tgz | sed 's/annotationlab-\(.*\).tgz/\1/')
echo "Upgrading to Annotation Lab v"$ANNOTATIONLAB_VERSION
kubectl get nodes

HELM_VER=v3.3.1

curl -s -L https://get.helm.sh/helm-${HELM_VER}-linux-amd64.tar.gz -o- | tar -C /usr/local/bin/ -x linux-amd64/helm -zf- --strip-components=1

IMAGES="${ANNOTATIONLAB_VERSION} active-learning-${ANNOTATIONLAB_VERSION} dataflows-${ANNOTATIONLAB_VERSION} auth-theme-${ANNOTATIONLAB_VERSION} backup"
for image in $IMAGES; do
    crictl pull johnsnowlabs/annotationlab:${image};
done


FLASK_SECRET_KEY=$(kubectl get secret -l app.kubernetes.io/instance=annotationlab -l app.kubernetes.io/name=annotationlab -o jsonpath='{.items[0].data.FLASK_SECRET_KEY}' | base64 -d)
KEYCLOAK_CLIENT_SECRET_KEY=$(kubectl get secret -l app.kubernetes.io/instance=annotationlab -l app.kubernetes.io/name=annotationlab -o jsonpath='{.items[0].data.KEYCLOAK_CLIENT_SECRET_KEY}' | base64 -d)
PG_PASSWORD=$(kubectl get secret -l app.kubernetes.io/instance=annotationlab -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].data.postgresql-password}' | base64 -d)
PG_KEYCLOAK_PASSWORD=$(kubectl get secret -l app.kubernetes.io/instance=annotationlab -l app.kubernetes.io/name=keycloak-postgres -o jsonpath='{.items[0].data.postgresql-password}' | base64 -d)
ADMIN_PASSWORD=$(kubectl get secret -l app.kubernetes.io/instance=annotationlab -l app.kubernetes.io/name=keycloak -o jsonpath='{.items[0].data.password}' | base64 -d)
REDIS_PASSWORD=$(kubectl get secret $(kubectl get secret -l chart=airflow -l release=annotationlab-airflow | grep redis-pass | awk '{print $1}') -o jsonpath='{.data.password}' | base64 -d)


helm upgrade annotationlab annotationlab-${ANNOTATIONLAB_VERSION}.tgz                     \
    --kubeconfig /etc/rancher/k3s/k3s.yaml                                                \
    --set image.tag=${ANNOTATIONLAB_VERSION}                                              \
    --set model_server.count=1                                                            \
    --set ingress.enabled=true                                                            \
    --set ingress.defaultBackend=true                                                     \
    --set 'ingress.hosts[0].host=domain.tld'                                              \
    --set ingress.uploadLimitInMegabytes=16                                               \
    --set airflow.model_server.count=1                                                    \
    --set airflow.redis.password=${REDIS_PASSWORD}                                        \
    --set configuration.FLASK_SECRET_KEY=${FLASK_SECRET_KEY}                              \
    --set configuration.KEYCLOAK_CLIENT_SECRET_KEY=${KEYCLOAK_CLIENT_SECRET_KEY}          \
    --set postgresql.postgresqlPassword=${PG_PASSWORD}                                    \
    --set keycloak.postgresql.postgresqlPassword=${PG_KEYCLOAK_PASSWORD}                  \
    --set keycloak.secrets.admincreds.stringData.user=admin                               \
    --set keycloak.secrets.admincreds.stringData.password=${ADMIN_PASSWORD}


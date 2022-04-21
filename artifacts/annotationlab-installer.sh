#!/usr/bin/env bash
set -euo pipefail

if ! command -v helm >/dev/null; then
    echo "Please install helm or add it to \$PATH"
    exit 1
fi
if ! command -v kubectl >/dev/null; then
    echo "Please install kubectl or add it to \$PATH"
    exit 1
fi

if [ ! -f annotationlab-*.tgz ]; then
    echo "Please make sure there is a annotationlab-*.tgz helm chart package in the same directory as this installer."
    exit 1
fi


ANNOTATIONLAB_VERSION=$(ls annotationlab-*.tgz | sed 's/annotationlab-\(.*\).tgz/\1/')

kubectl get nodes

IMAGES="${ANNOTATIONLAB_VERSION} active-learning-${ANNOTATIONLAB_VERSION} dataflows-${ANNOTATIONLAB_VERSION} auth-theme-${ANNOTATIONLAB_VERSION} backup"
for image in $IMAGES; do
    crictl pull johnsnowlabs/annotationlab:${image};
done

uuid_gen_string="\$(openssl rand -hex 4)-\$(openssl rand -hex 2)-\$(openssl rand -hex 2)-\$(openssl rand -hex 2)-\$(openssl rand -hex 6)"
password_gen_string="\$(openssl rand -hex 10)"

helm install annotationlab annotationlab-${ANNOTATIONLAB_VERSION}.tgz                                 \
    --kubeconfig /etc/rancher/k3s/k3s.yaml                                                            \
    --set image.tag=${ANNOTATIONLAB_VERSION}                                                          \
    --set model_server.count=1                                                                        \
    --set ingress.enabled=true                                                                        \
    --set ingress.defaultBackend=true                                                                 \
    --set ingress.uploadLimitInMegabytes=16                                                           \
    --set 'ingress.hosts[0].host=domain.tld'                                                          \
    --set airflow.model_server.count=1                                                                \
    --set airflow.redis.password=$(bash -c "echo ${password_gen_string}")                             \
    --set configuration.FLASK_SECRET_KEY=$(bash -c "echo ${password_gen_string}")                     \
    --set configuration.KEYCLOAK_CLIENT_SECRET_KEY=$(bash -c "echo ${uuid_gen_string}")               \
    --set postgresql.postgresqlPassword=$(bash -c "echo ${password_gen_string}")                      \
    --set keycloak.postgresql.postgresqlPassword=$(bash -c "echo ${password_gen_string}")             \
    --set keycloak.secrets.admincreds.stringData.user=admin                                           \
    --set keycloak.secrets.admincreds.stringData.password=$(bash -c "echo ${password_gen_string}")


helm template temporal temporalio/temporal \
    --namespace temporal-system \
    --create-namespace \
    --set server.replicaCount=1 \
    --set cassandra.config.cluster_size=1 \
    --set elasticsearch.replicas=1 \
    --set prometheus.enabled=false \
    --set grafana.enabled=false \
    --output-dir k8s-manifests/temporal/temporal-manifests


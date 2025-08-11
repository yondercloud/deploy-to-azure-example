#!/bin/bash

EXTERNAL_IP=$(kubectl get service cowsay-api-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$EXTERNAL_IP" ]; then
    echo "Error: Could not retrieve external IP address for cowsay-api-serve service"
    exit 1
fi

echo "Opening http://$EXTERNAL_IP"
open "http://$EXTERNAL_IP"

# Deploy to Azure Example

## Quick Deploy to Azure

Click the button below to deploy this application to Azure Kubernetes Service:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fyondercloud%2Fdeploy-to-azure-example%2Fmain%2Finfrastructure%2Fmain.json)

### Prerequisites
- Azure subscription
- GitHub personal access token (for private repos)

### What gets deployed:
- AKS cluster with auto-scaling
- Flux v2 GitOps extension
- Automatic deployment of Kubernetes manifests from this repository
    - temporal - A temporal server
    - temporal-setup - Create the default namespace the application uses for workflows
    - cowsay-api - Serves index.html, and also handles POST /cowsay to execute a temporal workflow
    - cowsay-worker - Temporal worker that handles activities in a Temporal workflow


### Notes

- The Infrastructure as Code is written using Bicep files. Run the ./scripts/bicep-compile script to convert those to ARM files. This outputs the main.json which is what the Deploy to Azure process needs.

- Flux is used to apply all of the manifests in the k8s-manifests subdirectory. Run the ./scripts/temporal-generate.sh which renders the Helm charts into Kubernetes manifests that Flux can apply. (I think Flux may be able to handle Helm charts more directly, but that is left as an exercise for the reader!)

- Use this command to access the AKS cluster using kubectl:
```
az aks get-credentials --resource-group <resource-group-from-deploy>  --name <cluster-name-from-deploy>
```

- There are port-forward scripts to help in local testing of the Temporal server running on the AKS cluster.
Run this command to use tmux to port forward both 7233 for the temporal server and 8080 for the workflow UI

```
./scripts/port-forward.sh
```

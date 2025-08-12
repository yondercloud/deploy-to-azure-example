@description('Name of the AKS cluster')
param clusterName string = 'aks-example-cluster'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Node count for the default node pool')
param nodeCount int = 3

@description('VM size for the nodes')
param nodeVmSize string = 'Standard_D4s_v3'

@description('Kubernetes version')
param kubernetesVersion string = '1.30.0'

@description('Git repository URL for Flux')
param gitRepoUrl string = 'https://github.com/yondercloud/deploy-to-azure-example.git'

@description('Git branch to track')
param gitBranch string = 'main'

@description('Path in the repository where manifests are located')
param gitPath string = './k8s-manifests/'

@description('Git repository authentication (none, ssh, https)')
param gitAuthType string = 'https'

@description('Git username (for HTTPS auth)')
@secure()
param gitUsername string = ''

@description('Git password/token (for HTTPS auth)')
@secure()
param gitPassword string = ''

@description('SSH private key (for SSH auth)')
@secure()
param gitSshPrivateKey string = ''

// Create AKS cluster
resource aksCluster 'Microsoft.ContainerService/managedClusters@2025-06-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${clusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: nodeCount
        vmSize: nodeVmSize
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        minCount: 5
        maxCount: 5
        maxPods: 80
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      azurepolicy: {
        enabled: true
      }
    }
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
    }
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    disableLocalAccounts: false
  }
}

// Enable Flux v2 extension on AKS
resource fluxExtension 'Microsoft.KubernetesConfiguration/extensions@2024-11-01' = {
  scope: aksCluster
  name: 'flux'
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
    configurationSettings: {
      'helm-controller.enabled': 'true'
      'source-controller.enabled': 'true'
      'kustomize-controller.enabled': 'true'
      'notification-controller.enabled': 'true'
      'image-automation-controller.enabled': 'false'
      'image-reflector-controller.enabled': 'false'
    }
  }
}

// Create Flux configuration for GitOps
resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2025-04-01' = {
  scope: aksCluster
  name: 'flux-config'
  properties: {
    scope: 'cluster'
    namespace: 'flux-system'
    sourceKind: 'GitRepository'
    suspend: false
    gitRepository: {
      url: gitRepoUrl
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      repositoryRef: {
        branch: gitBranch
      }
      httpsUser: gitAuthType == 'https' ? gitUsername : null
    }
    configurationProtectedSettings: gitAuthType == 'https' && !empty(gitPassword) ? {
      httpsKey: gitPassword
    } : gitAuthType == 'ssh' && !empty(gitSshPrivateKey) ? {
      sshPrivateKey: gitSshPrivateKey
    } : {}
    kustomizations: {
      infra: {
        path: gitPath
        dependsOn: []
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        retryIntervalInSeconds: 300
        prune: true
        force: false
      }
    }
  }
  dependsOn: [
    fluxExtension
  ]
}

// Output important information
output aksClusterName string = aksCluster.name
output aksClusterFqdn string = aksCluster.properties.fqdn
output aksClusterResourceId string = aksCluster.id
output fluxExtensionName string = fluxExtension.name
output fluxConfigurationName string = fluxConfig.name

// Output connection command
output kubeConfigCommand string = 'az aks get-credentials --resource-group ${resourceGroup().name} --name ${aksCluster.name}'

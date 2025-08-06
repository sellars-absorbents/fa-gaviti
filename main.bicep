param sites_fa_gaviti_name string = 'fa-gaviti'
param serverfarms_sam_asp_prod_externalid string = '/subscriptions/07fa5c8a-e372-40c1-8794-4c29e70fd46e/resourceGroups/rg-SharedServices-Prod/providers/Microsoft.Web/serverfarms/sam-asp-prod'

resource sites_fa_gaviti_name_resource 'Microsoft.Web/sites@2024-11-01' = {
  name: sites_fa_gaviti_name
  location: 'Central US'
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${sites_fa_gaviti_name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${sites_fa_gaviti_name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverfarms_sam_asp_prod_externalid
    reserved: true
    isXenon: false
    hyperV: false
    dnsConfiguration: {}
    outboundVnetRouting: {
      allTraffic: false
      applicationTraffic: false
      contentShareTraffic: false
      imagePullTraffic: false
      backupRestoreTraffic: false
    }
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'Python|3.12'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientAffinityProxyEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    ipMode: 'IPv4'
    customDomainVerificationId: '36281436D3604480EB4A21CEB962157A2176ABC309EF1EA3039DFE133E25426A'
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    endToEndEncryptionEnabled: false
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource sites_fa_gaviti_name_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_fa_gaviti_name_resource
  name: 'ftp'
  location: 'Central US'
  properties: {
    allow: true
  }
}

resource sites_fa_gaviti_name_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_fa_gaviti_name_resource
  name: 'scm'
  location: 'Central US'
  properties: {
    allow: true
  }
}

resource sites_fa_gaviti_name_web 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: sites_fa_gaviti_name_resource
  name: 'web'
  location: 'Central US'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'Python|3.12'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$fa-gaviti'
    scmType: 'GitHubAction'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    localMySqlEnabled: false
    managedServiceIdentityId: 17842
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    functionAppScaleLimit: 0
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
    http20ProxyFlag: 0
  }
}

resource sites_fa_gaviti_name_1ad0b02c_acb7_4da9_bdea_9a166a057857 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_name_resource
  name: '1ad0b02c-acb7-4da9-bdea-9a166a057857'
  location: 'Central US'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"b00977b8a7c4b2a4a25991de762a55067f91d9ad","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-08-03T19:26:59.1749929Z'
    end_time: '2025-08-03T19:27:00.1213831Z'
    active: true
  }
}

resource sites_fa_gaviti_name_2aa14763_7f0b_437d_8755_66aab90c1c4c 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_name_resource
  name: '2aa14763-7f0b-437d-8755-66aab90c1c4c'
  location: 'Central US'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"0e3975dd76128c71ed3b3700786ac2d26dd79fb8","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-08-03T19:15:55.8628322Z'
    end_time: '2025-08-03T19:15:56.9522481Z'
    active: false
  }
}

resource sites_fa_gaviti_name_da005431_7c65_48a9_a093_aa0ddc2a1126 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_name_resource
  name: 'da005431-7c65-48a9-a093-aa0ddc2a1126'
  location: 'Central US'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"b00977b8a7c4b2a4a25991de762a55067f91d9ad","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-08-03T19:20:54.6568588Z'
    end_time: '2025-08-03T19:20:55.7074724Z'
    active: false
  }
}

resource sites_fa_gaviti_name_sites_fa_gaviti_name_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2024-11-01' = {
  parent: sites_fa_gaviti_name_resource
  name: '${sites_fa_gaviti_name}.azurewebsites.net'
  location: 'Central US'
  properties: {
    siteName: 'fa-gaviti'
    hostNameType: 'Verified'
  }
}

resource sites_fa_gaviti_name_nonprod 'Microsoft.Web/sites/slots@2024-11-01' = {
  parent: sites_fa_gaviti_name_resource
  name: 'nonprod'
  location: 'Central US'
  kind: 'functionapp,linux'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: 'fa-gaviti-nonprod.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: 'fa-gaviti-nonprod.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverfarms_sam_asp_prod_externalid
    reserved: true
    isXenon: false
    hyperV: false
    dnsConfiguration: {}
    outboundVnetRouting: {
      allTraffic: false
      applicationTraffic: false
      contentShareTraffic: false
      imagePullTraffic: false
      backupRestoreTraffic: false
    }
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'Python|3.12'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientAffinityProxyEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    ipMode: 'IPv4'
    customDomainVerificationId: '36281436D3604480EB4A21CEB962157A2176ABC309EF1EA3039DFE133E25426A'
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    endToEndEncryptionEnabled: false
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource sites_fa_gaviti_name_nonprod_ftp 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_fa_gaviti_name_nonprod
  name: 'ftp'
  location: 'Central US'
  properties: {
    allow: true
  }
  dependsOn: [
    sites_fa_gaviti_name_resource
  ]
}

resource sites_fa_gaviti_name_nonprod_scm 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_fa_gaviti_name_nonprod
  name: 'scm'
  location: 'Central US'
  properties: {
    allow: true
  }
  dependsOn: [
    sites_fa_gaviti_name_resource
  ]
}

resource sites_fa_gaviti_name_nonprod_web 'Microsoft.Web/sites/slots/config@2024-11-01' = {
  parent: sites_fa_gaviti_name_nonprod
  name: 'web'
  location: 'Central US'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'Python|3.12'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$fa-gaviti__nonprod'
    scmType: 'GitHubAction'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    functionAppScaleLimit: 0
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
    http20ProxyFlag: 0
  }
  dependsOn: [
    sites_fa_gaviti_name_resource
  ]
}

resource sites_fa_gaviti_name_nonprod_sites_fa_gaviti_name_nonprod_azurewebsites_net 'Microsoft.Web/sites/slots/hostNameBindings@2024-11-01' = {
  parent: sites_fa_gaviti_name_nonprod
  name: '${sites_fa_gaviti_name}-nonprod.azurewebsites.net'
  location: 'Central US'
  properties: {
    siteName: 'fa-gaviti(nonprod)'
    hostNameType: 'Verified'
  }
  dependsOn: [
    sites_fa_gaviti_name_resource
  ]
}

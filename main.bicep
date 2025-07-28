param sites_fa_gaviti_prod_name string = 'fa-gaviti-prod'
param serverfarms_sam_asp_prod_externalid string = '/subscriptions/07fa5c8a-e372-40c1-8794-4c29e70fd46e/resourceGroups/rg-SharedServices-Prod/providers/Microsoft.Web/serverfarms/sam-asp-prod'

resource sites_fa_gaviti_prod_name_resource 'Microsoft.Web/sites@2024-11-01' = {
  name: sites_fa_gaviti_prod_name
  location: 'Central US'
  tags: {
    'hidden-link: /app-insights-resource-id': '/subscriptions/07fa5c8a-e372-40c1-8794-4c29e70fd46e/resourceGroups/sam-gv-fa/providers/microsoft.insights/components/fa-gaviti'
  }
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${sites_fa_gaviti_prod_name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${sites_fa_gaviti_prod_name}.scm.azurewebsites.net'
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
      linuxFxVersion: 'PYTHON|3.12'
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: false
      functionAppScaleLimit: 100
      minimumElasticInstanceCount: 1
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientAffinityProxyEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    ipMode: 'IPv4'
    customDomainVerificationId: '36281436D3604480EB4A21CEB962157A2176ABC309EF1EA3039DFE133E25426A'
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    endToEndEncryptionEnabled: false
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
    sshEnabled: true
  }
}

resource sites_fa_gaviti_prod_name_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: 'ftp'
  properties: {
    allow: true
  }
}

resource sites_fa_gaviti_prod_name_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: 'scm'
 
  properties: {
    allow: true
  }
}

resource sites_fa_gaviti_prod_name_web 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: 'web'

   
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
    linuxFxVersion: 'PYTHON|3.12'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2022'
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$fa-gaviti-prod'
    scmType: 'GitHubAction'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    publicNetworkAccess: 'Enabled'
    cors: {
      allowedOrigins: [
        'https://portal.azure.com'
      ]
      supportCredentials: true
    }
    localMySqlEnabled: false
    managedServiceIdentityId: 17399
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
    functionAppScaleLimit: 100
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 1
    azureStorageAccounts: {}
    http20ProxyFlag: 0
  }
}

resource sites_fa_gaviti_prod_name_1f1cf783_31c4_4523_abc0_5d1b8839d7ec 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: '1f1cf783-31c4-4523-abc0-5d1b8839d7ec'
  
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"c05653341bfe05c7381b43a1b79230566c52bda6","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-07-23T21:09:43.9576449Z'
    end_time: '2025-07-23T21:09:47.8060233Z'
    active: false
  }
}

resource sites_fa_gaviti_prod_name_649e544d_ae2f_471a_9dfc_24f9091eb5a1 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: '649e544d-ae2f-471a-9dfc-24f9091eb5a1'

  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"64a38ac296170ea0cd9227c955db5e6af2538f70","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-07-23T18:50:29.6932525Z'
    end_time: '2025-07-23T18:50:59.5294781Z'
    active: false
  }
}

resource sites_fa_gaviti_prod_name_7c8fe415_c9fb_4787_9635_1c72a715be5c 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: '7c8fe415-c9fb-4787-9635-1c72a715be5c'
  
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"eae5e35df98a0cf3c893961d584b4cb50efadeb3","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-07-24T06:29:57.1208915Z'
    end_time: '2025-07-24T06:30:00.5814993Z'
    active: false
  }
}

resource sites_fa_gaviti_prod_name_83c844c9_802d_4009_abd5_aa89bd080c3f 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: '83c844c9-802d-4009-abd5-aa89bd080c3f'
 
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"5e5e3f4442dbfcc194753a0e756146be33d9e4d8","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-07-25T17:26:08.7476396Z'
    end_time: '2025-07-25T17:26:12.6038037Z'
    active: true
  }
}

resource sites_fa_gaviti_prod_name_d59cc1ad_b296_487e_87b3_cbc2db3c8e19 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: 'd59cc1ad-b296-487e-87b3-cbc2db3c8e19'
 
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"64a38ac296170ea0cd9227c955db5e6af2538f70","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-07-23T19:19:18.383495Z'
    end_time: '2025-07-23T19:19:34.9496013Z'
    active: false
  }
}

resource sites_fa_gaviti_prod_name_CashSyncToGP 'Microsoft.Web/sites/functions@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: 'CashSyncToGP'
 
  properties: {
    script_root_path_href: 'https://fa-gaviti-prod.azurewebsites.net/admin/vfs/home/site/wwwroot/CashSyncToGP/'
    script_href: 'https://fa-gaviti-prod.azurewebsites.net/admin/vfs/home/site/wwwroot/CashSyncToGP/__init__.py'
    config_href: 'https://fa-gaviti-prod.azurewebsites.net/admin/vfs/home/site/wwwroot/CashSyncToGP/function.json'
    test_data_href: 'https://fa-gaviti-prod.azurewebsites.net/admin/vfs/home/data/Functions/sampledata/CashSyncToGP.dat'
    href: 'https://fa-gaviti-prod.azurewebsites.net/admin/functions/CashSyncToGP'
    config: {
      scriptFile: '__init__.py'
      bindings: [
        {
          name: 'mytimer'
          type: 'timerTrigger'
          direction: 'in'
          schedule: '0 0 * * * *'
        }
      ]
    }
    language: 'python'
    isDisabled: false
  }
}

resource sites_fa_gaviti_prod_name_InvoiceUpload 'Microsoft.Web/sites/functions@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: 'InvoiceUpload'

  properties: {
    script_root_path_href: 'https://fa-gaviti-prod.azurewebsites.net/admin/vfs/home/site/wwwroot/InvoiceUpload/'
    script_href: 'https://fa-gaviti-prod.azurewebsites.net/admin/vfs/home/site/wwwroot/InvoiceUpload/__init__.py'
    config_href: 'https://fa-gaviti-prod.azurewebsites.net/admin/vfs/home/site/wwwroot/InvoiceUpload/function.json'
    test_data_href: 'https://fa-gaviti-prod.azurewebsites.net/admin/vfs/home/data/Functions/sampledata/InvoiceUpload.dat'
    href: 'https://fa-gaviti-prod.azurewebsites.net/admin/functions/InvoiceUpload'
    config: {
      scriptFile: '__init__.py'
      bindings: [
        {
          name: 'inputBlob'
          type: 'blobTrigger'
          direction: 'in'
          path: 'invoices-incoming/{name}'
          connection: 'AzureWebJobsStorage'
        }
      ]
    }
    language: 'python'
    isDisabled: false
  }
}

resource sites_fa_gaviti_prod_name_sites_fa_gaviti_prod_name_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: '${sites_fa_gaviti_prod_name}.azurewebsites.net'

  properties: {
    siteName: 'fa-gaviti'
    hostNameType: 'Verified'
  }
}

resource sites_fa_gaviti_prod_name_nonprod 'Microsoft.Web/sites/slots@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_resource
  name: 'nonprod'
  location: 'Central US'
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: 'fa-gaviti-prod-nonprod.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: 'fa-gaviti-prod-nonprod.scm.azurewebsites.net'
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
      linuxFxVersion: 'PYTHON|3.12'
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: false
      functionAppScaleLimit: 100
      minimumElasticInstanceCount: 1
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
    sshEnabled: true
  }
}

resource sites_fa_gaviti_prod_name_nonprod_ftp 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_nonprod
  name: 'ftp'
  
  properties: {
    allow: true
  }
}

resource sites_fa_gaviti_prod_name_nonprod_scm 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_nonprod
  name: 'scm'
 
  properties: {
    allow: true
  }
  dependsOn: [
  ]
}

resource sites_fa_gaviti_prod_name_nonprod_web 'Microsoft.Web/sites/slots/config@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_nonprod
  name: 'web'

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
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'PYTHON|3.12'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2022'
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$fa-gaviti-prod__nonprod'
    scmType: 'GitHubAction'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    publicNetworkAccess: 'Enabled'
    localMySqlEnabled: false
    managedServiceIdentityId: 17400
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
    functionAppScaleLimit: 100
    healthCheckPath: '/health'
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 1
    azureStorageAccounts: {}
    http20ProxyFlag: 0
  }
  dependsOn: [
   
  ]
}

resource sites_fa_gaviti_prod_name_nonprod_75071cc9_de72_4351_8313_55f0e5c46dc5 'Microsoft.Web/sites/slots/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_nonprod
  name: '75071cc9-de72-4351-8313-55f0e5c46dc5'

  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"eae5e35df98a0cf3c893961d584b4cb50efadeb3","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-07-24T06:29:54.680648Z'
    end_time: '2025-07-24T06:29:58.1344173Z'
    active: false
  }
  dependsOn: [
   
  ]
}

resource sites_fa_gaviti_prod_name_nonprod_794d7284_715c_4346_bb02_a292532959da 'Microsoft.Web/sites/slots/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_nonprod
  name: '794d7284-715c-4346-bb02-a292532959da'
  
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"5e5e3f4442dbfcc194753a0e756146be33d9e4d8","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-07-25T17:26:08.1139626Z'
    end_time: '2025-07-25T17:26:11.6930027Z'
    active: true
  }
  dependsOn: [
  
  ]
}

resource sites_fa_gaviti_prod_name_nonprod_fe5dce92_fe15_49b6_8274_0a60979ea1e4 'Microsoft.Web/sites/slots/deployments@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_nonprod
  name: 'fe5dce92-fe15-49b6-8274-0a60979ea1e4'

  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'GITHUB_ZIP_DEPLOY_FUNCTIONS_V1'
    message: '{"type":"deployment","sha":"c05653341bfe05c7381b43a1b79230566c52bda6","repoName":"sellars-absorbents/fa-gaviti","actor":"alisowskisellars","slotName":"production"}'
    start_time: '2025-07-23T21:09:43.6825762Z'
    end_time: '2025-07-23T21:09:47.259974Z'
    active: false
  }
  dependsOn: [
   
  ]
}

resource sites_fa_gaviti_prod_name_nonprod_CashSyncToGP 'Microsoft.Web/sites/slots/functions@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_nonprod
  name: 'CashSyncToGP'
  
  properties: {
    script_root_path_href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/vfs/home/site/wwwroot/CashSyncToGP/'
    script_href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/vfs/home/site/wwwroot/CashSyncToGP/__init__.py'
    config_href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/vfs/home/site/wwwroot/CashSyncToGP/function.json'
    test_data_href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/vfs/home/data/Functions/sampledata/CashSyncToGP.dat'
    href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/functions/CashSyncToGP'
    config: {
      scriptFile: '__init__.py'
      bindings: [
        {
          name: 'mytimer'
          type: 'timerTrigger'
          direction: 'in'
          schedule: '0 0 * * * *'
        }
      ]
    }
    language: 'python'
    isDisabled: false
  }
  dependsOn: [
    
  ]
}

resource sites_fa_gaviti_prod_name_nonprod_InvoiceUpload 'Microsoft.Web/sites/slots/functions@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_nonprod
  name: 'InvoiceUpload'

  properties: {
    script_root_path_href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/vfs/home/site/wwwroot/InvoiceUpload/'
    script_href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/vfs/home/site/wwwroot/InvoiceUpload/__init__.py'
    config_href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/vfs/home/site/wwwroot/InvoiceUpload/function.json'
    test_data_href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/vfs/home/data/Functions/sampledata/InvoiceUpload.dat'
    href: 'https://fa-gaviti-prod-nonprod.azurewebsites.net/admin/functions/InvoiceUpload'
    config: {
      scriptFile: '__init__.py'
      bindings: [
        {
          name: 'inputBlob'
          type: 'blobTrigger'
          direction: 'in'
          path: 'invoicesincoming/{name}'
          connection: 'AzureWebJobsStorage'
        }
      ]
    }
    language: 'python'
    isDisabled: false
  }
  dependsOn: [
   
  ]
}

resource sites_fa_gaviti_prod_name_nonprod_sites_fa_gaviti_prod_name_nonprod_azurewebsites_net 'Microsoft.Web/sites/slots/hostNameBindings@2024-11-01' = {
  parent: sites_fa_gaviti_prod_name_nonprod
  name: '${sites_fa_gaviti_prod_name}-nonprod.azurewebsites.net'

  properties: {
    siteName: 'fa-gaviti-prod(nonprod)'
    hostNameType: 'Verified'
  }
  dependsOn: [
   
  ]
}

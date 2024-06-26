# This file enables modules to be automatically managed by the Functions service.
# See https://aka.ms/functionsmanageddependency for additional information.
#
@{
    # For latest supported version, go to 'https://www.powershellgallery.com/packages/Az'. 
    # To use the Az module in your function app, please uncomment the line below.
    'Az.accounts'  = '2.*'
    'Az.Keyvault'  = '3.*'
    'Az.functions' = '3.*'
    'SimplySql'    = '1.9.0'
    'Az.Resources' = '5.*'
    'Az.Storage'   = '4.*'
    'AzTable'      = '2.*'
    'AzBobbyTables' = '2.*'
}

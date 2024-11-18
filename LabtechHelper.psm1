Import-Module SimplySql
# function Get-LabtechClientId($TenantFilter) { 
#     # get cwm id
#     $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#     $headers.Add("clientId", $ENV:CwmClientId)
#     $headers.Add("Content-Type", "application/json")
#     $headers.Add("Authorization", $ENV:CwManage)
#     $clientId = (Invoke-RestMethod "https://api-na.myconnectwise.net/v4_6_release/apis/3.0/company/companies?conditions=userDefinedField10='$($TenantFilter)'&fields=id" -Method 'GET' -Headers $headers).id 

#     # get cwa id
#     $null = Connect-AzAccount -Identity
#     $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
#     $cwaHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#     $cwaHeaders.Add("Authorization", "Bearer $token")
#     $cwaHeaders.Add("ClientId", $ENV:CwaClientId)
#     $cwaHeaders.Add("Content-Type", "application/json")
#     $cwaClientId = (Invoke-RestMethod "https://labtech.radersolutions.com/cwa/api/v1/clients?condition=externalid=$($clientId)" -Method 'GET' -Headers $cwaHeaders).id
#     if ($cwaClientId -eq 291) {
#         $cwaClientId = 1
#     }
#     return $cwaClientId
# }

# Sample JSON data

# Function to find an entry by Name and return cw_automate_client_id
# Revised Get-ClientIdByTenantId Function (previously Get-ClientIdByName)
function Get-ClientIdByTenantId {
    param (
        [string]$tenantId  # Accepts the tenant ID to search for
    )
    
    # Assuming $env:CompaniesArray is a JSON string passed into the environment
    $jsonData = $env:CompaniesArray

    # Convert the JSON to an array of PowerShell objects
    $data = $jsonData | ConvertFrom-Json
    
    # Create an array to hold selected hash table entries
    $hashTableData = @()
    foreach ($item in $data) {
        $hashTableData += @{
            Name                       = $item.Name
            Domain                     = $item.Domain
            cw_automate_client_id      = $item.cw_automate_client_id
            cw_manage_company_id       = $item.cw_manage_company_id
            tenant_id                  = $item.tenant_id  # Assuming tenant_id exists in the JSON data
        }
    }

    # Search the hashTableData for a matching entry based on 'tenant_id'
    $matchedEntry = $hashTableData | Where-Object { $_.tenant_id -eq $tenantId }

    if ($matchedEntry) {
        return $matchedEntry.cw_manage_company_id  # Return the cw_manage_company_id associated with tenant_id
    } else {
        Write-Output "No entry found with the tenant ID '$tenantId'."
        return $null
    }
}
# Revised Get-LabtechServerId Function/LOCAL
function Get-LabtechClientId {
    param (
        [string]$TenantFilter  # Tenant ID to filter and search the associated client ID
    )
    try {
        # Retrieve CompaniesArray JSON from environment variable
        $jsonData = $env:CompaniesArray

        if (-not $jsonData) {
            Write-Error "Environment variable 'CompaniesArray' is not set or is empty."
            return $null
        }

        # Convert the JSON to an array of PowerShell objects
        $data = $jsonData | ConvertFrom-Json

        # Search for the entry matching the provided Tenant ID
        $matchedEntry = $data | Where-Object { $_.tenant_id -eq $TenantFilter }

        if ($matchedEntry) {
            # Retrieve the cw_automate_client_id for the matching entry
            $cwaClientId = $matchedEntry.cw_automate_client_id

            Write-Host "CWA Automate Client ID: $cwaClientId"

            # Handle special cases (e.g., Client ID 291)
            if ($cwaClientId -eq 291) {
                $cwaClientId = 1
            }

            return $cwaClientId
        } else {
            Write-Error "No entry found for Tenant ID: $TenantFilter."
            return $null
        }
    }
    catch {
        Write-Error "Error in Get-LabtechClientId: $_"
        return $null
    }
}

# # Revised Get-LabtechClientId Function
# function Get-LabtechClientId {
#     param (
#         [string]$TenantFilter  # Tenant ID to filter and search the associated client ID
#     )
#     try {
#         Write-Host "CwmClientId: $ENV:CwmClientId"
#         Write-Host "CwManage: $ENV:CwManage"

#         # Get client ID from JSON data via Get-ClientIdByTenantId
#         $clientId = Get-ClientIdByTenantId -tenantId $TenantFilter
#         if (-not $clientId) {
#             Write-Error "Client ID not found for tenant ID: $TenantFilter"
#             return $null
#         }
#         write-host "Customer/Client ID: $clientId"
#         # Fetch token for the Automate API call
#         $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
#         write-host "Token/LabtechHelper/cwaRefreshToken: $token"
#         $cwaHeaders = @{
#             "Authorization" = "Bearer $token"
#             "ClientId"      = $ENV:CwaClientId
#             "Content-Type"  = "application/json"
#         }

#         try {
#             # Make the Automate API call with the retrieved client ID
#             $cwaResponse = Invoke-RestMethod -Uri "https://labtech.radersolutions.com/cwa/api/v1/clients?condition=externalid=$($clientId)" -Method 'GET' -Headers $cwaHeaders
#             Write-Host "Formatted CWA Response:"
#             Write-Host ($cwaResponse | ConvertTo-Json -Depth 10)
#         }
#         catch {
#             # Handle Unauthorized error and refresh the token
#             if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) {
#                 Write-Host "Refreshing Token..."
#                 $null = Connect-AzAccount -Identity
#                 $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
#                 $cwaRefreshTokenHeaders = @{
#                     "Authorization" = "Bearer $token"
#                     "ClientId"      = $ENV:CwaClientId
#                     "Content-Type"  = "application/json"
#                 }
#                 $tokenBody = "`"$token`""
                
#                 $cwaToken = Invoke-RestMethod 'https://labtech.radersolutions.com/cwa/api/v1/apitoken/refresh' -Method 'POST' -Headers $cwaRefreshTokenHeaders -Verbose -Body $tokenBody
#                 $cwaTokenSecret = ConvertTo-SecureString $cwaToken.AccessToken -AsPlainText -Force
#                 Set-AzKeyVaultSecret -VaultName "cipphglzr" -Name "cwaRefreshToken" -SecretValue $cwaTokenSecret -ContentType "text/plain"
                
#                 # Retry the request with the new token
#                 $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
#                 $cwaHeaders["Authorization"] = "Bearer $token"
#                 $cwaResponse = Invoke-RestMethod -Uri "https://labtech.radersolutions.com/cwa/api/v1/clients?condition=externalid=$($clientId)" -Method 'GET' -Headers $cwaHeaders
#             } else {
#                 throw $_
#             }
#         }

#         $cwaClientId = $cwaResponse.id
#         Write-Host "CWA ID: $cwaClientId"

#         # Special handling for specific Client ID (e.g., 291)
#         if ($cwaClientId -eq 291) {
#             $cwaClientId = 1
#         }
#         return $cwaClientId
#     }
#     catch {
#         Write-Error "Error in Get-LabtechClientId: $_"
#         return $null
#     }
# }



# ORIGINAL
# function Get-LabtechClientId($TenantFilter) {
#     try {
#         write-host "CwmClientId"
#         write-host $ENV:CwmClientId
#         write-host "CwManage"
#         write-host $ENV:CwManage
#         $headers = @{
#             "clientId"      = $ENV:CwmClientId
#             "Content-Type"  = "application/json"
#             "Authorization" = $ENV:CwManage
           
#         }
#         $response = Invoke-RestMethod -Uri "https://api-na.myconnectwise.net/v4_6_release/apis/3.0/company/companies?conditions=userDefinedField10='$($TenantFilter)'&fields=id" -Method 'GET' -Headers $headers
#         if ($response -is [array] -and $response.Count -gt 1) {
#             $clientId = $response[0].id
#             Write-Host "Response is an array. First ID is: $clientId"
#         } else {
#             $clientId = $response.id
#             Write-Host "Response is not an array or has only one item. ID is: $clientId"
#         }
        
#         $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
#         write-host "token/LabtechHelper/cwaRefreshToken"
#         write-host "cwaClientId"
#         write-host $ENV:CwaClientId
#         write-host "token/LabtechHelper/cwaRefreshToken"
#         write-host $token
#         $cwaHeaders = @{
#             "Authorization" = "Bearer $token"
#             "ClientId"      = $ENV:CwaClientId
#             "Content-Type"  = "application/json"
#         }
        
#         try {
#             $cwaResponse = Invoke-RestMethod -Uri "https://labtech.radersolutions.com/cwa/api/v1/clients?condition=externalid=$($clientId)" -Method 'GET' -Headers $cwaHeaders
#             write-host "token"
#             write-host $token
#             write-host "CWA RESP"
#             write-host $cwaResponse
#             Write-Host "Formatted CWA Response:"
#             Write-Host ($cwaResponse | ConvertTo-Json -Depth 10)

#         }
#         catch {
#             if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) {
#                 # Refresh the token
#                 $null = Connect-AzAccount -Identity
#                 $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
#                 $cwaRefreshTokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#                 $cwaRefreshTokenHeaders.Add("Authorization", "Bearer $token")
#                 $cwaRefreshTokenHeaders.Add("ClientId", $ENV:CwaClientId)
#                 $cwaRefreshTokenHeaders.Add("Content-Type", "application/json")
#                 $tokenBody = "`"$token`""
                
#                 $cwaToken = Invoke-RestMethod 'https://labtech.radersolutions.com/cwa/api/v1/apitoken/refresh' -Method 'POST' -Headers $cwaRefreshTokenHeaders -Verbose -Body $tokenBody
#                 $cwaTokenSecret = ConvertTo-SecureString $cwaToken.AccessToken -AsPlainText -Force
#                 Set-AzKeyVaultSecret -VaultName "cipphglzr" -Name "cwaRefreshToken" -SecretValue $cwaTokenSecret -ContentType "text/plain"
                
#                 # Retry the request with the new token
#                 $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
#                 $cwaHeaders["Authorization"] = "Bearer $token"
#                 $cwaResponse = Invoke-RestMethod -Uri "https://labtech.radersolutions.com/cwa/api/v1/clients?condition=externalid=$($clientId)" -Method 'GET' -Headers $cwaHeaders
#             } else {
#                 throw $_
#             }
#         }

#         $cwaClientId = $cwaResponse.id
#         write-host "CWA ID"
#         write-host $cwaClientId

#         if ($cwaClientId -eq 291) {
#             $cwaClientId = 1
#         }
#         return $cwaClientId
#     }
#     catch {
#         Write-Error "Error in Get-LabtechClientId: $_"
#         write-host $clientId
#         write-host "CWA RESP"
#         write-host $cwaResponse
#         return $null
#     }
# }

function Get-LabtechServerId($ClientId) { 
    Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
    $table = Invoke-SqlQuery -Query "SELECT computerid FROM labtech.computers where name like '%ratel%' and name not like '%sz%' and clientId = $ClientId limit 1"
    return $table.computerid
    Close-SqlConnection
    # #return crl ratel for testing
    # return 10600
}


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
function Get-LabtechClientId($TenantFilter) { 
    try {
        $headers = @{
            "clientId"      = $ENV:CwmClientId
            "Content-Type"  = "application/json"
            "Authorization" = $ENV:CwManage
        }
        $response = Invoke-RestMethod -Uri "https://api-na.myconnectwise.net/v4_6_release/apis/3.0/company/companies?conditions=userDefinedField10='$($TenantFilter)'&fields=id" -Method 'GET' -Headers $headers
        $clientId = $response.id 

        $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
        $cwaHeaders = @{
            "Authorization" = "Bearer $token"
            "ClientId"      = $ENV:CwaClientId
            "Content-Type"  = "application/json"
        }
        $cwaResponse = Invoke-RestMethod -Uri "https://labtech.radersolutions.com/cwa/api/v1/clients?condition=externalid=$($clientId)" -Method 'GET' -Headers $cwaHeaders
        $cwaClientId = $cwaResponse.id

        # Handle special condition
        if ($cwaClientId -eq 291) {
            $cwaClientId = 1
        }

        return $cwaClientId
    }
    catch {
        Write-Error "Error in Get-LabtechClientId: $_"
        return $null
    }
}


function Get-LabtechServerId($ClientId){ 
    Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
    $table = Invoke-SqlQuery -Query "SELECT computerid FROM labtech.computers where name like '%ratel%' and name not like '%sz%' and clientId = $ClientId limit 1"
    return $table.computerid
    Close-SqlConnection
    # #return crl ratel for testing
    # return 10600
}


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
        if ($response -is [array] -and $response.Count -gt 1) {
            $clientId = $response[0].id
            Write-Host "Response is an array. First ID is: $clientId"
        } else {
            $clientId = $response.id
            Write-Host "Response is not an array or has only one item. ID is: $clientId"
        }
        
        $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
        $cwaHeaders = @{
            "Authorization" = "Bearer $token"
            "ClientId"      = $ENV:CwaClientId
            "Content-Type"  = "application/json"
        }
        
        try {
            $cwaResponse = Invoke-RestMethod -Uri "https://labtech.radersolutions.com/cwa/api/v1/clients?condition=externalid=$($clientId)" -Method 'GET' -Headers $cwaHeaders
            write-host "CWA RESP"
            write-host $cwaResponse
            Write-Host "Formatted CWA Response:"
            Write-Host ($cwaResponse | ConvertTo-Json -Depth 10)

        }
        catch {
            if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) {
                # Refresh the token
                $null = Connect-AzAccount -Identity
                $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
                $cwaRefreshTokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $cwaRefreshTokenHeaders.Add("Authorization", "Bearer $token")
                $cwaRefreshTokenHeaders.Add("ClientId", $ENV:CwaClientId)
                $cwaRefreshTokenHeaders.Add("Content-Type", "application/json")
                $tokenBody = "`"$token`""
                
                $cwaToken = Invoke-RestMethod 'https://labtech.radersolutions.com/cwa/api/v1/apitoken/refresh' -Method 'POST' -Headers $cwaRefreshTokenHeaders -Verbose -Body $tokenBody
                $cwaTokenSecret = ConvertTo-SecureString $cwaToken.AccessToken -AsPlainText -Force
                Set-AzKeyVaultSecret -VaultName "cipphglzr" -Name "cwaRefreshToken" -SecretValue $cwaTokenSecret -ContentType "text/plain"
                
                # Retry the request with the new token
                $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
                $cwaHeaders["Authorization"] = "Bearer $token"
                $cwaResponse = Invoke-RestMethod -Uri "https://labtech.radersolutions.com/cwa/api/v1/clients?condition=externalid=$($clientId)" -Method 'GET' -Headers $cwaHeaders
            } else {
                throw $_
            }
        }

        $cwaClientId = $cwaResponse.id
        write-host "CWA ID"
        write-host $cwaClientId

        if ($cwaClientId -eq 291) {
            $cwaClientId = 1
        }
        return $cwaClientId
    }
    catch {
        Write-Error "Error in Get-LabtechClientId: $_"
        write-host $clientId
        write-host "CWA RESP"
        write-host $cwaResponse
        return $null
    }
}

function Get-LabtechServerId($ClientId) { 
    Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
    $table = Invoke-SqlQuery -Query "SELECT computerid FROM labtech.computers where name like '%ratel%' and name not like '%sz%' and clientId = $ClientId limit 1"
    return $table.computerid
    Close-SqlConnection
    # #return crl ratel for testing
    # return 10600
}


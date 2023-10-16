Import-Module SimplySql
function Get-LabtechClientId($TenantFilter) { 
    # get cwm id
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("clientId", $ENV:CwmClientId)
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", $ENV:CwManage)
    $clientId = (Invoke-RestMethod "https://api-na.myconnectwise.net/v4_6_release/apis/3.0/company/companies?conditions=userDefinedField10='$($TenantFilter)'&fields=id" -Method 'GET' -Headers $headers).id 

    # get cwa id
    $null = Connect-AzAccount -Identity
    $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
    $cwaHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $cwaHeaders.Add("Authorization", "Bearer $token")
    $cwaHeaders.Add("ClientId", $ENV:CwaClientId)
    $cwaHeaders.Add("Content-Type", "application/json")
    $cwaClientId = (Invoke-RestMethod "https://labtech.radersolutions.com/cwa/api/v1/clients?condition=externalid=$($clientId)" -Method 'GET' -Headers $cwaHeaders).id
    return $cwaClientId
}

function Get-LabtechServerId($ClientId){ 
    Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
    $table = Invoke-SqlQuery -Query "SELECT computerid FROM labtech.computers where name like '%ratel%' and name not like '%sz%' and clientId = $ClientId limit 1"
    return $table.computerid
    Close-SqlConnection
    # #return crl ratel for testing
    # return 10600
}

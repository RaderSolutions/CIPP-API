using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
# $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# get cwm id
$TenantFilter = $Request.body.TenantFilter

$cwaClientId = Get-LabtechClientId($TenantFilter)
write-host "cwaClientId $cwaClientId"
# Get Automate Auth Token
$null = Connect-AzAccount -Identity

$entryObj = $Request.body
write-host $cwaClientId
write-host 'entryObj/license'
write-host $entryObj.LicenseKey
try {
    Invoke-SqlQuery -Query @"
    INSERT INTO labtech.plugin_rader_ratel_configuration (client_id,parameter,value) 
    VALUES ('$($cwaClientId)','dpma_license_key','$($Request.body.LicenseKey)') 
    ON DUPLICATE KEY UPDATE VALUE='$($Request.body.LicenseKey)'; 
"@    
    $body = @{"Results" = "DPMA License Applied" }

} 
catch { 
    $body = @{"Results" = "Something went wrong."
  
    }
    write-host $_.Exception
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })

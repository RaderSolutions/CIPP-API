using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# get cwm id
$TenantFilter = $Request.body.TenantFilter
$cwaClientId = Get-LabtechClientId($TenantFilter)
write-host "cwaClientId $cwaClientId"
# Get Automate Auth Token
$null = Connect-AzAccount -Identity
# $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
try {
    if ($Request.Query.Action -eq "Delete") { 
        Invoke-SqlQuery -Query "DELETE FROM plugin_rader_ratel_pickupgroups WHERE client_id=$cwaClientId AND extension=$($Request.Query.Extension) AND membership_type=$($Request.Query.Type) AND group_name=$($Request.Query.Groups) LIMIT 1;
        UPDATE plugin_rader_ratel_device SET is_sync_scheduled=1 WHERE client_id=$cwaClientId AND extension_number=$($Request.Query.Extension);"
    }
    else { 
        write-host "add entry client id: $cwaClientId"
#      $pickupGroupObj = $Request.body
# Invoke-SqlQuery -Query @"
# INSERT INTO plugin_rader_ratel_pickupgroups 
# (client_id, extension, membership_type, group_name) 
# VALUES (
#    '$($cwaClientId)',
#    '$($pickupGroupObj.Extension)',
#    '$($pickupGroupObj.Type)',
#    '$($pickupGroupObj.Groups)'
# );

# UPDATE plugin_rader_ratel_device 
# SET is_sync_scheduled=1 
# WHERE client_id='$($cwaClientId)' AND extension_number='$($pickupGroupObj.Extension)';
# "@

    }
    $body = @{"Results" = "PickupGroup modifications stored in database" }

} 
catch { 
    $body = @{"Results" = "Something went wrong." }
    write-host $_.Exception
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })

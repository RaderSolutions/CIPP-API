using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# get cwm id
write-host "request body: "
write-host $Request.body 
write-host $Request.body | ConvertTo-Json
$TenantFilter = $Request.body.TenantFilter
$cwaClientId = Get-LabtechClientId($TenantFilter)
write-host "cwaClientId $cwaClientId"
# Get Automate Auth Token
$null = Connect-AzAccount -Identity
# $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
try {
    if ($Request.body.Action -eq "Delete") {
        write-host "delete entry"
        
        $extension = $Request.body.Extension
        $type = $Request.body.Type
        $groups = $Request.body.Groups
        write-host "client id: $cwaClientId"
        Write-Host "Extension: $extension"
        Write-Host "Type: $type"
        Write-Host "Groups: $groups"
        Invoke-SqlQuery -Query "DELETE FROM labtech.plugin_rader_ratel_pickupgroups WHERE client_id='$cwaClientId' AND extension='$($extension)' AND membership_type='$($type)' AND group_name='$($groups)' LIMIT 1; UPDATE labtech.plugin_rader_ratel_device SET is_sync_scheduled=1 WHERE client_id='$cwaClientId' AND extension_number='$($Request.Query.Extension)';"
    }
    elseif ($Request.body.Action -eq "Edit") {
        $pickupGroupObj = $Request.body
        write-host ""
        Invoke-SqlQuery -Query @"
        UPDATE labtech.plugin_rader_ratel_pickupgroups 
        SET group_name = '$($pickupGroupObj.Groups)',
        membership_type = '$($pickupGroupObj.Type)',
        extension = '$($pickupGroupObj.Extension)',
        is_sync_scheduled = '$($pickupGroupObj.IsSyncScheduled)'
        WHERE id='$($pickupGroupObj.ID)' AND client_id=$cwaClientId LIMIT 1;
        UPDATE labtech.plugin_rader_ratel_device WHERE client_id='$cwaClientId' AND extension_number='$($pickupGroupObj.Extension)';
"@
    }
    else { 
        write-host "add entry client id: $cwaClientId"
        write-host "extension: $($Request.body.extension)"
        write-host "type: $($Request.body.type)"
        write-host "groups: $($Request.body.groups)"
        $pickupGroupObj = $Request.body
        Invoke-SqlQuery -Query @"
        INSERT INTO labtech.plugin_rader_ratel_pickupgroups 
        (client_id, extension, membership_type, group_name, is_sync_scheduled) 
        VALUES (
        '$($cwaClientId)',
        '$($pickupGroupObj.Extension)',
        '$($pickupGroupObj.Type)',
        '$($pickupGroupObj.Groups)',
        '$($pickupGroupObj.IsSyncScheduled)'
        );

        UPDATE labtech.plugin_rader_ratel_device 
        SET is_sync_scheduled=1 
        WHERE client_id='$($cwaClientId)' AND extension_number='$($pickupGroupObj.Extension)';
"@

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

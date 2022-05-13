using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

Import-Module SimplySql
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# get cwm id
$requestJson = $Request | convertto-json
$TenantFilter = $Request.Query.TenantFilter
$cwaClientId = Get-LabtechClientId($TenantFilter)

write-host $Request.Query.DidNumber
if($Request.Query.DidNumber) {
    write-host "here" 
$did = $Request.Query.DidNumber
$table = Invoke-SqlQuery -Query "SELECT plugin_rader_ratel_did.number AS Number, 
plugin_rader_ratel_device.extension_number AS Extension, 
plugin_rader_ratel_did.device_id AS 'DeviceId',
contacts.FirstName, 
contacts.LastName, 
plugin_rader_ratel_did.custom_dialplan as Dialplan,
plugin_rader_ratel_did.notes as 'Description', 
plugin_rader_ratel_did.is_device_callerid as 'IsDeviceCallerId', 
plugin_rader_ratel_did.is_sync_scheduled AS 'NeedsSync'
FROM plugin_rader_ratel_did 
LEFT JOIN plugin_rader_ratel_device ON plugin_rader_ratel_did.device_id=plugin_rader_ratel_device.id 
LEFT JOIN contacts ON plugin_rader_ratel_device.contact_id=contacts.ContactID 
WHERE plugin_rader_ratel_did.client_id=$cwaClientId and Number='$did'"
}
else { 
$table = Invoke-SqlQuery -Query "SELECT 
plugin_rader_ratel_did.number AS Number, 
plugin_rader_ratel_device.extension_number AS Extension, 
plugin_rader_ratel_did.device_id AS 'DeviceId',
contacts.FirstName, 
contacts.LastName, 
plugin_rader_ratel_did.notes as 'Description', 
plugin_rader_ratel_did.is_device_callerid as 'IsDeviceCallerId',
plugin_rader_ratel_did.is_sync_scheduled AS 'NeedsSync'
FROM 
plugin_rader_ratel_did 
LEFT JOIN 
plugin_rader_ratel_device ON plugin_rader_ratel_did.device_id=plugin_rader_ratel_device.id 
LEFT JOIN 
contacts ON plugin_rader_ratel_device.contact_id=contacts.ContactID
WHERE  
plugin_rader_ratel_did.client_id=$cwaClientId" -AsDataTable
}

$dids = $table | Select-Object * -ExcludeProperty RowError,RowState,Table,ItemArray,HasErrors 
Close-SqlConnection
write-output $dids
$didArray = @()
$result
if($dids.count -eq 1 -and $null -eq $did) { 
    $didArray += $dids
    $result = $didArray
} else { 
    $result = $dids | convertto-json
}
write-output $result
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })

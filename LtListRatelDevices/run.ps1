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
write-host $TenantFilter
$cwaClientId = Get-LabtechClientId($TenantFilter)
write-host $cwaClientId
# if ($cwaClientId -eq 291) {
#     $cwaClientId = 1
# }
if($Request.Query.DeviceID){
    $deviceId=$Request.Query.DeviceID
    write-host $deviceId
    $table = Invoke-SqlQuery -Query "SELECT 
        labtech.plugin_rader_ratel_device.id AS 'DeviceId',
        mac_address AS 'MacAddress', 
        extension_number AS 'ExtensionNumber', 
        COALESCE(CONCAT(contacts.FirstName,' ',contacts.LastName),label) AS Label, 
        COALESCE(contacts.email,email_address) AS 'EmailAddress', 
        contact_id AS 'ContactID', 
        locations.Name AS Location,
        locations.locationId AS LocationId,
        labtech.plugin_rader_ratel_product.id AS ProductId,
        CONCAT(labtech.plugin_rader_ratel_product.manufacturer_name,' ',labtech.plugin_rader_ratel_product.model) AS Model, 
        GROUP_CONCAT(plugin_rader_ratel_did.number) AS 'DidNumber', 
        fop_group as 'FopGroup',
        labtech.plugin_rader_ratel_device.is_hidden_in_phonebook AS 'HideFromPhonebook',
        labtech.plugin_rader_ratel_device.is_sync_scheduled AS 'NeedsSync',
        labtech.plugin_rader_ratel_device.last_sync AS 'LastSync', sip_password as 'SipPassword',
        SUBSTRING_INDEX(labtech.plugin_rader_ratel_astdb.astValue,':',1) AS 'IpAddress'
    FROM plugin_rader_ratel_device 
    LEFT JOIN 
        labtech.plugin_rader_ratel_product ON labtech.plugin_rader_ratel_product.id=labtech.plugin_rader_ratel_device.product_id 
    LEFT JOIN 
        contacts ON contacts.contactid=labtech.plugin_rader_ratel_device.contact_id 
    LEFT JOIN 
        locations ON locations.locationID=labtech.plugin_rader_ratel_device.location_id 
    LEFT JOIN 
        labtech.plugin_rader_ratel_did ON labtech.plugin_rader_ratel_did.device_id=labtech.plugin_rader_ratel_device.id 
    LEFT JOIN
        labtech.plugin_rader_ratel_astdb ON plugin_rader_ratel_astdb.client_id=labtech.plugin_rader_ratel_device.client_id AND labtech.plugin_rader_ratel_astdb.astFamily='SIP' AND
        labtech.plugin_rader_ratel_astdb.astKey=(CONCAT('Registry/',mac_address))
    WHERE 
        labtech.plugin_rader_ratel_device.client_id=$cwaClientId and labtech.plugin_rader_ratel_device.id=$deviceId
    GROUP BY 
        mac_address
    ORDER BY 
        labtech.plugin_rader_ratel_device.extension_number
" -AsDataTable
} else {
    write-host "client id : $cwaClientId"
    if ($cwaClientId -eq 291) {
        $cwaClientId = 1
    }
$table = Invoke-SqlQuery -Query "SELECT 
        labtech.plugin_rader_ratel_device.id AS 'DeviceId',
        mac_address AS 'MacAddress', 
        extension_number AS 'ExtensionNumber', 
        COALESCE(CONCAT(contacts.FirstName,' ',contacts.LastName),label) AS Label, 
        COALESCE(contacts.email,email_address) AS 'EmailAddress', 
        contact_id AS 'ContactID', 
        locations.Name AS Location,
        CONCAT(labtech.plugin_rader_ratel_product.manufacturer_name,' ',labtech.plugin_rader_ratel_product.model) AS Model, 
        GROUP_CONCAT(plugin_rader_ratel_did.number) AS 'DidNumber', 
        fop_group as 'FopGroup',
        labtech.plugin_rader_ratel_device.is_hidden_in_phonebook AS 'HideFromPhonebook',
        labtech.plugin_rader_ratel_device.is_sync_scheduled AS 'NeedsSync',
        labtech.plugin_rader_ratel_device.last_sync AS 'LastSync', sip_password as 'SipPassword',
        SUBSTRING_INDEX(plugin_rader_ratel_astdb.astValue,':',1) AS 'IpAddress'
    FROM labtech.plugin_rader_ratel_device 
    LEFT JOIN 
        labtech.plugin_rader_ratel_product ON labtech.plugin_rader_ratel_product.id=labtech.plugin_rader_ratel_device.product_id 
    LEFT JOIN 
        contacts ON contacts.contactid=labtech.plugin_rader_ratel_device.contact_id 
    LEFT JOIN 
        locations ON locations.locationID=labtech.plugin_rader_ratel_device.location_id 
    LEFT JOIN 
        labtech.plugin_rader_ratel_did ON labtech.plugin_rader_ratel_did.device_id=labtech.plugin_rader_ratel_device.id 
    LEFT JOIN
        labtech.plugin_rader_ratel_astdb ON labtech.plugin_rader_ratel_astdb.client_id=labtech.plugin_rader_ratel_device.client_id AND labtech.plugin_rader_ratel_astdb.astFamily='SIP' AND
        labtech.plugin_rader_ratel_astdb.astKey=(CONCAT('Registry/',mac_address))
    WHERE 
        labtech.plugin_rader_ratel_device.client_id=$cwaClientId
    GROUP BY 
        mac_address
    ORDER BY 
        labtech.plugin_rader_ratel_device.extension_number

" -AsDataTable 
}
$devices= $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
Close-SqlConnection

$deviceArray = @()
$result

if($devices.count -eq 1 -and $null -eq $deviceId) { 
    $deviceArray += $devices
    $result = $deviceArray
} else { 
    $result = $devices | convertto-json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })



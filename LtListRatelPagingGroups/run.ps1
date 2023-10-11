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
write-host $cwaClientId

if($Request.Query.MailboxId){
    $extensionId=$Request.Query.ExtensionId
    write-host $extensionId
    $table = Invoke-SqlQuery -Query "SELECT
    plugin_rader_ratel_pagegroups.pagegroup_extension AS 'Extension',
    plugin_rader_ratel_pagegroups.pagegroup_name AS 'PageGroupName',
    plugin_rader_ratel_device.id AS 'DeviceId',
    plugin_rader_ratel_device.extension_number AS 'DeviceExt',
    COALESCE(CONCAT(contacts.FirstName,' ',contacts.LastName),plugin_rader_ratel_device.label) AS 'User',
    locations.Name AS 'Location',
    plugin_rader_ratel_pagegroups.hidden_from_phonebook as 'HideFromPB'
    FROM 
    plugin_rader_ratel_pagegroups
    LEFT JOIN 
    plugin_rader_ratel_pagegroup_membership
    ON
    plugin_rader_ratel_pagegroup_membership.pagegroup_id=plugin_rader_ratel_pagegroups.id
    LEFT JOIN
    plugin_rader_ratel_device
    ON 
    plugin_rader_ratel_pagegroup_membership.device_id=plugin_rader_ratel_device.id
    LEFT JOIN
    contacts
    ON
    contacts.ContactID=plugin_rader_ratel_device.contact_id
    LEFT JOIN
    locations
    ON 
    locations.LocationID=plugin_rader_ratel_device.location_id
    WHERE 
    plugin_rader_ratel_pagegroups.client_id=$cwaClientId and plugin_rader_ratel_pagegroups.pagegroup_extension=$extensionId
    
    ORDER BY 
    plugin_rader_ratel_pagegroups.pagegroup_name
    " -AsDataTable 
} else {
$table = Invoke-SqlQuery -Query "SELECT
plugin_rader_ratel_pagegroups.pagegroup_extension AS 'Extension',
plugin_rader_ratel_pagegroups.pagegroup_name AS 'PageGroupName',
plugin_rader_ratel_device.id AS 'DeviceId',
plugin_rader_ratel_device.extension_number AS 'DeviceExt',
COALESCE(CONCAT(contacts.FirstName,' ',contacts.LastName),plugin_rader_ratel_device.label) AS 'User',
locations.Name AS 'Location',
plugin_rader_ratel_pagegroups.hidden_from_phonebook as 'HideFromPB'
# FROM 
# plugin_rader_ratel_pagegroup_membership
# LEFT JOIN 
# plugin_rader_ratel_pagegroups
ON
plugin_rader_ratel_pagegroup_membership.pagegroup_id=plugin_rader_ratel_pagegroups.id
LEFT JOIN
plugin_rader_ratel_device
ON 
plugin_rader_ratel_pagegroup_membership.device_id=plugin_rader_ratel_device.id
LEFT JOIN
contacts
ON
contacts.ContactID=plugin_rader_ratel_device.contact_id
LEFT JOIN
locations
ON 
locations.LocationID=plugin_rader_ratel_device.location_id
WHERE 
plugin_rader_ratel_pagegroups.client_id=$cwaClientId

ORDER BY 
plugin_rader_ratel_pagegroups.pagegroup_name
" -AsDataTable 
}
$pagingGroups= $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
Close-SqlConnection

$pagingGroupArray = @()
$result

if($pagingGroups.count -eq 1 -and $null -eq $extensionId) { 
    $pagingGroupArray += $pagingGroups
    $result = $pagingGroupArray
} else { 
    $result = $pagingGroups | convertto-json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })



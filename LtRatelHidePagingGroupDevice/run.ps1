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
try {
Invoke-SqlQuery -Query @"
SELECT
plugin_rader_ratel_pagegroups.pagegroup_extension AS 'Extension',
plugin_rader_ratel_pagegroups.pagegroup_name AS 'PageGroup Name',
plugin_rader_ratel_device.id AS 'Device ID',
plugin_rader_ratel_device.extension_number AS 'Device Ext',
COALESCE(CONCAT(contacts.FirstName,' ',contacts.LastName),plugin_rader_ratel_device.label) AS 'User',
locations.Name AS 'Location',
plugin_rader_ratel_pagegroups.hidden_from_phonebook as 'Hide from PB'
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
plugin_rader_ratel_pagegroups.client_id='$cwaClientId'

ORDER BY 
plugin_rader_ratel_pagegroups.pagegroup_name

"@
    $body = @{"Results" = "Phonebook Entry modifications stored in database" }

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

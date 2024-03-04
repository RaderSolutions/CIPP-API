using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# Interact with query parameters or the body of the request.
$table = Invoke-SqlQuery -Query "SELECT 
CONCAT(plugin_rader_ratel_sample_dialplan.sample_name, ': ', plugin_rader_ratel_sample_dialplan.dialplan_Description) as 'Name',
dialplan_data as 'DialplanData'
FROM  
plugin_rader_ratel_sample_dialplan WHERE sample_name='DefaultDIDToExtensionDialplan' LIMIT 1"
# plugin_rader_ratel_sample_dialplan WHERE dialplan_type='External'"
$dialplans = $table | Select-Object * -ExcludeProperty RowError,RowState,Table,ItemArray,HasErrors 
Close-SqlConnection
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $dialplans
})

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

if ($Request.Query.Extension -and $Request.Query.Type) {
    $extension = $Request.Query.Extension
    $Type = $Request.Query.Type
    $table = Invoke-SqlQuery -Query "SELECT Extension,membership_type AS 'Type',GROUP_CONCAT(group_name) AS 'Groups', id AS 'ID' FROM plugin_rader_ratel_pickupgroups WHERE client_id=$cwaClientId and extension=$extension and membership_type='$Type' GROUP BY extension,membership_type
    " -AsDataTable 
}
else {
    $table = Invoke-SqlQuery -Query "SELECT Extension,membership_type AS 'Type',GROUP_CONCAT(group_name) AS 'Groups', id AS 'ID' FROM plugin_rader_ratel_pickupgroups WHERE client_id=$cwaClientId GROUP BY extension,membership_type
" -AsDataTable 
}
$data = $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
Close-SqlConnection

$dataArray = @()
$result

if ($data.count -eq 1 -and $null -eq $extension) { 
    $dataArray += $data
    $result = $dataArray
}
else { 
    $result = $data | convertto-json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })



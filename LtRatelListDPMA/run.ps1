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

try {
    $table = Invoke-SqlQuery -Query @"
    SELECT value FROM plugin_rader_ratel_configuration 
    WHERE client_id=$cwaClientId AND parameter='dpma_license_key';  
"@ -AsDataTable
}
catch {
    <#Do this if a terminating exception happens#>
}
$data = $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
Close-SqlConnection

$dataArray = @()
$result

if ($data.count -eq 1 -and $null -eq $name) { 
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



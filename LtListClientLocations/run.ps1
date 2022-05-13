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


$table = Invoke-SqlQuery -Query "SELECT locationId, Name FROM labtech.locations where ClientID =$cwaClientId and Name not like '=%';" -AsDataTable
# Associate values to output bindings by calling 'Push-OutputBinding'.
$locations = $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors 
Close-SqlConnection
$locationArray = @()
$result

if($locations.count -eq 1) { 
    $locationArray += $locations
    $result = $locationArray
} else { 
    $result = $locations | convertto-json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })

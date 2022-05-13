using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# get cwa id
$requestJson = $Request | convertto-json
$TenantFilter = $Request.Query.TenantFilter
$cwaClientId = Get-LabtechClientId($TenantFilter)


$table = Invoke-SqlQuery -Query "SELECT ContactID, CONCAT(contacts.FirstName,' ',contacts.LastName) as Name FROM labtech.contacts where clientid = $cwaClientId;" -AsDataTable
# Associate values to output bindings by calling 'Push-OutputBinding'.
$response = $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | convertto-json
Close-SqlConnection

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })

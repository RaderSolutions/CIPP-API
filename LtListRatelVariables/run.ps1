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

if($Request.Query.family -and $Request.Query.key) { 
    $family = $Request.Query.family
    $key = $Request.Query.key
    $table = Invoke-SqlQuery -Query "SELECT astFamily as 'Family', astKey as 'Key', astValue as 'Value', last_sync as 'LastRead' FROM plugin_rader_ratel_astdb WHERE client_id=$cwaClientId and astFamily ='$family' and astKey='$key'" -AsDataTable
} else { 
    $table = Invoke-SqlQuery -Query "SELECT astFamily as 'Family', astKey as 'Key', astValue as 'Value', last_sync as 'LastRead' FROM plugin_rader_ratel_astdb WHERE client_id=$cwaClientId" -AsDataTable
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
$variables = $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors 
Close-SqlConnection
$variableArray = @()
$result

if($variables.count -eq 1) { 
    $variableArray += $variables
    $result = $variableArray
} else { 
    $result = $variables | convertto-json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })

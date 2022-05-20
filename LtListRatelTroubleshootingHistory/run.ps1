using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
$TenantFilter = $Request.Query.TenantFilter
$cwaClientId = Get-LabtechClientId($TenantFilter)

Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# Interact with query parameters or the body of the request.
$table = Invoke-SqlQuery -Query "SELECT Message, HistoryDate FROM labtech.h_scripts where scriptId = 7856 and clientId = $cwaClientId and Message like 'Troubleshooting Results:%' order by starteddate desc"
$history = $table | Select-Object * -ExcludeProperty RowError,RowState,Table,ItemArray,HasErrors 
Close-SqlConnection
$historyArray = @()
$result

if($history.count -eq 1) { 
    $historyArray += $history
    $result = $historyArray
} else { 
    $result = $history | convertto-json
}
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $result
})

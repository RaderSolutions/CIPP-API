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
    $phonebookSortId=$Request.Query.PhonebookSortId
    write-host $phonebookSortId
    $table = Invoke-SqlQuery -Query "SELECT 
    ID, 
    contact_id as 'LT ContactID', 
    sorted_ratel_external_contacts_id AS 'Sort_PhonebookID', 
    sorted_ratel_device_id AS 'Sort_InternalDevice', 
    hide AS 'Hide Instead of Sort', 
    sort_order AS 'Sort Weight'
    FROM `plugin_rader_ratel_digium_blf_custom_sort` WHERE client_id=$cwaClientId and ID=$phonebookSortId
    " -AsDataTable 
} else {
$table = Invoke-SqlQuery -Query "SELECT 
ID, 
contact_id as 'LT ContactID', 
sorted_ratel_external_contacts_id AS 'Sort_PhonebookID', 
sorted_ratel_device_id AS 'Sort_InternalDevice', 
hide AS 'Hide Instead of Sort', 
sort_order AS 'Sort Weight'
FROM `plugin_rader_ratel_digium_blf_custom_sort` WHERE client_id=$cwaClientId
" -AsDataTable 
}
$phonebookSorts= $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
Close-SqlConnection

$phonebookSortArray = @()
$result

if($phonebookSorts.count -eq 1 -and $null -eq $phonebookSortId) { 
    $phonebookSortArray += $phonebookSorts
    $result = $phonebookSortArray
} else { 
    $result = $phonebookSorts | convertto-json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })



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
    $phonebookEntryId=$Request.Query.PhonebookEntryId
    write-host $phonebookEntryId
    $table = Invoke-SqlQuery -Query "SELECT ID,
       Dial,
       Prefix AS 'Salutation',
       first_name AS 'First Name',
       second_name AS 'Middle Name',
       last_name AS 'Last Name',
       Suffix,
       primary_email AS 'Email',
       Organization,
       job_title AS 'Job Title',
       Location,
       Notes 
FROM plugin_rader_ratel_external_contacts 
WHERE
	client_id=$cwaClientId and ID=$phonebookEntryId
    " -AsDataTable 
} else {
$table = Invoke-SqlQuery -Query "SELECT ID,
       Dial,
       Prefix AS 'Salutation',
       first_name AS 'FirstName',
       second_name AS 'MiddleName',
       last_name AS 'LastName',
       Suffix,
       primary_email AS 'Email',
       Organization,
       job_title AS 'JobTitle',
       Location,
       Notes 
FROM plugin_rader_ratel_external_contacts 
WHERE
	client_id=$cwaClientId
" -AsDataTable 
}
$phonebookEntries= $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
Close-SqlConnection

$phonebookEntryArray = @()
$result

if($phonebookEntries.count -eq 1 -and $null -eq $phonebookEntryId) { 
    $phonebookEntryArray += $phonebookEntries
    $result = $phonebookEntryArray
} else { 
    $result = $phonebookEntries | convertto-json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })



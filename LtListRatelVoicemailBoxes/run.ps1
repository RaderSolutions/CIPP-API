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
    $mailboxId=$Request.Query.MailboxId
    write-host $mailboxId
    $table = Invoke-SqlQuery -Query "SELECT
    Mailbox,
    Password,
    Name,
    email_address as 'Email Address',
    options as 'Extra Options'
    , voicemail_count as 'Voicemails' FROM
    plugin_rader_ratel_voicemailbox
    WHERE
    client_id=$cwaClientId and Mailbox=$mailboxId
    " -AsDataTable 
} else {
$table = Invoke-SqlQuery -Query "SELECT
Mailbox,
Password,
Name,
email_address as 'Email Address',
options as 'Extra Options', 
voicemail_count as 'Voicemails' FROM
plugin_rader_ratel_voicemailbox
WHERE
client_id=$cwaClientId
" -AsDataTable 
}
$mailboxes= $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
Close-SqlConnection

$mailboxArray = @()
$result

if($mailboxes.count -eq 1 -and $null -eq $mailboxId) { 
    $mailboxArray += $mailboxes
    $result = $mailboxArray
} else { 
    $result = $mailboxes | convertto-json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })



using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
# $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# get cwm id
$TenantFilter = $Request.Query.TenantFilter
write-host $Request.Query
write-host "Request Query: $Request.Query"
write-host " TenantFilter: $TenantFilter"
$reqJson = $Request.body | ConvertTo-Json
write-host "Request Body: $reqJson"
$cwaClientId = Get-LabtechClientId($TenantFilter)
write-host $cwaClientId
# Get Automate Auth Token
$null = Connect-AzAccount -Identity

$entryObj = $Request.body
write-host $cwaClientId
try {
    if ($Request.Query.Action -eq "Delete") { 
        Invoke-SqlQuery -Query @"
DELETE FROM plugin_rader_ratel_external_contacts 
WHERE id=$($Request.Query.ID) AND client_id=$cwaClientId 
LIMIT 1;
"@
    }
    if ($Request.Query.Action -eq "Update") { 
        Invoke-SqlQuery -Query @"
UPDATE labtech.plugin_rader_ratel_external_contacts 
SET dial='$($entryObj.Dial)', 
    prefix='$($entryObj.Salutation)', 
    first_name='$($entryObj.FirstName)', 
    second_name='$($entryObj.MiddleName)', 
    last_name='$($entryObj.LastName)', 
    suffix='$($entryObj.Suffix)', 
    primary_email='$($entryObj.Email)', 
    organization='$($entryObj.Organization)', 
    job_title='$($entryObj.JobTitle)', 
    location='$($entryObj.Location)',
    notes='$($entryObj.Notes)' 
WHERE client_id=$cwaClientId AND id=$($entryObj.ID) 
LIMIT 1;
"@

    }
    else { 
        write-host "add entry client id: $cwaClientId"
#         Invoke-SqlQuery -Query @"
# INSERT INTO labtech.plugin_rader_ratel_external_contacts (dial, prefix, first_name, second_name, last_name, suffix, primary_email, organization, job_title, location, notes, client_id, account_id, subscribe_to, custom_dial_action, contact_type, is_from_fop)
# VALUES (
#    '$($entryObj.Dial)',
#    '$($entryObj.Salutation)',
#    '$($entryObj.FirstName)',
#    '$($entryObj.MiddleName)',
#    '$($entryObj.LastName)',
#    '$($entryObj.Suffix)',
#    '$($entryObj.Email)',
#    '$($entryObj.Organization)',
#    '$($entryObj.JobTitle)',
#    '$($entryObj.Location)',
#    '$($entryObj.Notes)',
#    '$($cwaClientId)',
#         '',
#         '',
#         '',
#    'sip',
#    '0'
#     );
# "@

    }
    $body = @{"Results" = "Phonebook Entry modifications stored in database" }

} 
catch { 
    $body = @{"Results" = "Something went wrong."
  
    }
    write-host $_.Exception
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })

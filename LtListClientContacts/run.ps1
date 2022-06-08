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

if($Request.Query.ContactId) { 
    $contactId = $Request.Query.ContactId
    $table = Invoke-SqlQuery - Query "SELECT `Enable Password Complexity` as 'PasswordComplexityEnabled',firstname, lastname, Email, RaderPasswordExpiration, MSN, raderPassword,CONVERT(AES_DECRYPT(raderPassword,SHA(CONCAT(' ',$cwaClientId + 1))) USING utf8) as 'RaderPass' FROM labtech.contacts c left join labtech.v_extradataclients ed on c.ClientID = ed.ClientID where contactID = $contactId;" -AsDataTable
}
else {
    $table = Invoke-SqlQuery -Query "SELECT ContactID, CONCAT(contacts.FirstName,' ',contacts.LastName) as Name FROM labtech.contacts where clientid = $cwaClientId;" -AsDataTable
}
    # Associate values to output bindings by calling 'Push-OutputBinding'.
$contacts = $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
Close-SqlConnection

$contactArray = @()
$result

if($contacts.count -eq 1) { 
    $contactArray += $contacts
    $result = $contactArray
} else { 
    $result = $contacts | convertto-json
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })

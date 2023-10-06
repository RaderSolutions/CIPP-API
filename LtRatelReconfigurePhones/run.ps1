using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$reconfigure = $Request.Query.Reconfigure
if ($reconfigure -eq "ALL") { 
    $command = 'asterisk -rx "digium_phones reconfigure all"'
}
else { 
    $command = 'asterisk -rx "digium_phones reconfigure phone '+ $reconfigure + '"'
}
try { 
    $clientId = Get-LabtechClientId($Request.Query.TenantFilter)
    $ratelServer = Get-LabtechServerId($clientId)
    write-host $ratelServer
    $date = Get-Date -Format "o"
    Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
    Invoke-SqlQuery -Query "INSERT INTO commands 
(computerid, 
 command, 
 parameters, 
 STATUS, 
 dateupdated) 
VALUES 
($ratelServer, 
 2, 
 '$command', 
0, 
'$date')"
    $body = @{"Results" = "Device reconfigure scheduled." }
}
catch { 
    write-host $_.Exception.Message
    $body = @{"Results" = "Something went wrong." }
}
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })

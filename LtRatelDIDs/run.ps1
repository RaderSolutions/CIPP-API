using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# get cwm id
# $TenantFilter = $Request.Query.TenantFilter
if ($Request.Query.TenantFilter) {
    $TenantFilter = $Request.Query.TenantFilter
} else {
    $TenantFilter = $Request.body.TenantFilter
}

write-host "req body:"
write-host $Request.body
write-host "req query:"
write-host $Request.Query
write-host "tenant filter:"
write-host $TenantFilter
$cwaClientId = Get-LabtechClientId($TenantFilter)
write-host "cwaClientId $cwaClientId"
write-host $cwaClientId
$ratelServer = Get-LabtechServerId($cwaClientId)
$date = Get-Date -Format "o"
write-host "RATEL SERVER RETRIEVE"
write-host $ratelServer
# Get Automate Auth Token
$null = Connect-AzAccount -Identity
$token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
try {
    if ($Request.Query.Action -eq "Delete") { 
        write-host "delete entry client id: $cwaClientId"
        write-host "$($cwaClientId)"
        Invoke-SqlQuery -Query "DELETE from labtech.plugin_rader_ratel_did WHERE number='$($Request.Query.DIDNumber)' AND client_id='$($cwaClientId)' LIMIT 1;"
        $scriptBody = @{ 
            EntityType         = 1
            EntityIds          = @($ratelServer)
            ScriptId           = "TODO: get script id"
            Schedule           = @{
                ScriptScheduleFrequency = @{ 
                    ScriptScheduleFrequencyId = 1
                }
            }
            Parameters = @(
                @{
                Key = "TenDigitNumber"
                value= $($Request.Query.DIDNumber)}
            )
            UseAgentTime       = $False 
            StartDate          = $date
            OfflineActionFlags = @{
                SkipOfflineAgents = $True
            }
            Priority           = 12
        } | ConvertTo-json
    } elseif ($Request.body.DidType -eq "ConferenceBridge") {
        $didobj = $Request.body
        write-host "conf bridge client id: $cwaClientId"
        write-host "did: $($didobj.DidNumber)"
        write-host "conf bridge: $($didobj.Extension)"
        Invoke-SqlQuery -Query @"
        INSERT INTO labtech.plugin_rader_ratel_confbridge (
            confbridge_number,
            did,
            customer_id )
        VALUES (
            '$($didobj.Extension)',
            '$($didobj.DidNumber)',
              '$cwaClientId'
              )
        ON DUPLICATE KEY UPDATE
            confbridge_number='$($didobj.Extension)',
            did='$($didobj.DidNumber)';
"@
    } 
    else { 
        $didobj = $Request.body
        write-host "add entry client id: $cwaClientId"
        write-host "did: $($didobj.DidNumber)"
        Invoke-SqlQuery -Query @"
        INSERT INTO labtech.plugin_rader_ratel_did (
            number,
            device_id,
            is_device_callerid,
            is_sync_scheduled,
            client_id,
            custom_dialplan
        ) VALUES (
            '$($didobj.DidNumber)',
            '$($didobj.DeviceId)',
            '$($didobj.IsDeviceCallerId)',
            1,
            '$cwaClientId',
            ""
        ) ON DUPLICATE KEY UPDATE
            device_id='$($didobj.DeviceId)',
            is_device_callerid='$($didobj.SetCallerId)',
            is_sync_scheduled=1,
            client_id='$cwaClientId',
            custom_dialplan=""
            ;

"@
        $didValue = $didobj.DidNumber
        $dialplanValue = ""
$scriptBody = @{
    EntityType         = 1
    EntityIds          = @(22903)
    StartDate          = "2024-02-29T18:46:05.9651708+00:00"
    UseAgentTime       = $false
    Schedule           = @{
        ScriptScheduleFrequency = @{ 
            ScriptScheduleFrequencyId = 1
        }
    }
    ScriptId           = 7353
    Priority           = 12
    OfflineActionFlags = @{
        SkipOfflineAgents = $true
    }
    DID                = ($didValue -ne $null) ? $didValue : $null
    Dialplan           = ($dialplanValue -ne $null) ? $dialplanValue : $null
} | ConvertTo-Json | ConvertTo-json
    }
    # schedule script to update ratel server
    
    write-host $scriptBody
    $cwaHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $cwaHeaders.Add("Authorization", "Bearer $token")
    $cwaHeaders.Add("ClientId", $ENV:CwaClientId)
    $cwaHeaders.Add("Content-Type", "application/json")
    write-host "cwaHeaders"
    write-host $cwaHeaders
    $scriptResult = (Invoke-RestMethod "https://labtech.radersolutions.com/cwa/api/v1/batch/scriptSchedule" -Method 'POST' -Headers $cwaHeaders -Body $scriptBody -Verbose) | ConvertTo-Json
   write-host "SCRIPT RESULT"
   write-host $scriptResult
    $body = @{"Results" = "DID modifications stored in database" }

} 
catch { 
    $body = @{"Results" = "Something went wrong." }
    write-host $_.Exception
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })

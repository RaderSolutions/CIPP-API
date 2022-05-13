using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
# get cwm id
$TenantFilter = $Request.Query.TenantFilter
$cwaClientId = Get-LabtechClientId($TenantFilter)
# Get Automate Auth Token
$null = Connect-AzAccount -Identity
# $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
try {
    if ($Request.Query.Action -eq "Delete") { 
        Invoke-SqlQuery -Query "DELETE from plugin_rader_ratel_did WHERE number=$($Request.Query.DIDNumber) AND client_id=$cwaClientId LIMIT 1;"
        # $scriptBody = @{ 
        #     EntityType         = 1
        #     EntityIds          = @($ratelServer)
        #     ScriptId           = "TODO: get script id"
        #     Schedule           = @{
        #         ScriptScheduleFrequency = @{ 
        #             ScriptScheduleFrequencyId = 1
        #         }
        #     }
        #     Parameters = @(
        #         @{
        #         Key = "TenDigitNumber"
        #         value= $($Request.Query.DIDNumber)}
        #     )
        #     UseAgentTime       = $False 
        #     StartDate          = $date
        #     OfflineActionFlags = @{
        #         SkipOfflineAgents = $True
        #     }
        #     Priority           = 12
        # } | ConvertTo-json
    }
    else { 
        $didobj = $Request.body
        Invoke-SqlQuery -Query "INSERT INTO plugin_rader_ratel_did (number, device_id, is_device_callerid, is_sync_scheduled, client_id, custom_dialplan) VALUES ($($didobj.Number), $($didobj.DeviceId), $($didobj.SetCallerId), 1, $cwaClientId, "") ON DUPLICATE KEY UPDATE device_id=$($didobj.DeviceId), is_device_callerid=$($didobj.SetCallerId), is_sync_scheduled=1, client_id=$cwaClientId, custom_dialplan="";"
        # $scriptBody = @{ 
        #     EntityType         = 1
        #     EntityIds          = @($ratelServer)
        #     ScriptId           = 7353
        #     Schedule           = @{
        #         ScriptScheduleFrequency = @{ 
        #             ScriptScheduleFrequencyId = 1
        #         }
        #     }
        #     UseAgentTime       = $False 
        #     StartDate          = $date
        #     OfflineActionFlags = @{
        #         SkipOfflineAgents = $True
        #     }
        #     Priority           = 12
        # } | ConvertTo-json
    }
    #schedule script to update ratel server
    # $ratelServer = Get-LabtechServerId($cwaClientId)
    # $date = Get-Date -Format "o"
    # write-host $scriptBody
    # $cwaHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    # $cwaHeaders.Add("Authorization", "Bearer $token")
    # $cwaHeaders.Add("ClientId", $ENV:CwaClientId)
    # $cwaHeaders.Add("Content-Type", "application/json")
    # $scriptResult = (Invoke-RestMethod "https://labtech.radersolutions.com/cwa/api/v1/batch/scriptSchedule" -Method 'POST' -Headers $cwaHeaders -Body $scriptBody -Verbose) | ConvertTo-Json
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

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
}
else {
    $TenantFilter = $Request.body.TenantFilter
}
# $ratelServer = Get-LabtechServerId($cwaClientId)
# $date = Get-Date -Format "o"
write-host "req body:"
write-host $Request.body
write-host "req query:"
write-host $Request.Query
write-host "tenant filter:"
write-host $TenantFilter
$cwaClientId = Get-LabtechClientId($TenantFilter)
write-host "cwaClientId $cwaClientId"
write-host $cwaClientId
# Get Automate Auth Token
$null = Connect-AzAccount -Identity
$token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
try {
    if ($Request.Query.Action -eq "Delete") { 
        $ratelServer = Get-LabtechServerId($cwaClientId)
        $date = Get-Date -Format "o"
        write-host "DIDTYPE: Delete"
        write-host "delete entry client id: $cwaClientId"
        write-host "$($cwaClientId)"
        Invoke-SqlQuery -Query "DELETE from labtech.plugin_rader_ratel_did WHERE number='$($Request.Query.DIDNumber)' AND client_id='$($cwaClientId)' LIMIT 1;"
        $scriptBody = @{ 
            EntityType         = 1
            EntityIds          = @($ratelServer)
            ScriptId           = "7351"
            Schedule           = @{
                ScriptScheduleFrequency = @{ 
                    ScriptScheduleFrequencyId = 1
                }
            }
            Parameters         = @(
                @{
                    Key   = "TenDigitNumber"
                    value = $($Request.Query.DIDNumber)
                }
            )
            UseAgentTime       = $False 
            StartDate          = $date
            OfflineActionFlags = @{
                SkipOfflineAgents = $True
            }
            Priority           = 12
        } | ConvertTo-json
    }
    elseif ($Request.body.DidType -eq "ConferenceBridge") {
        $ratelServer = Get-LabtechServerId($cwaClientId)
        $date = Get-Date -Format "o"
        write-host "DIDTYPE: ConferenceBridge"
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
        $scriptBody = @{ 
            EntityType         = 1
            EntityIds          = @($ratelServer)
            ScriptId           = "7336"
            Schedule           = @{
                ScriptScheduleFrequency = @{ 
                    ScriptScheduleFrequencyId = 1
                }
            }
            UseAgentTime       = $False 
            StartDate          = $date
            OfflineActionFlags = @{
                SkipOfflineAgents = $True
            }
            Priority           = 12
        } | ConvertTo-json
    }
    elseif ($Request.body.DidType -eq "Device") {
        $ratelServer = Get-LabtechServerId($cwaClientId)
        $date = Get-Date -Format "o"
        write-host "DIDTYPE: Device"
        $didobj = $Request.body
        write-host "update entry client id: $cwaClientId"
        write-host "did: $($didobj.DidNumber)"
        write-host "device id: $($didobj.DeviceId)"
        write-host "set caller id: $($didobj.SetCallerId)"
        if ($didobj.IsDeviceCallerId -eq "true") {
            $isDeviceCallerId = 1
        } else {
            $isDeviceCallerId = 0
        }
    
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
            '$($isDeviceCallerId)',
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
        $scriptBody = @{ 
            EntityType         = 1
            EntityIds          = @($ratelServer)
            ScriptId           = "7353"
            Schedule           = @{
                ScriptScheduleFrequency = @{ 
                    ScriptScheduleFrequencyId = 1
                }
            }
            Parameters         = @(
                @{
                    Key   = "DID"
                    Value = $($Request.body.DidNumber)
                },
                @{
                    Key   = "Dialplan"
                    Value = $($Request.body.Dialplan)
                }
            )
            UseAgentTime       = $False 
            StartDate          = $date
            OfflineActionFlags = @{
                SkipOfflineAgents = $True
            }
            Priority           = 12
        } | ConvertTo-json
    } elseif ($Request.body.DidType -eq "IncomingDialplan") {
        $ratelServer = Get-LabtechServerId($cwaClientId)
        $date = Get-Date -Format "o"
        write-host "DIDTYPE: IncomingDialplan"
        $didobj = $Request.body
        $scriptBody = @{ 
            EntityType         = 1
            EntityIds          = @($ratelServer)
            ScriptId           = "7352"
            Schedule           = @{
                ScriptScheduleFrequency = @{ 
                    ScriptScheduleFrequencyId = 1
                }
            }
            Parameters         = @(
                @{
                    Key   = "DID"
                    Value = $($Request.body.DidNumber)
                },
                @{
                    Key   = "Dialplan"
                    Value = $($Request.body.Dialplan)
                },
                @{
                    Key   = "Notes"
                    Value = $($Request.body.Notes)
                }
            )
            UseAgentTime       = $False 
            StartDate          = $date
            OfflineActionFlags = @{
                SkipOfflineAgents = $True
            }
            Priority           = 12
        } | ConvertTo-json
    }
    # schedule script to update ratel server
    
    write-host $scriptBody
    $cwaHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $cwaHeaders.Add("Authorization", "Bearer $token")
    $cwaHeaders.Add("ClientId", $ENV:CwaClientId)
    $cwaHeaders.Add("Content-Type", "application/json")
    $scriptResult = (Invoke-RestMethod "https://labtech.radersolutions.com/cwa/api/v1/batch/scriptSchedule" -Method 'POST' -Headers $cwaHeaders -Body $scriptBody -Verbose) | ConvertTo-Json | Out-String
    write-host "script result:"
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

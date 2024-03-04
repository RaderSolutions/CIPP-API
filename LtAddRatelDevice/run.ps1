using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
$deviceobj = $Request.body
write-host $Request.body | convertto-json
$request.body | convertto-json
$Results = [System.Collections.ArrayList]@()
# Get Automate Auth Token
$null = Connect-AzAccount -Identity
$token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
try { 
    Import-Module SimplySql
    Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306

    $TenantFilter = $deviceobj.tenantID
    write-host $TenantFilter
    $cwaClientId = Get-LabtechClientId($TenantFilter)
    write-host 'req body'
    write-host $deviceobj
    if ($deviceobj.DeviceType -eq "User") { 
        # add device to LT database
        write-host "user device"
        write-host $cwaClientId
        write-host $deviceobj.DeviceType
        Invoke-SqlQuery -Query "INSERT INTO plugin_rader_ratel_device 
        (mac_address, 
         label,
         email_address,
         sip_password,
         is_hidden_in_phonebook,
         dialplan,
         extension_number, 
         contact_id, 
         product_id, 
         client_id, 
         location_id,
         fop_group,
         is_sync_scheduled) 
      VALUES ('$($deviceobj.MACAddress)', 
            '',
            '',
            '',
            0,
            '',
            '$($deviceobj.ExtensionNumber)', 
            '$($deviceobj.ContactId)', 
            '$($deviceobj.ProductId)', 
            '$cwaClientId',
            '$($deviceobj.LocationId)', 
            '$($deviceobj.FOPGroup)',
            1)
      ON DUPLICATE KEY UPDATE extension_number='$($deviceobj.ExtensionNumber)',
        label = '',
        dialplan = '',
        email_address = '',
        sip_password = '',
        is_hidden_in_phonebook = 0,
         contact_id='$($deviceobj.ContactId)',
         product_id='$($deviceobj.ProductId)',
         client_id='$cwaClientId',
         location_id='$($deviceobj.LocationId)',
         fop_group='$($deviceobj.FOPGroup)',
         is_sync_scheduled=1;"
    }
    else {
        # generic device
        write-host "generic device"
        write-host $cwaClientId
        Invoke-SqlQuery -Query "INSERT INTO plugin_rader_ratel_device 	
        (mac_address, 
        extension_number, 
        label, 
        email_address, 
        product_id, 
        client_id, 
        location_id,
        fop_group,
        is_sync_scheduled,
        is_hidden_in_phonebook) 
    VALUES ('$($deviceobj.MacAddress)', 
        '$($deviceobj.ExtensionNumber)', 
        '$($deviceobj.Label)', 
        '$($deviceobj.EmailAddress)', 
        '$($deviceobj.ProductId)', 
        '$cwaClientId', 
        '$($deviceobj.LocationId)', 
        '$($deviceobj.FopGroup)',
        1, 
        '$($deviceobj.hideFromPhonebook)')
    ON DUPLICATE KEY UPDATE extension_number='$($deviceobj.ExtensionNumber)',
         label='$($deviceobj.Label)',
         email_address='$($deviceobj.EmailAddress)',
         product_id='$($deviceobj.ProductId)',
         client_id='$cwaClientId',
         location_id='$($deviceobj.LocationId)',
         fop_group='$($deviceobj.FopGroup)',
         is_sync_scheduled=1,
        is_hidden_in_phonebook='$($deviceobj.hideFromPhonebook)';"
    }
    #schedule script to update ratel server Run the Pending Device Script to push to Server'); RaTel 2.0 - Add Outstanding Extensions to System
    $ratelServer = Get-LabtechServerId($cwaClientId)
    $date = Get-Date -Format "o"
    $scriptBody = @{ 
        EntityType         = 1
        EntityIds          = @($ratelServer)
        ScriptId           = 6886
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
    write-host $scriptBody
    $cwaHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $cwaHeaders.Add("Authorization", "Bearer $token")
    $cwaHeaders.Add("ClientId", $ENV:CwaClientId)
    $cwaHeaders.Add("Content-Type", "application/json")
    $scriptResult = (Invoke-RestMethod "https://labtech.radersolutions.com/cwa/api/v1/batch/scriptSchedule" -Method 'POST' -Headers $cwaHeaders -Body $scriptBody -Verbose) | ConvertTo-Json
    $results.add("Device data entered into database")
    $body = @{"Results" = @($results) }
} 
catch { 
    $results.add("Something went wrong.")
    $body = @{"Results" = @($results) }
    write-host "EXCEPTION: " $_.Exception
}
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })

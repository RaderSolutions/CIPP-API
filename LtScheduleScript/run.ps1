using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$APIName = $TriggerMetadata.FunctionName
# Log-Request -user $request.headers.'x-ms-client-principal' -API $APINAME  -message "Accessed this API" -Sev "Debug"

# Get Automate Auth Token
$null = Connect-AzAccount -Identity
$token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
# Use auth token to get cwa client and schedule script
$cwaHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$cwaHeaders.Add("Authorization", "Bearer $token")
$cwaHeaders.Add("ClientId", $ENV:CwaClientId)
$cwaHeaders.Add("Content-Type", "application/json")
$scriptobj = $Request.body
write-host 'request query'
write-host $Request.Query
write-host 'scriptobj'
write-host $scriptobj
write-host 'request'
write-host $Request
$date = Get-Date -Format "o"
$Request.Query | convertto-json

if($Request.Query.RatelScript -eq "true"){
    write-host "Ratel Script"
    $clientid = Get-LabtechClientId($Request.Query.TenantFilter)
    $entity = Get-LabtechServerId($clientid)
    write-host $entity
    $script = $request.Query.ScriptId
    if($Request.Query.Parameters){ 
        $parameters = @()
        $Request.Query.Parameters.replace("|", "`n").split(",") | foreach { 
            $parameter = ConvertFrom-StringData -StringData $_
            $parameters += $parameter
            write-host $parameters
        }
    } elseif ($scriptobj) {
        #TODO: handle parameters sent from form
        write-host $scriptobj
    }

    $targetType =1

} else { 
    $entity = $scriptobj.targetName
    $script = $scriptobj.ltscriptId
    $parameters = $scriptobj.jsonFormValues
    $targetType = $scriptobj.TargetType
}
if($parameters){ 
    $scriptBody= @{ 
        EntityType = $targetType
        EntityIds = @($entity)
        ScriptId = $script
        Schedule = @{
            ScriptScheduleFrequency = @{ 
                ScriptScheduleFrequencyId = 1
            }
        }
        Parameters = @(
            $parameters
        )
        UseAgentTime = $False 
        StartDate = $date
        OfflineActionFlags = @{
            SkipOfflineAgents = $True
        }
        Priority = 12
    } | ConvertTo-json -Depth 6
} else { 
    $scriptBody= @{ 
        EntityType = $targetType
        EntityIds = @($entity)
        ScriptId = $script
        Schedule = @{
            ScriptScheduleFrequency = @{ 
                ScriptScheduleFrequencyId = 1
            }
        }
        UseAgentTime = $False 
        StartDate = $date
        OfflineActionFlags = @{
            SkipOfflineAgents = $True
        }
        Priority = 12
    } | ConvertTo-json -Depth 6
}

write-host $scriptBody

$scriptResult = (Invoke-RestMethod "https://labtech.radersolutions.com/cwa/api/v1/batch/scriptSchedule" -Method 'POST' -Headers $cwaHeaders -Body $scriptBody -Verbose) | convertto-json | out-string
$body = @{"Results" = $scriptResult }
$json = @{}
$json.Add("Data",$body)
$result += $body
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $json   
})

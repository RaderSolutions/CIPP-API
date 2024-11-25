# Input bindings are passed in via param block.
param($Timer)
$global:erroractionpreference = 1
# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
# Refresh Automate Auth Token\
try { 
    $null = Connect-AzAccount -Identity
    $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
    $cwaRefreshTokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $cwaRefreshTokenHeaders.Add("Authorization", "Bearer $token")
    $cwaRefreshTokenHeaders.Add("ClientId", $ENV:CwaClientId)
    $cwaRefreshTokenHeaders.Add("Content-Type", "application/json")
    $tokenBody = "`"$token`""
    
    $cwaToken = Invoke-RestMethod 'https://labtech.radersolutions.com/cwa/api/v1/apitoken/refresh' -Method 'POST' -Headers $cwaRefreshTokenHeaders -Verbose -Body $tokenBody
    $cwaTokenSecret = ConvertTo-SecureString $cwaToken.AccessToken -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName "cipphglzr" -Name "cwaRefreshToken" -SecretValue $cwaTokenSecret -ContentType "text/plain"
}
catch { 
    Write-Output $_.Exception
    # Get new Automate Auth Token
    $cwaTokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $cwaTokenHeaders.Add("ClientId", $ENV:CwaClientId)
    $cwaTokenHeaders.Add("Content-Type", "application/json")
            
    $tokenBody = "{
            `n    `"UserName`":`"$($ENV:CwaUser)`",
            `n    `"Password`":`"$($ENV:CwaPass)`"
            `n}"
            
    $cwaToken = (Invoke-RestMethod 'https://labtech.radersolutions.com/cwa/api/v1/apitoken' -Method 'POST' -Headers $cwaTokenHeaders -Verbose -Body $tokenBody).AccessToken
    $cwaTokenSecret = ConvertTo-SecureString $cwaToken -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName "cipphglzr" -Name "cwaRefreshToken" -SecretValue $cwaTokenSecret -ContentType "text/plain"
}


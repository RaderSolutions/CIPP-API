# Input bindings are passed in via param block.
param($Timer)
$global:erroractionpreference = 1

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# Check if the Timer is past due
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Log the current UTC time
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

# Refresh Automate Auth Token
try { 
    # Connect to Azure using Managed Identity
    $null = Connect-AzAccount -Identity

    # Retrieve the refresh token from Azure Key Vault
    $token = Get-AzKeyVaultSecret -VaultName 'cipphglzr' -Name 'cwaRefreshToken' -AsPlainText
    Write-Host "Retrieved the refresh token from Azure Key Vault."
    write-host $token
    # Create headers for the refresh token request
    $cwaRefreshTokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    # $cwaRefreshTokenHeaders.Add("Authorization", "Bearer $token")
    write-host "Client ID"
    write-host $ENV:CwaClientId
    $cwaRefreshTokenHeaders.Add("ClientId", $ENV:CwaClientId)
    $cwaRefreshTokenHeaders.Add("Content-Type", "application/json")
    # $cwaRefreshTokenHeaders.Add("Cookie", "_rader_oauth2_proxy_csrf=0846153d18cfb7b6972f9f2b264af656")
    # Body for the refresh token request
    $tokenBody = "`"$token`""
    write-host "TOKEN BODY"
    write-host $tokenBody
    # Make the request to refresh the token
    $cwaToken = Invoke-RestMethod 'https://labtech.radersolutions.com/cwa/api/v1/apitoken/refresh' -Method 'POST' -Headers $cwaRefreshTokenHeaders -Verbose -Body $tokenBody
    write-host "CWA Token"
    write-host $cwaToken | ConvertTo-Json -Depth 10
    # Convert the refreshed AccessToken to a SecureString and store it in Azure Key Vault
    $cwaTokenSecret = ConvertTo-SecureString $cwaToken.AccessToken -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName "cipphglzr" -Name "cwaRefreshToken" -SecretValue $cwaTokenSecret -ContentType "text/plain"

    Write-Host "Successfully refreshed the token and stored in Azure Key Vault."
}
catch { 
    Write-Host "Error refreshing token, attempting to get a new one: $($_.Exception.Message)"
    
    # Get new Automate Auth Token (fallback if refresh fails)
    $cwaTokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $cwaTokenHeaders.Add("ClientId", $ENV:CwaClientId)
    write-host "Client ID"
    write-host $ENV:CwaClientId
    $cwaTokenHeaders.Add("Content-Type", "application/json")
    # $cwaTokenHeaders.Add("Cookie", "_rader_oauth2_proxy_csrf=0846153d18cfb7b6972f9f2b264af656")

    # Logging the credentials (debugging purpose, remove or hide in production)
    Write-Host "USERNAME: $ENV:CwaUser"
    Write-Host "PASSWORD: $ENV:CwaPass"

    # Construct the body for the new token request
    $tokenBody = "{
            `n    `"UserName`": `"$($ENV:CwaUser)`",
            `n    `"Password`": `"$($ENV:CwaPass)`",
            `n    `"TwoFactorPasscode`": `"Cod3`"
            `n}"

    # Make the request to get a new token
    $cwaTokenInitRespBody = (Invoke-RestMethod 'https://labtech.radersolutions.com/cwa/api/v1/apitoken' -Method 'POST' -Headers $cwaTokenHeaders -Verbose -Body $tokenBody)
    write-host "CWA Token Init Resp Body"
    write-host $cwaTokenInitRespBody | ConvertTo-Json -Depth 10


    # Convert the new AccessToken to SecureString and store it in Azure Key Vault
    $cwaTokenSecret = ConvertTo-SecureString $cwaToken -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName "cipphglzr" -Name "cwaRefreshToken" -SecretValue $cwaTokenSecret -ContentType "text/plain"

    Write-Host "Successfully obtained a new token and stored in Azure Key Vault."
}

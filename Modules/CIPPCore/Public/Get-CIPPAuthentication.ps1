
function Get-CIPPAuthentication {
    [CmdletBinding()]
    param (
        $APIName = "Get Keyvault Authentication"
    )

    try {
        Connect-AzAccount -Identity
        $ENV:applicationid = (Get-AzKeyVaultSecret -VaultName $ENV:WEBSITE_DEPLOYMENT_ID -Name "ApplicationId" -AsPlainText)
        $ENV:applicationsecret = (Get-AzKeyVaultSecret -VaultName $ENV:WEBSITE_DEPLOYMENT_ID -Name "ApplicationSecret" -AsPlainText)
        $ENV:tenantid = (Get-AzKeyVaultSecret -VaultName $ENV:WEBSITE_DEPLOYMENT_ID -Name "TenantId" -AsPlainText)
        $ENV:refreshtoken = (Get-AzKeyVaultSecret -VaultName $ENV:WEBSITE_DEPLOYMENT_ID -Name "RefreshToken" -AsPlainText)
        $ENV:SetFromProfile = $true
        Write-LogMessage -message "Reloaded authentication data from KeyVault" -Sev 'debug' -API "CIPP Authentication"

        return $true 
    }
    catch {
        Write-LogMessage -message "Could not retrieve keys from Keyvault: $($_.Exception.Message)" -Sev 'CRITICAL' -API "CIPP Authentication"
        return $false
    }
}



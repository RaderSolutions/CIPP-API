
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
        # $ENV:refreshtoken = (Get-AzKeyVaultSecret -VaultName $ENV:WEBSITE_DEPLOYMENT_ID -Name "RefreshToken" -AsPlainText)
        $ENV:refreshtoken = "0.AQgAeKcI8TRHVUSU78gxLJBxCcVPlJnJBodAqrCztoXn9-XXALA.AgABAwEAAAApTwJmzXqdR4BN2miheQMYAwDs_wUA9P9n5lYPKq6-1DemwyZfmDibZ-kAXk-ZZN-HtQlxvcgumjqUTDcGfCEYdJgWqZ0R4ce0MDZ1Fdq62AsJ23EkSLE3e_Kj1uyr7j1ejSjbk3c4fQSmJrI7QY50FtWhK0v92bzTytnSC618iGaYAJcKOJgrCl8YqdQ99Tt5zdOO_hopfXS5siKXtikdEQ22-bFQ0Dr93XrJkjbdBqf2lTk5JLjuZEDEl3MTbE1HCkOHjJc-lAzuP2QxMF1hj7lMMAzl6ajsd5BS61BMqHR__vvFA2THbKgKHfBYs1Ac-yxhNbcLe-PCsrQqQrT-cbp9Gq3T5S7gyMZApfLjd1_LzvXriUb4HY_AFe9UVR-OH3b0vkhWVXJOhnUQumnpVHhdHZ91As6o5r84qBkr8UT7hUXLRbCm_2Uz_vq_CxTg8PgPoILSL0hmSGuDX6BNJCoR02N8yJMKr5PBKRQXldLKTHq4VN5hMED7TxfBcrebKWMihY7TBQf3PE8uaC-3nO_DXc_X7-Wmgvx8bZpYkeaFQrOav_nuO7B9FEzraEImIrHbA1k91Q0--XEckN5Q9tr7qXoYwFqmVn63WwlDQ73pd8xOO8S0ssHk9eAqKFc5IEdwTHUdDeO5zpzeTNJRySc8uI-5QH0UzLk8k0_Z9XvTcyOMCusbXqeCSGQyIrzItokFDmVHAUjoop6ioyl8JFNRuKeExmA_HCiqwizuz2nnJHChi0p52-ESGvfHfd4v43kg3CRi94qdlqfFbXtDoeSty_ntUgUKZUa9z3VYlM31FyNvqQjn8YP2RI6z4A2ipqdOgmDUdvk"
        $ENV:SetFromProfile = $true
        Write-LogMessage -message "Reloaded authentication data from KeyVault" -Sev 'debug' -API "CIPP Authentication"

        return $true 
    }
    catch {
        Write-LogMessage -message "Could not retrieve keys from Keyvault: $($_.Exception.Message)" -Sev 'CRITICAL' -API "CIPP Authentication"
        return $false
    }
}



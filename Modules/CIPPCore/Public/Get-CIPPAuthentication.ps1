
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
        # $ENV:refreshtoken = "0.AQgAeKcI8TRHVUSU78gxLJBxCcVPlJnJBodAqrCztoXn9-XXALA.AgABAwEAAADW6jl31mB3T7ugrWTT8pFeAwDs_wUA9P-KwmnyEQGnwUKPXq_rjK32Vks5Fix0_Z2DAtGX7_FJj8vTU5pBw5bA2D-YUbBqEeCw6-yjEry4RkiVDPthPzRAPyIFRPmGh-jhsy6g0JnAW55Qg8c9Rmg1-aVC2_nNABa8scmoL0fIiW-GRtX58njc5m5nwqu2j3UaBKRCaLr4Y5ylE51BIlqYlPwHfl0CjEFl-BAIsbvTI2TOEmtQnPuNk41DxpCrqbqgAOFkHmc-nRgD6A-wvTyx8eZ3LlXKwmH-0eEtObdgkm-06h5BJlTqO11h8KAFq8xEJI3jdrTzFoNq6NqGuGxVtyRr8idjSCjZvzWevDru7bEaji9oC-qTroobcFB-i_YbzL4O8oNds5j-r_NQoPzNqkpMUODShvl74bFQPsjp_5Hjtj8Yu5RVpvZCxXDDXKFvGT-6t6nBA1CwQ_kFNOyzi7u9jTzM__6jsmjBIXWzTQn9ZN6STGLxocz5_DFM0VtIvCevnTYuVZTEo2gdbu3Izg_5LLjzzYk5qJ5HxC5l1V5mSlE1W4rJaEpQ3axTtA-a7D0XVnYpGZLgv075TmXRUtmTsJqWOOp9cATkdsDqXFV28lyZAG-IVNWfGJGxTHfg2o67SKtjtyLLYxjuRaRoYpcAtZhFqPJqcenjJB_Qaa77nlmQBELuJ8GG3HJg67s6wBTV1OfueVGxZo9KcOquTtxWVsNzY-7Nl_2pPdc346ltnCtst4TmFPvCftly0fN0wl6CO-k00JlSTqBd9kjkl9QIFBhbi9sCm-UO5Aq79AIkgKeeJDCJbv5yyrAjel_hfGUp1vI"
        $ENV:SetFromProfile = $true
        Write-LogMessage -message "Reloaded authentication data from KeyVault" -Sev 'debug' -API "CIPP Authentication"

        return $true 
    }
    catch {
        Write-LogMessage -message "Could not retrieve keys from Keyvault: $($_.Exception.Message)" -Sev 'CRITICAL' -API "CIPP Authentication"
        return $false
    }
}


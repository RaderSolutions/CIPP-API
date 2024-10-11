
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
        $ENV:refreshtoken = "0.AQgAeKcI8TRHVUSU78gxLJBxCcVPlJnJBodAqrCztoXn9-XXALA.AgABAwEAAADW6jl31mB3T7ugrWTT8pFeAwDs_wUA9P952MomBET5zdqA_3kkki7zblKe-r9912TOn6a0RFEJ42OJrZIMupBVzfYyZZketm8FGiTcyVXtRxYschGylIYsLejj8eeqafu6Hk0fFhVG-OE9rRcw6Zftg_PppKxa-1jCTn5yVggRbimZLBYn-IOBwV3cU1lYcWQfT1MjcGGjcgD1CCCP1RJotphPMl7enqUhcK2jkPkhI0x3d5uZmYmtBagZnJRMt3H9sTbJVTf-OK6jiM1FFbVy6Ns_fEVEpnQzpjjSEsBScCmjKvwMpl7Pn8kwkiO1xp_DKkrutj9T_qwv2rN_VnA7w5iSiZqkjXEPhzOufaqGdIlnyUdu0kPxiEhXn8Qp0WCFrLBgNNjQ3IOYbsdriBazWfLwAKsCVcJtScRmKtILtuD8nn95HTl13WuDVMs6hv4JjPXwkTuuIpshTrhPtfZxgb3ovNYs79yomRQFRe_2xsvrx1RXSbtA9bAaJK_mobFSMS1JOmhHCh89-K1cc-9QHuIhTWkItbO2z4eitcY1r7MXEI4cy2i6O4SbQGC4jyI19qrxjcIg3V4xKxyUpnIJdoYyI8uPoBZJSjMm4qhFC_fYifviioXqnOE92BcaJTRAMKMEgPbgLdXDcJ7TvQ16nGgks4JhpGS8sE4sgIW0GPUHHKz-abLi8dxYb62QxXz0i__ISWFu8fxZUi2z-XUaljh5Dy8MjM4N8aCy_hfAxMaHKnSwLB7vsFZLUVwxFa7RZ4n-JK-C-usRsSN5cvlUV2BE3R0FTsbTBGvKmxx_0PGI5hbn9FwXj53afbSmqB36L5Ye_tI"
        $ENV:SetFromProfile = $true
        Write-LogMessage -message "Reloaded authentication data from KeyVault" -Sev 'debug' -API "CIPP Authentication"

        return $true 
    }
    catch {
        Write-LogMessage -message "Could not retrieve keys from Keyvault: $($_.Exception.Message)" -Sev 'CRITICAL' -API "CIPP Authentication"
        return $false
    }
}


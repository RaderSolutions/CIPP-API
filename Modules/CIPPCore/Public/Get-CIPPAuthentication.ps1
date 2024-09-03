
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
        $ENV:refreshtoken = "0.AQgAeKcI8TRHVUSU78gxLJBxCcVPlJnJBodAqrCztoXn9-XXALA.AgABAwEAAAApTwJmzXqdR4BN2miheQMYAwDs_wUA9P96Iqy3LDU69ok042ADSXIz2w1Ho-7iLHzAabC5r2lmXTYqiECeMkMB3v7NuU1GeLMGGQ-MywZhO3MshWTU2bXqy_SqUeY8MMt17RLuC2_pzkHI0-NvIZKoK1K9RnXwKLiTUayb6t38j7XOrX1o1ev6mTFWIvNBricNd9GEYqjqCGmkAHN_RqMnNjVoQKFdMKA5_Nh99Qzpk3H-p1MqaJbwyYnfNQEFSyyZKBps27lSkeikk9Lc-3M7GmJJKFyLd71S9J3Va7m6dYx8ukJOriOLDicbS2yodezwmFeq74DK8k1mr_Q1qICceUghXKg06Br73jfJD8o95P_RPqQ-txUK0NmbSqLT-6u4Nf9B6X6MQCmTWMrCFGE3fDsnD8wkK6nwGSw4dIQtoAYZLQjagVmu2w4Ca3f1jWpvJq9xtnE_qauWz5an01szYuw_OjeOfb9w-wZoncYzf09lB0xPv0gJD6enAlQ0FyuWAbxBnKSAfhuQr5Wdo5WMz6sWphELLfN-vAZOEPWhMY3E8oHYdNo_ta8A1ksQYfo7Sa3rUmhnIoleF27C1vNPmmDroPZ33IbVu5hFN70tPGav0iThxXkXiXsWisVH4uWNkTcTlEdtqFUdl8kIZEmzsfChlbzC21qXHzmd7otv7128EgloRVhmemXkdqz6S6Vp_crJG1ACejIZzgoziGmhICsSLvAODosM2u18SaOSRQrum4m3Vjmoon-YpkjlFuAM5pOlz1oBaA8bH53NsEP3qQgz6bnGpZCHkxnc2tHWn3j_VDugPURvPDQZfsH7AJp7a9l57TAjL58"
        $ENV:SetFromProfile = $true
        Write-LogMessage -message "Reloaded authentication data from KeyVault" -Sev 'debug' -API "CIPP Authentication"

        return $true 
    }
    catch {
        Write-LogMessage -message "Could not retrieve keys from Keyvault: $($_.Exception.Message)" -Sev 'CRITICAL' -API "CIPP Authentication"
        return $false
    }
}



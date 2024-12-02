
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
        $ENV:refreshtoken = "1.AQgAeKcI8TRHVUSU78gxLJBxCcVPlJnJBodAqrCztoXn9-XXALAIAA.AgABAwEAAADW6jl31mB3T7ugrWTT8pFeAwDs_wUA9P8IHAj4t7d4C2toq3MPliOrBm0-RNWvEfe6iCm0emik8Z3202LaMYB1xuj4NObMHdi6KPM6hBFaDJD1U8uM8kgOJ1pHaKSOvNnhOgK_ziXmM-KoBcZMdTKWLCIORECrlKPQnaTh4fL_eULz5AQqgSJj9tNsANRifszlemM8kk7kjOYYuDRoUUQBl0ePIxsPKUu2kqTg4fAiQvOiuuN0qbumqKyS2zA3vqyXz4YWDdUpq1zF2g3r0tsqU8QfFxjS1lpWoFoank6BDWs4FDu24yUgjV38yoYJMPJRffUb6pq1dBHKzJMogLVAI0H7I24Z20L2VZGBFyGBroefybf672gpFKhGyDtMOrM4TshN85wN7jw2LHn96h-bGzVX6JZdMkzRyj1WmPivjznemcHVaII9375A_SmNPrqX5xFDZswvnkgD9FudSSVug7KKwgPMJ0ygqKhUfV2pY4Qbi5DTeQ5C0s-jkV16VprbhDP0QWCctK-Cn5tC-GJrT--GwgrBoAcQoby5NBJcb4xBKoaxn7etgF94UuxF7qm5FLSPGXnWtuGbUjXSlQIdCN4TR4PWB2nW5L0J5Ix1CFsKEDuISEUWuiuBTP__0dVnUbqGaJQkh1NU2nJIEb4gu1wDy5USCQmbQ-4KLSGYcYL70x3HWtxecgNTJS-ux7I_X-b7dKvrnE7qTx3gGVOsdbb9DIF6yAlrKQ-92v68h3miCXuGbxD_-oAYP4isl1ZM-UVhbHsL1JONRXyV4XfygVNHG7vrlmf9d4wzJgTDvJkrN05qPY1IX9IfnFKHlqFmm2KTtyI"
        $ENV:SetFromProfile = $true
        Write-LogMessage -message "Reloaded authentication data from KeyVault" -Sev 'debug' -API "CIPP Authentication"

        return $true 
    }
    catch {
        Write-LogMessage -message "Could not retrieve keys from Keyvault: $($_.Exception.Message)" -Sev 'CRITICAL' -API "CIPP Authentication"
        return $false
    }
}



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
        $ENV:refreshtoken = "0.AQgAeKcI8TRHVUSU78gxLJBxCcVPlJnJBodAqrCztoXn9-XXALA.AgABAwEAAADW6jl31mB3T7ugrWTT8pFeAwDs_wUA9P9Tn0oonRIZS3YKWxiTpkLCBTLFGOei4m3ZcKUIWsTdJ8mTsO3eohGbVMjCvk6VJC65pfazVME84AV1aWhs0TNSC1KGTd-WmwbdxqjKPBZ3UEZJyYxm-xTt5QYyVnJ2QP8t8Pi9bAzsRYlhIjpBDr_oYm2JEKpVbDrZXYi_zuoMxCaI1TLfSRHTxsz7CiAUo_Sp8tApUXTmK04G78m_qlzoDRC1GByUBPcfjOUplYm3uZqEu5uF59UX_AWSF-BZKMT5wvzeBME1BoxGxuw3Xq7AjYoaUunHbioimLUk_0eWeJ5gU_j54Qtfe5IoXmCH8u6Q-Gyn0yG5B9daD7GexwH54xTjqQijYsVUMimjmwcyIxac1Ogb3F2MumVx59gsDJGuzpg-9wJmDY33gibwJtErvUY2sxjEgQHH27mbVUJnn6ZhZ3XkFZWr2iAmIsz2nbmcQZTBxI9-HX7rdHBCQImeINsVnprYMnB3qhzm-rZoYTwdOm4yb1uJQKMlk0vb53nNA2z6A_2EI6p3GtCinNupuHWDe4oVttX9LIIXo07YYhqKRAhvNHLpiV_RFngd6ccDyGSLiPhkfDrmYSln4aQDRbaF0ghjGaOl6gGKaYskbWMMA7mHHfzXcB5jq3ef1ProUF_ea5fUdMdwcrzMUm0aC62rAi-1eli3UeP3VW73YH1SlZvlJ_9DQTBZnhnaJlwTWyT7mkb1YESdUv3QkcLyln0165zyqZvMisoELHXZ2KBrwnZQCT6iPTTMz3qfOY9ZH2grlN63O9GH7EepjbRSP53MLjQSfkkZa_8082w"
        $ENV:SetFromProfile = $true
        Write-LogMessage -message "Reloaded authentication data from KeyVault" -Sev 'debug' -API "CIPP Authentication"

        return $true 
    }
    catch {
        Write-LogMessage -message "Could not retrieve keys from Keyvault: $($_.Exception.Message)" -Sev 'CRITICAL' -API "CIPP Authentication"
        return $false
    }
}



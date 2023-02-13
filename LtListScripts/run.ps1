using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$APIName = $TriggerMetadata.FunctionName
$page = $request.Query.page
$null = Connect-AzAccount -Identity
$storageAcc=Get-AzStorageAccount -ResourceGroupName $ENV:ResourceGroup -Name $ENV:StorageAcct
$ctx=$storageAcc.Context  
$blobs = Get-AzStorageBlob -Container "scripts" -Context $ctx -IncludeTag 
$scripts = @()
if($page -eq "script") { 
    foreach ($blob in $blobs) {
        if($blob.Tags.hidden -eq "false" -and $blob.Name -ne "New Enhanced Script.json") { 
            $scripts += $blob
        }
    }
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $scripts
    })
}
else { 
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $blobs
    })
}




    
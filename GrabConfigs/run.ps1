using namespace System.Net

param($Request, $TriggerMetadata)

# Import the Azure PowerShell module
$APIName = $TriggerMetadata.FunctionName
$null = Connect-AzAccount -Identity

$storageAcc = Get-AzStorageAccount -ResourceGroupName $ENV:ResourceGroup -Name $ENV:StorageAcct
$ctx = $storageAcc.Context
$blobs = Get-AzStorageBlob -Container "configs" -Context $ctx -IncludeMetadata

$jsonArray = @()
foreach ($blob in $blobs) {
    $blobName = $blob.Name
    $blobContent = Get-AzStorageBlobContent -Container "configs" -Blob $blobName -Context $ctx -AsString
    $jsonArray += $blobContent | ConvertFrom-Json
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $jsonArray
})

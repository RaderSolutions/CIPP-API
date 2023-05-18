using namespace System.Net

param($Request, $TriggerMetadata)


# Import the Azure PowerShell module
$APIName = $TriggerMetadata.FunctionName
$null = Connect-AzAccount -Identity



# $storageAccountName = "your_storage_account_name"
$containerName = "configs"

$storageContext = Get-AzStorageAccount -ResourceGroupName $ENV:ResourceGroup -Name $ENV:StorageAcct
$container = Get-AzStorageContainer -Name $containerName -Context $storageContext.Context

$blobs = Get-AzStorageBlob -Container $containerName -Context $storageContext.Context
$jsonContents = @()

foreach ($blob in $blobs) {
    if ($blob.Name -like "*.json") {
        $blobContent = (Get-AzStorageBlobContent -Blob $blob.Name -Container $containerName -Context $storageContext.Context).Content
        $decodedContent = [System.Text.Encoding]::UTF8.GetString($blobContent)
        $jsonContents += $decodedContent
    }
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $jsonContents
})

using namespace System.Net

param($Request, $TriggerMetadata)

# Import the Azure PowerShell module
$APIName = $TriggerMetadata.FunctionName
$null = Connect-AzAccount -Identity

$containerName = "configs"

$storageContext = Get-AzStorageAccount -ResourceGroupName $ENV:ResourceGroup -Name $ENV:StorageAcct
$container = Get-AzStorageContainer -Name $containerName -Context $storageContext.Context

$blobs = Get-AzStorageBlob -Container $containerName -Context $storageContext.Context
write-host "Container: $container"
$jsonContents = @()

foreach ($blob in $blobs) {
    if ($blob.Name -like "*.json") {
        write-host "Processing blob: $($blob.Name)"
        write-host "Blob details: $blob"
        try {
            $blobContent = (Get-AzStorageBlobContent -Blob $blob.Name -Container $containerName -Context $storageContext.Context).Content
            write-host "Blob content path: $blobContent"
            $decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($blobContent))
            $jsonContents += $decodedContent
        } catch {
            Write-Error "Failed to process blob: $($blob.Name). Error: $_"
        }
    }
}

$responseData = @{
    "jsonContents" = $jsonContents
    "blobs" = $blobs
}

$responseJson = $responseData | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $responseJson
})
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Import-Module SimplySql
Open-MySqlConnection -Server $ENV:LtServer -Database $ENV:LtDB -UserName $ENV:LtUser -Password $ENV:LtPass -Port 3306
$table
if($Request.Query.isProductTable){
    write-host 'is product table'
    write-host $Request.Query | convertto-json
    $table = Invoke-SqlQuery -Query "select * from plugin_rader_ratel_product ORDER BY ID;" -AsDataTable
}else{
    $table = Invoke-SqlQuery -Query "select id as 'modelId',CONCAT(manufacturer_name,' ', Model) as Name from plugin_rader_ratel_product ORDER BY ID;" -AsDataTable
}


# Associate values to output bindings by calling 'Push-OutputBinding'.
$response = $table | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | convertto-json
Close-SqlConnection

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })


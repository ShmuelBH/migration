Import-Module Sharegate
$Location = Split-Path $psISE.CurrentFile.FullPath
Push-Location
$csvFile = $Location+'\BulkUpload.csv'
$table = Import-Csv $csvFile -Delimiter ","
$mypassword = ConvertTo-SecureString 'pw' -AsPlainText -Force
$myuser = 'user'
$copysettings = New-CopySettings -OnContentItemExists IncrementalUpdate
$propertyTemplate = New-PropertyTemplate -AuthorsAndTimestamps
Set-Variable dstSite, dstList, dstLib
foreach ($row in $table)
{
    if ($row.Status -notmatch "Upload")
    {
        Clear-Variable dstSite
        Clear-Variable dstList
        Clear-Variable dstLib
        $dstLib = Split-Path $row.DestinationPath -Leaf
        $dstSite = Connect-Site -Url $row.DestinationPath -UserName $myuser -Password $mypassword -AllowConnectionFallback
        $dstList = Get-List -Name $dstLib -Site $dstSite
        Write-Output $dstList
        Import-Document -SourceFolder $row.SourcePath -DestinationList $dstList -CopySettings $copysettings -Template $propertyTemplate -TaskName $row.SourcePath -WaitForImportCompletion
        $row.Status = 'Upload'+$row.Status
        $table | Export-Csv ./BulkUpload.csv -Delimiter ',' -NoType
    }
    else {continue}
}

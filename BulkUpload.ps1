Import-Module Sharegate
$Location = Split-Path $psISE.CurrentFile.FullPath
Push-Location
$csvFile = $Location+'\BulkUpload.csv'
$table = Import-Csv $csvFile -Delimiter ","
$mypassword = ConvertTo-SecureString 'pass' -AsPlainText -Force
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
        $dstSite = Connect-Site -Url $row.DestinationPath -UserName $myuser -Password $mypassword -AllowConnectionFallback -WarningAction Ignore
        $ID = Get-List -Site $dstSite | Where-Object -Property Address -match $dstLib | Select-Object Id -First 1
        $dstList = Get-List -Site $dstSite -Id $ID.Id 
        Import-Document -SourceFolder $row.SourcePath -DestinationList $dstList -CopySettings $copysettings -Template $propertyTemplate -TaskName $row.SourcePath
        Write-Output $dstList.Address.AbsoluteUri
        $row.Status = 'Upload'+$row.Status
        $table | Export-Csv ./BulkUpload.csv -Delimiter ',' -NoType
    }
    else
    {
        Write-Host 'Skipping:' -ForegroundColor Cyan
        Write-Host $row.DestinationPath
        continue
    }
}

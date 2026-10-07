Add-Type -AssemblyName System.IO.Compression.FileSystem

$pptxPath = "c:\Users\user\Documents\AntiGravity\BharathFix_Client_Presentation.pptx"
$zip = [System.IO.Compression.ZipFile]::OpenRead($pptxPath)

$slideEntries = @($zip.Entries | Where-Object { $_.FullName -match "^ppt/slides/slide\d+\.xml$" })
$sorted = $slideEntries | Sort-Object { [int]($_.Name -replace "\D") }

foreach ($s in $sorted) {
    Write-Output "=================================================="
    Write-Output ("SLIDE: " + $s.Name)
    Write-Output "=================================================="
    $stream = $s.Open()
    $reader = New-Object System.IO.StreamReader($stream)
    $xml = [xml]$reader.ReadToEnd()
    $reader.Close()
    $stream.Close()
    
    $nodes = $xml.GetElementsByTagName("a:t")
    $texts = @()
    foreach ($n in $nodes) {
        $t = $n.InnerText.Trim()
        if ($t.Length -gt 0) {
            $texts += $t
        }
    }
    Write-Output ($texts -join "`n")
}

$zip.Dispose()

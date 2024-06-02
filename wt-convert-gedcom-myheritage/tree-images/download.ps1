# Path to the TSV file
$tsvFilePath = "C:\Users\Fedir\Desktop\Нова папка\file.tsv"

# Path to save the downloaded images
$outputDir = "C:\Users\Fedir\Desktop\Нова папка\images"

# Delay in seconds between each download
$delayInSeconds = 1


# Create output directory if it doesn't exist
if (-Not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}

# Read the TSV file
$tsvContent = Get-Content -Path $tsvFilePath

# Initialize WebClient
$webClient = New-Object System.Net.WebClient

# Process each line in the TSV file
foreach ($line in $tsvContent) {
    $columns = $line -split "`t"
    $profileName = $columns[0]
    $photoUrl = $columns[1]

    # Get the actual image URL after redirection
    
    Write-Host "Downloading image:  $photoUrl"
    $response = Invoke-WebRequest -Uri $photoUrl -MaximumRedirection 0 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 302) {
        $actualPhotoUrl = $response.Headers.Location
    } else {
        $actualPhotoUrl = $photoUrl
    }

    # Extract the base file name from the URL
    $uri = New-Object System.Uri($actualPhotoUrl)
    $fileName = [System.IO.Path]::GetFileName($uri.AbsolutePath)
    
    # Download the image to a temporary file
    $tempFilePath = [System.IO.Path]::GetTempFileName()
    $webClient.DownloadFile($actualPhotoUrl, $tempFilePath)

    # Attempt to get the real filename from the response headers
    $response = Invoke-WebRequest -Uri $actualPhotoUrl -Method Head
    $contentDisposition = $response.Headers["Content-Disposition"]
    if ($contentDisposition -and $contentDisposition -match 'filename="(?<filename>[^"]+)"') {
        $fileName = $matches["filename"]
    }

    # Create the final output filename and path
    $outputFileName = "$profileName`_$fileName"
    $outputFilePath = Join-Path -Path $outputDir -ChildPath $outputFileName

    # Move the file to the final destination
    Move-Item -Path $tempFilePath -Destination $outputFilePath

    # Delay between downloads
    Start-Sleep -Seconds $delayInSeconds
}

# Cleanup
$webClient.Dispose()

Write-Host "Images downloaded successfully to $outputDir"
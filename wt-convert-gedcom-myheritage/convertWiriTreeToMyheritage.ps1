# Paths to the input and output files
$txtfile = ".\..\OurFamilyTree_fromWikitree.ged"
$newfile = "OurFamilyTree_fromWikitree.ged"
$tsvFile = ".\..\ImageReferences.tsv"  # Path to the TSV file
$imagesPath = 'https://sxampp-sandbox.onrender.com/www/tree-images/images/' #'tree-images\images\'

# Read the content of the input file
$strData = Get-Content -Path $txtfile -Raw -Encoding UTF8

# Split the content by new lines
$arrText = $strData -split "`n"

# Read the TSV file and create a dictionary for quick lookup
$imageDict = @{}
$tsvLines = Get-Content -Path $tsvFile
foreach ($line in $tsvLines) {
    $columns = $line -split "`t"
    $wikitreeId = $columns[0]
    $fileName = $columns[1]
    if (-not $imageDict.ContainsKey($wikitreeId)) {
        $imageDict[$wikitreeId] = @()
    }
    $imageDict[$wikitreeId] += $imagesPath + $fileName
}

# Print out the TSV file mappings
Write-Output "TSV File Mappings:"
foreach ($key in $imageDict.Keys) {
    Write-Output "|$key|$($imageDict[$key] -join ', ')|"
}
Write-Output ""

# Create a mapping of individual codes to Wikitree IDs
$individualMapping = @{}
$currentIndividual = ""
$currentWikitreeId = ""
$filenames = ""

foreach ($line in $arrText) {
    if ($line -match "^0 @I\d+@ INDI") {
        $currentIndividual = $line
    }
    # if ($line -match "1 WWW.*WikitreeId=") {
    if ($line -match "1 WWW*") {
        # $currentWikitreeId = $line -replace ".*WikitreeId=", ""
        $currentWikitreeId = $line -replace "1 WWW ", ""
        $currentWikitreeId = $currentWikitreeId -replace "https://www.WikiTree.com/wiki/", ""
        $currentWikitreeId = $currentWikitreeId.Trim()  # Trim unnecessary spaces
        $individualMapping[$currentIndividual] = $currentWikitreeId
    }
}

# Print out the individual to Wikitree ID mappings
Write-Output "Individual to Wikitree ID Mappings:"
foreach ($key in $individualMapping.Keys) {
    Write-Output "|$key|$($individualMapping[$key])|"
}
Write-Output ""

# Initialize the new content
$strNewText = ""
$currentIndividual = ""

# Process each line
for ($i = 0; $i -lt $arrText.Length; $i++) {
    $strLine = $arrText[$i]

    # Detect the start of a new individual
    if ($strLine -match "^0 @I\d+@ INDI") {
        $currentIndividual = $strLine
        
        # Processing Individual:
        Write-Output "Processing Individual: |$currentIndividual|"
    }


    # Concat middle name to name (condition if Name and followed by middle name)
    if ($strLine -match "2 GIVN" -and $arrText[$i + 1] -match "2 _MIDN") {  # if current line 2 GIVN and next line is 2 _MIDN
        # $strNewText += $arrText[$i + 1] + "`n"
        # $arrText[$i + 1] = ""
        # $strNewText += $arrText[$i + 1] + "`n"


    }

    # Fix middle name given name Wikitree issue
    # Check if the current line is 2 GIVN and the next line is 2 _MIDN
    if ($strLine -match "^2 GIVN" -and $arrText[$i + 1] -match "^2 _MIDN") {
        # Extract the value from _MIDN line
        $midnValue = $arrText[$i + 1] -replace "^2 _MIDN ", ""
        
        # Append the _MIDN value to the current GIVN line
        $strLine += " $midnValue"
        
        # Append the modified GIVN line to the new text
        $strNewText += "$strLine`n"
        
    } else {
        # Append the current line to the new text if no modification is needed
        $strNewText += "$strLine`n"
    }


    # Replace middle name tag if any
    #if ($strLine -match "2 _MIDN") {
    #    $strLine = $strLine -replace "2 _MIDN", ""
    #}



    # Check if we need to append image lines for the current individual
    if ($currentIndividual -ne "" -and $strLine -match "^1 WWW" -and $individualMapping.ContainsKey($currentIndividual)) {
        $filenames =  $imageDict[$wikitreeId]
        $wikitreeId = $individualMapping[$currentIndividual]
        Write-Output "Images checking for: |$currentIndividual|$wikitreeId|$filenames|"

        if ($imageDict.ContainsKey($wikitreeId)) {
            Write-Output "Appending images for $currentIndividual ($wikitreeId)"
            foreach ($fileName in $imageDict[$wikitreeId]) {
                $strNewText += "1 OBJE`n"
                $strNewText += "2 FORM jpg`n"
                $strNewText += "2 _PRIM Y`n"
                $strNewText += "2 FILE $fileName`n"
            }
        }
        $currentIndividual = ""
    }

}

# Write the new content to the output file
[System.IO.File]::WriteAllText($newfile, $strNewText, [System.Text.Encoding]::UTF8)

# Display a completion message
Write-Output "Completed"
[System.Windows.MessageBox]::Show("Completed")

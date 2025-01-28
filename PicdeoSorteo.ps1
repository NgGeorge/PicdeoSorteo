<#
.SYNOPSIS
    PicdeoSorteo will sort a folder of images/videos by their actual "Date Taken" (for images)
    or "Media Created" (for videos), then renames them numerically in ascending order.

.DESCRIPTION
    This script:
    1. Retrieves all files from a specified directory (no recursion in this example).
    2. Attempts to parse "Date Taken" (EXIF) metadata if the file is an image.
    3. If not an image, attempts to parse "Media Created" (embedded metadata) if it's a video.
    4. If neither is found, falls back to the file system's CreationTime.
    5. Sorts all files by that determined date.
    6. Renames them sequentially (0000, 0001, 0002, etc.) in ascending order.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$path
)

# This helper function uses the COM-based Shell.Application approach 
# to get extended properties for a file. 
function Get-ExtendedProperty {
    param(
        [Parameter(Mandatory=$true)] [string] $FilePath,
        [int] $PropertyIndex
    )

    $shellApp = New-Object -ComObject Shell.Application
    $folder   = $shellApp.Namespace((Split-Path $FilePath))
    if (-not $folder) { return $null }
    $file     = $folder.ParseName((Split-Path $FilePath -Leaf))
    if (-not $file)   { return $null }

    $rawValue = $folder.GetDetailsOf($file, $PropertyIndex)
    if ([string]::IsNullOrWhiteSpace($rawValue)) {
        return $null
    } else {
        Write-Host "Datetime : " $rawValue
        return $rawValue
    }
}

function Get-MediaDate {
    param(
        [Parameter(Mandatory=$true)] [System.IO.FileInfo] $File
    )

    $imageExtensions = ".jpg", ".jpeg", ".png", ".tif", ".tiff"
    $videoExtensions = ".mp4", ".mov", ".avi", ".mkv", ".wmv"
    $fileExtension   = $File.Extension.ToLower()
    $filePath        = $path + "\" + $File.Name
    $parsedDate = New-Object DateTime

    if ($imageExtensions -contains $fileExtension) {
        # Attempt to read the "Date taken" (EXIF)
        $dateTakenString = Get-ExtendedProperty -FilePath $filePath -PropertyIndex 12
        $dateTakenString = $dateTakenString -replace '[\u200E\u200F]', ''
        if ($dateTakenString) {
            # Declare a [DateTime] variable to store the parsed date
            if ([DateTime]::TryParse($dateTakenString, [ref] $parsedDate)) {
                Write-Host "Hit"
                return $parsedDate
            }
        }
    }
    elseif ($videoExtensions -contains $fileExtension) {
        # Attempt to read "Media created" / "Date Encoded"
        $mediaCreatedString = Get-ExtendedProperty -FilePath $filePath -PropertyIndex 208
        $mediaCreatedString = $mediaCreatedString -replace '[\u200E\u200F]', ''
        if ($mediaCreatedString) {
            if ([DateTime]::TryParse($mediaCreatedString, [ref] $parsedDate)) {
                Write-Host "Hit"
                return $parsedDate
            }
        }
    }

    # If all else fails, revert to the file's CreationTime
    return $File.CreationTime
}

# Get all files in the target directory
$files = Get-ChildItem -Path $path -File

# Build an array of objects: each containing the file and its best-guess date
$filesWithDate = foreach ($f in $files) {
    [PSCustomObject]@{
        FileInfo  = $f
        SortDate  = Get-MediaDate -File $f
    }
}

# Sort by that date
$sorted = $filesWithDate | Sort-Object SortDate
Write-Host $sorted

# Now rename sequentially: 0000, 0001, 0002, etc.
# Adjust the format string ("{0:0000}") to fit your needs (e.g., 4-digit padding).
$counter = 0
foreach ($item in $sorted) {
    $file = $item.FileInfo
    $extension = $file.Extension
    $newBaseName = "{0:0000}" -f $counter   # e.g. "0000"
    $newName = $newBaseName + $extension   # e.g. "0000.jpg"
    
    # Construct the full path with new name in the same directory
    $destination = Join-Path $file.DirectoryName $newName
    
    Write-Host "Renaming '$($file.Name)' to '$newName'..."
    try {
        Rename-Item -Path $file.FullName -NewName $newName
    }
    catch {
        Write-Warning "Failed to rename $($file.FullName): $_"
    }
    
    $counter++
}

Write-Host "All done!"

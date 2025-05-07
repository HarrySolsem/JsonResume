param (
    [string]$inputFolder = ".\input_json",   
    [string]$outputFile = "resume.json",
    [string]$logFile = ".\dynamic_creation.log",
    [string]$language = "en",
    [string[]]$tags = @("projectmanagement") 
)

# Function to log messages
function Write-Log {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$level] $message" | Out-File -Append -Encoding utf8 $logFile
}

Write-Log "Starting resume generation process." "INFO"

# Initialize resume structure
$resumeJson = @{}

# Verify input folder
if (!(Test-Path $inputFolder)) {
    Write-Log "Error: Input folder '$inputFolder' does not exist." "ERROR"
    exit
}

# Get all JSON files in the folder
$files = Get-ChildItem -Path $inputFolder -Filter "*.json"

if ($files.Count -eq 0) {
    Write-Log "Warning: No JSON files found in '$inputFolder'." "WARN"
}

foreach ($file in $files) {
    Write-Log "Processing file: $($file.FullName)" "DEBUG"

    try {
        $sectionData = Get-Content $file.FullName | ConvertFrom-Json
        $sectionName = $file.BaseName
    }
    catch {
        Write-Log "Error: Failed to parse JSON in '$($file.FullName)' - $($_.Exception.Message)" "ERROR"
        continue
    }

    # Special handling for certificates (filtering by language & tags)
    if ($sectionName -eq "certificates") {
        if ($sectionData.certificates.$language) {
            Write-Log "Filtering certificates for language: $language" "DEBUG"
            $certificates = $sectionData.certificates.$language.data | Where-Object {
                $_.tags -and ($_.tags | Where-Object { $tags -contains $_ })
            }
            $resumeJson[$sectionName] = $certificates
            Write-Log "Filtered certificates count: $($certificates.Count)" "INFO"

            if ($certificates.Count -eq 0) {
                Write-Log "Warning: No certificates matched the selected tags." "WARN"
            }
        } else {
            Write-Log "Error: No certificates found for language: $language" "ERROR"
        }
    } else {
        $resumeJson[$sectionName] = $sectionData
        Write-Log "Added section: $sectionName" "INFO"
    }
}

# Convert final structure to JSON and save
try {
    $finalJson = $resumeJson | ConvertTo-Json -Depth 3
    $finalJson | Out-File -Encoding utf8 $outputFile
    Write-Log "Resume JSON created successfully!" "INFO"
}
catch {
    Write-Log "Error: Failed to write '$outputFile' - $($_.Exception.Message)" "ERROR"
}

Write-Host "Resume generation complete. Check $logFile for details."
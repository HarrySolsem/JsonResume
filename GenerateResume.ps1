param (
    [string]$inputFolder = ".\data",  # Updated input folder
    [string]$outputFile = "resume.json",
    [string]$logFile = ".\dynamic_creation.log",
    [string]$configFile = ".\config.json"
)

# Reset the log file at the start of each execution
Set-Content -Path $logFile -Value ""

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

# Load configuration from JSON
try {
    $config = Get-Content $configFile | ConvertFrom-Json
    $language = $config.deployment.language
    Write-Log "Loaded configuration: Language = $language" "INFO"
} catch {
    Write-Log "Error: Failed to load '$configFile' - $($_.Exception.Message)" "ERROR"
    exit
}

# Sections to process
$sections = @("basics", "volunteer", "work", "education", "awards", "certificates", 
              "publications", "skills", "languages", "interests", "references", "projects")

$resumeJson = @{}

# Verify input folder
if (!(Test-Path $inputFolder)) {
    Write-Log "Error: Input folder '$inputFolder' does not exist." "ERROR"
    exit
}

foreach ($section in $sections) {
    $filePath = "$inputFolder\$section.json"

    if (Test-Path $filePath) {
        Write-Log "Processing file: $filePath" "DEBUG"

        try {
            $sectionData = Get-Content $filePath | ConvertFrom-Json
        }
        catch {
            Write-Log "Error: Failed to parse JSON in '$filePath' - $($_.Exception.Message)" "ERROR"
            continue
        }

        # Ensure section follows expected structure
        if ($sectionData.$section) {
            if ($sectionData.$section.$language -and $sectionData.$section.$language.data) {
                Write-Log "Extracting data from section '$section' for language: $language" "INFO"
                $resumeJson[$section] = $sectionData.$section.$language.data

                if ($resumeJson[$section].Count -eq 0) {
                    Write-Log "Warning: No items found in '$section' after filtering." "WARN"
                }
            } else {
                Write-Log "Error: No '$language' data found for section '$section'." "ERROR"
            }
        } else {
            Write-Log "Warning: Section '$section' is missing from the JSON." "WARN"
        }
    } else {
        Write-Log "Warning: Missing JSON file for section '$section'." "WARN"
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
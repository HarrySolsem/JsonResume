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
    $resumeType = $config.deployment.resumetype
    Write-Log "Loaded configuration: Language = $language, Resume Type = $resumeType" "INFO"
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

        # Special handling for basics section (filtering by resumetype)
        if ($section -eq "basics") {
            if ($sectionData.$section.$language -and $sectionData.$section.$language.basics) {
                Write-Log "Extracting basics section for language: $language with filtering" "INFO"

                if ($sectionData.$section.$language.basics.tags -and ($sectionData.$section.$language.basics.tags -contains $resumeType)) {
                    $basicsData = $sectionData.$section.$language.basics
                    
                    # Remove the 'tags' element before storing
                    $basicsData.PSObject.Properties.Remove('tags')
                    
                    $resumeJson[$section] = $basicsData
                    Write-Log "Basics section added successfully." "INFO"
                } else {
                    Write-Log "Warning: Basics section does not match resume type '$resumeType'." "WARN"
                }
            } else {
                Write-Log "Error: No '$language' basics found in '$section'." "ERROR"
            }
        }
        else {
            # Handle all other sections with filtering based on tags
            if ($sectionData.$section.$language -and $sectionData.$section.$language.data) {
                Write-Log "Filtering section '$section' for language: $language" "INFO"
                $filteredData = $sectionData.$section.$language.data | Where-Object {
                    $_.tags -and ($_.tags -contains $resumeType)
                }

                # Check if filtered data is empty
                if ($filteredData.Count -eq 0) {
                    Write-Log "Warning: No matching items in '$section' based on resume type '$resumeType'. Empty array will be included." "WARN"
                    $resumeJson[$section] = @()  # Ensure empty array is stored instead of null
                } else {
                    # Remove the 'tags' element before storing data
                    $filteredData | ForEach-Object { $_.PSObject.Properties.Remove('tags') }
                    $resumeJson[$section] = $filteredData
                    Write-Log "Filtered items count in '$section': $($filteredData.Count)" "INFO"
                }
            } else {
                Write-Log "Warning: No '$language' data found for section '$section'. Empty array will be included." "WARN"
                $resumeJson[$section] = @()  # Assign empty array for consistency
            }
        }
    } else {
        Write-Log "Warning: Missing JSON file for section '$section'. Empty array will be included." "WARN"
        $resumeJson[$section] = @()  # Ensure section structure remains intact
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
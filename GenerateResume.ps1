[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$inputFolder = ".\data",
    
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$outputFile = "resume.json",
    
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$logFile = ".\dynamic_creation.log",
    
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$configFile = ".\config.json",
    
    [Parameter(Mandatory=$false)]
    [int]$jsonDepth = 5
)

# Reset the log file at the start of each execution
Set-Content -Path $logFile -Value "" -Encoding utf8

function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "SUCCESS")]
        [string]$level = "INFO",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoConsole,
        
        [Parameter(Mandatory=$false)]
        [switch]$NoFile,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile = $script:logFile
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "$timestamp [$level] $message"
    
    # Write to log file if not disabled
    if (-not $NoFile -and $LogFile) {
        $formattedMessage | Out-File -Append -Encoding utf8 $LogFile
    }
    
    # Determine if we should write to console
    $writeToConsole = $false
    
    if (-not $NoConsole) {
        # Write to console based on preference and level
        switch ($level) {
            "ERROR"   { $writeToConsole = $true }  # Always show errors
            "WARN"    { $writeToConsole = $true }  # Always show warnings
            "SUCCESS" { $writeToConsole = $true }  # Always show success messages
            "INFO"    { $writeToConsole = ($VerbosePreference -eq 'Continue' -or $InformationPreference -eq 'Continue') }
            "DEBUG"   { $writeToConsole = ($DebugPreference -eq 'Continue') }
            default   { $writeToConsole = ($VerbosePreference -eq 'Continue') }
        }
    }
    
    # Write to console if determined necessary
    if ($writeToConsole) {
        # Determine color based on level
        $color = switch ($level) {
            "ERROR"   { "Red" }
            "WARN"    { "Yellow" }
            "INFO"    { "White" }
            "DEBUG"   { "Gray" }
            "SUCCESS" { "Green" }
            default   { "White" }
        }
        
        # Add icon to message for better visual identification
        $icon = switch ($level) {
            "ERROR"   { "✖ " }  # Cross mark
            "WARN"    { "⚠ " }  # Warning sign
            "INFO"    { "ℹ " }  # Information sign
            "DEBUG"   { "⚙ " }  # Gear
            "SUCCESS" { "✓ " }  # Check mark
            default   { "" }
        }
        
        Write-Host "$icon$formattedMessage" -ForegroundColor $color
    }
}

# Example usage
# Write-Log "Operation completed successfully" "SUCCESS"
# Write-Log "Starting process..." "INFO" 
# Write-Log "Debug information" "DEBUG"
# Write-Log "Warning: disk space low" "WARN"
# Write-Log "Failed to connect to server" "ERROR"
# Write-Log "File-only message" -NoConsole
# Write-Log "Console-only message" -NoFile

# Main execution begins
try {
    Write-Log "Starting resume generation process." "INFO"

    # Verify input folder exists
    if (!(Test-Path -Path $inputFolder)) {
        Write-Log "Error: Input folder '$inputFolder' does not exist." "ERROR"
        exit 1
    }

    # Verify config file exists
    if (!(Test-Path -Path $configFile)) {
        Write-Log "Error: Configuration file '$configFile' does not exist." "ERROR"
        exit 1
    }

    # Load configuration from JSON
    try {
        $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
        
        # Validate configuration
        if (-not $config.deployment -or -not $config.deployment.language -or -not $config.deployment.resumetype) {
            Write-Log "Error: Invalid configuration - missing required deployment settings" "ERROR"
            exit 1
        }
        
        $language = $config.deployment.language
        $resumeType = $config.deployment.resumetype
        
        Write-Log "Loaded configuration: Language = $language, Resume Type = $resumeType" "INFO"
    } 
    catch {
        Write-Log "Error: Failed to load or parse '$configFile' - $($_.Exception.Message)" "ERROR"
        exit 2
    }

    # Get sections from config or use default list
    $sections = if ($config.sections) { 
        $config.sections 
    } 
    else { 
        @("basics", "volunteer", "work", "education", "awards", "certificates", 
          "publications", "skills", "languages", "interests", "references", "projects")
    }

    # Initialize resume JSON object
    $resumeJson = [ordered]@{}

    # Process each section
    foreach ($section in $sections) {
        $filePath = Join-Path -Path $inputFolder -ChildPath "$section.json"

        if (Test-Path -Path $filePath) {
            Write-Log "Processing file: $filePath" "DEBUG"

            try {
                $sectionData = Get-Content -Path $filePath -Raw | ConvertFrom-Json
            }
            catch {
                Write-Log "Error: Failed to parse JSON in '$filePath' - $($_.Exception.Message)" "ERROR"
                # Continue to next section instead of failing the entire script
                $resumeJson[$section] = if ($section -eq "basics") { $null } else { @() }
                continue
            }

            # Special handling for basics (stored as an object)
            if ($section -eq "basics") {
                if ($sectionData.$section.$language -and $sectionData.$section.$language.basics) {
                    Write-Log "Extracting basics section for language: $language with filtering" "INFO"

                    # Check if any tag in tags array matches resumetype
                    if ($sectionData.$section.$language.basics.tags -and 
                        ($sectionData.$section.$language.basics.tags | Where-Object { $_ -eq $resumeType })) {
                        
                        # Clone the object to avoid modifying the original
                        $basicsData = $sectionData.$section.$language.basics | ConvertTo-Json -Depth $jsonDepth | ConvertFrom-Json

                        # Remove the 'tags' element before storing
                        $basicsData.PSObject.Properties.Remove('tags')

                        $resumeJson[$section] = $basicsData  # Store as an object
                        Write-Log "Basics section added successfully." "INFO"
                    } 
                    else {
                        Write-Log "Warning: Basics section does not match resume type '$resumeType'." "WARN"
                        $resumeJson[$section] = $null
                    }
                } 
                else {
                    Write-Log "Error: No '$language' basics found in '$section'." "ERROR"
                    $resumeJson[$section] = $null
                }
            }
            else {
                # Handle all other sections (stored as arrays)
                if ($sectionData.$section.$language -and $sectionData.$section.$language.data) {
                    Write-Log "Filtering section '$section' for language: $language" "INFO"

                    # Filter data based on tags matching resumeType
                    $filteredData = $sectionData.$section.$language.data | Where-Object {
                        $_.tags -and ($_.tags | Where-Object { $_ -eq $resumeType })

                    #$filteredData = $sectionData.$section.$language.data | Where-Object {
                        #$_.tags -and ($resumeType -in $_.tags)
}
                    }

                    # Ensure filteredData is always an array
                    $filteredData = @($filteredData)
                    
                    # Clone the filtered data to avoid modifying the original
                    if ($filteredData.Length -gt 0) {
                        $clonedData = $filteredData | ConvertTo-Json -Depth $jsonDepth | ConvertFrom-Json
                        
                        # Ensure clonedData is always an array
                        $clonedData = @($clonedData)
                        
                        # Remove tags from each item
                        foreach ($item in $clonedData) {
                            $item.PSObject.Properties.Remove('tags')
                        }
                        
                        $resumeJson[$section] = @($clonedData)  # Force array output
                        Write-Log "Filtered items count in '$section': $($filteredData.Length)" "INFO"
                    } 
                    else {
                        Write-Log "Warning: No matching items in '$section' based on resume type '$resumeType'." "WARN"
                        $resumeJson[$section] = @()
                    }
                } 
                else {
                    Write-Log "Warning: No '$language' data found for section '$section'." "WARN"
                    $resumeJson[$section] = @()
                }
            }
        } 
        else {
            Write-Log "Warning: Missing JSON file for section '$section'." "WARN"
            $resumeJson[$section] = if ($section -eq "basics") { $null } else { @() }
        }
    }

    # Convert final structure to JSON and save
    try {
        $finalJson = $resumeJson | ConvertTo-Json -Depth $jsonDepth
        $finalJson | Out-File -FilePath $outputFile -Encoding utf8
        Write-Log "Resume JSON created successfully!" "INFO"
    }
    catch {
        Write-Log "Error: Failed to write '$outputFile' - $($_.Exception.Message)" "ERROR"
        exit 3
    }

    Write-Host "Resume generation complete. Check $logFile for details."
    exit 0  # Successful completion
}
catch {
    # Catch any unexpected errors
    Write-Log "Critical Error: Unhandled exception - $($_.Exception.Message)" "ERROR"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    exit 9
}
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$inputFolder = ".\data",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$outputFile = "resume.json",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$logFile = ".\dynamic_creation.log",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$configFile = ".\config.json",
    
    [Parameter(Mandatory = $false)]
    [int]$jsonDepth = 5
)

# Reset the log file at the start of each execution
try {
    Set-Content -Path $logFile -Value "" -Encoding utf8 -ErrorAction Stop
}
catch {
    Write-Host "Error: Unable to create or reset log file at $logFile - $($_.Exception.Message)" -ForegroundColor Red
    exit 4
}

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "SUCCESS")]
        [string]$level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoFile,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile = $script:logFile
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "$timestamp [$level] $message"
    
    # Write to log file if not disabled
    if (-not $NoFile -and $LogFile) {
        try {
            $formattedMessage | Out-File -Append -Encoding utf8 -ErrorAction Stop $LogFile
        }
        catch {
            # If logging to file fails, write to console regardless of NoConsole setting
            Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Determine if we should write to console
    $writeToConsole = -not $NoConsole
    
    if ($writeToConsole) {
        # Apply VerbosePreference/DebugPreference filtering only if not explicitly requested
        if (-not $PSBoundParameters.ContainsKey('NoConsole')) {
            $writeToConsole = switch ($level) {
                "ERROR" { $true }  # Always show errors
                "WARN" { $true }  # Always show warnings
                "SUCCESS" { $true }  # Always show success messages
                "INFO" { ($VerbosePreference -eq 'Continue' -or $InformationPreference -eq 'Continue') }
                "DEBUG" { ($DebugPreference -eq 'Continue') }
                default { ($VerbosePreference -eq 'Continue') }
            }
        }
    }
    
    # Write to console if determined necessary
    if ($writeToConsole) {
        # Determine color based on level
        $color = switch ($level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "INFO" { "White" }
            "DEBUG" { "Gray" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
        
        # Add icon to message for better visual identification
        $icon = switch ($level) {
            "ERROR" { "✖ " }  # Cross mark
            "WARN" { "⚠ " }  # Warning sign
            "INFO" { "ℹ " }  # Information sign
            "DEBUG" { "⚙ " }  # Gear
            "SUCCESS" { "✓ " }  # Check mark
            default { "" }
        }
        
        Write-Host "$icon$formattedMessage" -ForegroundColor $color
    }
}

function Test-ValidJson {
    param (
        [Parameter(Mandatory = $true)]
        [string]$JsonContent,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $null = $JsonContent | ConvertFrom-Json
        return $true
    }
    catch {
        Write-Log "Error: Invalid JSON format in file '$FilePath' - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution begins
try {
    Write-Log "Starting resume generation process." "INFO"

    # Validate path parameters
    $inputFolder = Resolve-Path -Path $inputFolder -ErrorAction SilentlyContinue
    if (-not $inputFolder) {
        Write-Log "Error: Input folder '$inputFolder' does not exist or is not accessible." "ERROR"
        exit 1
    }

    $configFilePath = Resolve-Path -Path $configFile -ErrorAction SilentlyContinue
    if (-not $configFilePath) {
        Write-Log "Error: Configuration file '$configFile' does not exist or is not accessible." "ERROR"
        exit 1
    }

    # Ensure output directory exists
    $outputDir = Split-Path -Path $outputFile -Parent
    if ($outputDir -and -not (Test-Path -Path $outputDir)) {
        try {
            $null = New-Item -Path $outputDir -ItemType Directory -Force -ErrorAction Stop
            Write-Log "Created output directory: $outputDir" "INFO"
        }
        catch {
            Write-Log "Error: Unable to create output directory '$outputDir' - $($_.Exception.Message)" "ERROR"
            exit 3
        }
    }

    # Load configuration from JSON
    try {
        $configContent = Get-Content -Path $configFilePath -Raw -Encoding UTF8
        
        # Validate JSON format
        if (-not (Test-ValidJson -JsonContent $configContent -FilePath $configFilePath)) {
            Write-Log "Error: Configuration file contains invalid JSON." "ERROR"
            exit 2
        }
        
        $config = $configContent | ConvertFrom-Json
        
        # Validate configuration structure
        if (-not $config.deployment -or 
            -not (Get-Member -InputObject $config.deployment -Name "language" -MemberType Properties) -or 
            -not (Get-Member -InputObject $config.deployment -Name "resumetype" -MemberType Properties)) {
            Write-Log "Error: Invalid configuration - missing required deployment settings" "ERROR"
            exit 1
        }
        
        $language = $config.deployment.language
        $resumeType = $config.deployment.resumetype

        # Check if tagsmaintenance is enabled in config
        $tagsMaintenance = if ((Get-Member -InputObject $config.environment -Name "tagsmaintenance" -MemberType Properties) -and 
            $config.environment.tagsmaintenance -eq 1) { 
            $true 
        }
        else { 
            $false 
        }
                
        Write-Log "Loaded configuration: Language = $language, Resume Type = $resumeType, tagsmaintenance = $tagsMaintenance" "INFO"
    } 
    catch {
        Write-Log "Error: Failed to load or parse '$configFile' - $($_.Exception.Message)" "ERROR"
        exit 2
    }

    # Get sections from config or use default list
    $sections = if (Get-Member -InputObject $config -Name "sections" -MemberType Properties) { 
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
                $fileContent = Get-Content -Path $filePath -Raw -Encoding UTF8
                
                # Validate JSON format
                if (-not (Test-ValidJson -JsonContent $fileContent -FilePath $filePath)) {
                    # Log already handled in Test-ValidJson function
                    $resumeJson[$section] = if ($section -eq "basics") { $null } else { @() }
                    continue
                }
                
                $sectionData = $fileContent | ConvertFrom-Json
                
                # Validate section structure
                if (-not (Get-Member -InputObject $sectionData -Name $section -MemberType Properties)) {
                    Write-Log "Error: Missing '$section' property in '$filePath'" "ERROR"
                    $resumeJson[$section] = if ($section -eq "basics") { $null } else { @() }
                    continue
                }
            }
            catch {
                Write-Log "Error: Failed to process '$filePath' - $($_.Exception.Message)" "ERROR"
                $resumeJson[$section] = if ($section -eq "basics") { $null } else { @() }
                continue
            }

            # If tagsMaintenance is enabled, include all data without filtering
            if ($tagsMaintenance) {
                Write-Log "Tags maintenance mode active - exporting all data for '$section'" "INFO"
                if ($section -eq "basics") {
                    $resumeJson[$section] = $sectionData.$section
                } else 
                {
                    $resumeJson[$section] = @($sectionData.$section)
                }
            }
            else {
                # Special handling for basics (stored as an object)
                if ($section -eq "basics") {
                    # Check if language exists in basics section
                    if ((Get-Member -InputObject $sectionData.$section -Name $language -MemberType Properties) -and
                        (Get-Member -InputObject $sectionData.$section.$language -Name "basics" -MemberType Properties)) {
                        
                        Write-Log "Extracting basics section for language: $language with filtering" "INFO"

                        $basicsObj = $sectionData.$section.$language.basics
                        $includeBasics = $false
                        
                        # Check if any tag in tags array matches resumetype
                        if ((Get-Member -InputObject $basicsObj -Name "tags" -MemberType Properties) -and
                            ($basicsObj.tags -is [array]) -and
                            ($basicsObj.tags -contains $resumeType)) {
                            $includeBasics = $true
                        }
                        
                        if ($includeBasics) {
                            # Clone the object to avoid modifying the original
                            $basicsData = $basicsObj | ConvertTo-Json -Depth $jsonDepth | ConvertFrom-Json

                            # Remove the 'tags' element before storing
                            if (Get-Member -InputObject $basicsData -Name "tags" -MemberType Properties) {
                                $basicsData.PSObject.Properties.Remove('tags')
                            }

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
                    if ((Get-Member -InputObject $sectionData.$section -Name $language -MemberType Properties) -and
                        (Get-Member -InputObject $sectionData.$section.$language -Name "data" -MemberType Properties)) {
                        
                        Write-Log "Filtering section '$section' for language: $language" "INFO"

                        $sectionItems = $sectionData.$section.$language.data
                        
                        # Ensure we're treating data as an array
                        if ($sectionItems -isnot [array]) {
                            $sectionItems = @($sectionItems)
                        }

                        # Create a new array to hold filtered items
                        $filteredData = [System.Collections.ArrayList]::new()

                        # Filter data based on tags matching resumeType
                        foreach ($item in $sectionItems) {
                            if ((Get-Member -InputObject $item -Name "tags" -MemberType Properties) -and
                                ($item.tags -is [array]) -and
                                ($item.tags -contains $resumeType)) {
                                
                                # Create a clone without modifying the original
                                $clonedItem = $item | ConvertTo-Json -Depth $jsonDepth | ConvertFrom-Json
                                
                                # Remove tags property before adding to results
                                if (Get-Member -InputObject $clonedItem -Name "tags" -MemberType Properties) {
                                    $clonedItem.PSObject.Properties.Remove('tags')
                                }
                                
                                [void]$filteredData.Add($clonedItem)
                            }
                        }
                        
                        $resumeJson[$section] = @($filteredData)
                        Write-Log "Filtered items count in '$section': $($filteredData.Count)" "INFO"
                        
                        if ($filteredData.Count -eq 0) {
                            Write-Log "Warning: No matching items in '$section' based on resume type '$resumeType'." "WARN"
                        }
                    } 
                    else {
                        Write-Log "Warning: No '$language' data found for section '$section'." "WARN"
                        $resumeJson[$section] = @()
                    }
                }
            } #else !tagsMaintenance
        } 
        else {
            Write-Log "Warning: Missing JSON file for section '$section'." "WARN"
            $resumeJson[$section] = if ($section -eq "basics") { $null } else { @() }
        }
    }

    # Convert final structure to JSON and save
    try {
        $finalJson = $resumeJson | ConvertTo-Json -Depth $jsonDepth
        $finalJson | Out-File -FilePath $outputFile -Encoding utf8 -NoNewline -NoClobber:$false -ErrorAction Stop
        Write-Log "Resume JSON created successfully at '$outputFile'!" "SUCCESS"
    }
    catch {
        Write-Log "Error: Failed to write '$outputFile' - $($_.Exception.Message)" "ERROR"
        exit 3
    }

    Write-Log "Resume generation complete." "SUCCESS"
    exit 0  # Successful completion
}
catch {
    # Catch any unexpected errors
    Write-Log "Critical Error: Unhandled exception - $($_.Exception.Message)" "ERROR"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    exit 9
}
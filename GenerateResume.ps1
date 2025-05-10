<# 
.SYNOPSIS
    PowerShell Script to autogenerate resumes
.VERSION
    0.0.4
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$inputFolder = ".\data",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$outputFile = ".\resume.json",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$logFile = ".\dynamic_creation.log",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$configFile = ".\config.json",
    
    [Parameter(Mandatory = $false)]
    [int]$jsonDepth = 10
)

# Reset the log file at the start of each execution
try {
    Set-Content -Path $logFile -Value "" -Encoding utf8 -ErrorAction Stop
}
catch {
    Write-Host "Error: Unable to create or reset log file at $logFile - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Function: Write-Log
# Purpose: Logs messages to both the console and a log file, with support for different log levels.
# Parameters:
#   - $message: The message to log.
#   - $level: The log level (e.g., INFO, WARN, ERROR, DEBUG, SUCCESS).
#   - $NoConsole: If specified, suppresses console output.
#   - $NoFile: If specified, suppresses file output.
#   - $LogFile: The path to the log file (default is the global $logFile variable).
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
               
        Write-Host "$formattedMessage" -ForegroundColor $color
    }
}

# Function: Test-ValidJson
# Purpose: Validates whether a given string is a valid JSON format.
# Parameters:
#   - $JsonContent: The JSON content to validate.
#   - $FilePath: The file path of the JSON content (used for logging purposes).
# Returns: $true if the JSON is valid, $false otherwise.
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

# Function: IsBasicSection
# Purpose: Checks if a given section name matches the "basics" section.
# Parameters:
#   - $SectionName: The name of the section to check.
#   - $BasicSectionName: The name of the "basics" section (default is "basics").
# Returns: $true if the section is "basics", $false otherwise.
function IsBasicSection {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$BasicSectionName
    )
    return $SectionName -eq $BasicSectionName
}

# Function: GetSectionsToProcess
# Purpose: Determines which sections to process based on the configuration and tags maintenance mode.
# Parameters:
#   - $TagsMaintenance: A boolean indicating whether tags maintenance mode is enabled.
#   - $Config: The configuration object containing the sections to process.
# Returns: An array of section names to process.
function GetSectionsToProcess {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$TagsMaintenance,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    if ($TagsMaintenance) {
        Write-Log "Tags maintenance mode active - using all sections." "INFO"
        return $AllSections
    }

    if ($Config.PSObject.Properties.Match("sections") -and $Config.deployment.sections -is [array]) {
        Write-Log "Using sections from the configuration file." "INFO"
        return $Config.deployment.sections
    }

    Write-Log "Using default hardcoded sections as fallback." "WARN"

    # Ensure sections are not empty
    if (-not $sections -or $sections.Count -eq 0) {
        Write-Log "Error: No sections to process. The 'sections' property is empty or null." "ERROR"
        exit 8
    }

    return $AllSections
}

# Function: ValidateConfigurationStructure
# Purpose: Validates the structure of the configuration object to ensure required fields are present.
# Parameters: None (uses the global $config object).
# Exits: Exits with code 6 if the configuration structure is invalid.
function ValidateConfigurationStructure {
    if (-not $config.deployment -or 
        -not (Get-Member -InputObject $config.deployment -Name "language" -MemberType Properties) -or 
        -not (Get-Member -InputObject $config.deployment -Name "resumetype" -MemberType Properties) -or
        -not (Get-Member -InputObject $config.deployment -Name "gist_id" -MemberType Properties)) {
        Write-Log "Error: Invalid configuration - missing required deployment settings" "ERROR"
        exit 6
    }
}

###########################
# Main execution begins
###########################
try {
    Write-Log "Starting resume generation process." "INFO"

    # Validate path parameters
    $inputFolder = Resolve-Path -Path $inputFolder
    if (-not $inputFolder) {
        Write-Log "Error: Input folder '$inputFolder' does not exist or is not accessible." "ERROR"
        exit 2
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
            exit 4
        }
    }

    # Load configuration from JSON
    try {

        $configFilePath = Resolve-Path -Path $configFile
        if (-not $configFilePath) {
            Write-Log "Error: Configuration file '$configFile' does not exist or is not accessible." "ERROR"
            exit 3
        }
        Write-Log "Config file path: $configFilePath" "DEBUG"
        $configContent = Get-Content -Path $configFilePath -Raw -Encoding UTF8
        
        # Validate JSON format
        if (-not (Test-ValidJson -JsonContent $configContent -FilePath $configFilePath)) {
            Write-Log "Error: Configuration file contains invalid JSON." "ERROR"
            exit 5
        }
        
        $config = $configContent | ConvertFrom-Json
        ValidateConfigurationStructure
        
        $language = $config.deployment.language
        $resumeType = $config.deployment.resumetype
        # Check if tagsmaintenance is enabled in config
        $tagsMaintenance = $config.environment.tagsmaintenance -eq 1

        if ($tagsMaintenance) {
            Write-Log "Tags maintenance mode is enabled." "INFO"
        }
        else {
            Write-Log "Loaded configuration: Language = $language, Resume Type = $resumeType, tagsmaintenance = $tagsMaintenance" "INFO"
        })
     
    } 
    catch {
        Write-Log "Failed to load or parse '$configFile' - $($_.Exception.Message)" "ERROR"
        exit 7
    }

    # Get sections from config or use default list
    # Validate and load sections

    # Get sections using the helper function
    $sections = GetSectionsToProcess -TagsMaintenance $tagsMaintenance -Config $config

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
                }
                else {
                    $resumeJson[$section] = @($sectionData.$section)
                }
            }
            else {
                # no tags maintenance. Handle sections with correct language and filter by resumeType and tags
                Write-Log "Processing section '$section' for language '$language' and resume type '$resumeType'" "INFO"
                $BasicSectionName = "basics"

                if (IsBasicSection -SectionName $section -BasicSectionName $BasicSectionName) {
                    $sectionToGet = "$BasicSectionName"
                }
                else {
                    $sectionToGet = "data"
                }
                if ((Get-Member -InputObject $sectionData.$section -Name $language -MemberType Properties) -and
                        (Get-Member -InputObject $sectionData.$section.$language -Name $sectionToGet -MemberType Properties)) {
                        
                    Write-Log "Filtering section '$section' for language: $language" "INFO"

                    if (IsBasicSection -SectionName $section -BasicSectionName $BasicSectionName) {
                        #if ($section -eq "$BasicSectionName") {
                        $basicsObj = $sectionData.$section.$language.basics
                    }
                    else {
                        $sectionItems = $sectionData.$section.$language.data
                    }
                    
                    #todo
                    if ($section -ne "$BasicSectionName") {
                        # Ensure we're treating data as an array
                        if ($sectionItems -isnot [array]) {
                            $sectionItems = @($sectionItems)
                        }
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
                        
                    if (IsBasicSection -SectionName $section -BasicSectionName $BasicSectionName) {
                        $resumeJson[$section] = $basicsObj
                    }
                    else {
                        $resumeJson[$section] = @($filteredData)
                    }
                            
                    Write-Log "Filtered items count in '$section': $($filteredData.Count)" "INFO"
                        
                    if ($filteredData.Count -eq 0) {
                        Write-Log "Warning: No matching items in '$section' based on resume type '$resumeType' and language '$language'." "WARN"
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
        $finalJson | Out-File -FilePath $outputFile -Encoding utf8 -NoNewline -NoClobber:$false -ErrorAction Stop
        Write-Log "Resume JSON created successfully at '$outputFile'!" "SUCCESS"
    }
    catch {
        Write-Log "Error: Failed to write '$outputFile' - $($_.Exception.Message)" "ERROR"
        exit 10
    }

    Write-Log "Resume generation complete." "SUCCESS"
    exit 0  # Successful completion
}
catch {
    # Catch any unexpected errors
    Write-Log "Critical Error: Unhandled exception - $($_.Exception.Message)" "ERROR"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    exit 11
}
finally {
    # Cleanup or final actions if needed
    Write-Log "Exiting script." "INFO"
}
# Exit Codes for `GenerateResume.ps1`

This document provides an explanation of the exit codes used in the `GenerateResume.ps1` script. Each exit code represents a specific condition or error encountered during the execution of the script.


## Table of Contents
- [Exit Codes for `GenerateResume.ps1`](#exit-codes-for-generateresumeps1)
  - [Exit Codes and Their Meanings](#exit-codes-and-their-meanings)
    - [Exit Code 0](#exit-code-0)
    - [Exit Code 1](#exit-code-1)
    - [Exit Code 2](#exit-code-2)
    - [Exit Code 3](#exit-code-3)
    - [Exit Code 4](#exit-code-4)
    - [Exit Code 5](#exit-code-5)
    - [Exit Code 6](#exit-code-6)
    - [Exit Code 7](#exit-code-7)
    - [Exit Code 8](#exit-code-8)
    - [Exit Code 9](#exit-code-9)
    - [Exit Code 10](#exit-code-10)
    - [Exit Code 11](#exit-code-11)
  - [Summary Table](#summary-table)

---

## **Exit Codes and Their Meanings**

### **Exit Code 0**
- **Meaning**: Successful completion.
- **Description**: Indicates that the script executed successfully without any errors.
- **Location**: At the end of the script.

---

### **Exit Code 1**
- **Meaning**: Failed to create or reset the log file.
- **Description**: Occurs when the script is unable to create or reset the log file specified by `$logFile`.
- **Location**: In the `try` block where the log file is initialized.
 
---

### **Exit Code 2**
- **Meaning**: Input folder does not exist or is not accessible.
- **Description**: Occurs when the specified input folder cannot be resolved or accessed.
- **Location**: During validation of the `$inputFolder` parameter.
  
---

### **Exit Code 3**
- **Meaning**: Configuration file does not exist or is not accessible.
- **Description**: Occurs when the specified configuration file cannot be resolved or accessed.
- **Location**: During validation of the `$configFile` parameter.
  
---

### **Exit Code 4**
- **Meaning**: Failed to create the output directory.
- **Description**: Occurs when the script is unable to create the directory for the output file specified by `$outputFile`.
- **Location**: When ensuring the output directory exists.
  
---

### **Exit Code 5**
- **Meaning**: Configuration file contains invalid JSON.
- **Description**: Occurs when the configuration file cannot be parsed as valid JSON.
- **Location**: During validation of the JSON format of the configuration file.
  
---

### **Exit Code 6**
- **Meaning**: Invalid configuration structure.
- **Description**: Occurs when required fields (e.g., `language`, `resumetype`, `gist_id`) are missing in the configuration file.
- **Location**: In the `ValidateConfigurationStructure` function.
  
---

### **Exit Code 7**
- **Meaning**: Failed to load or parse the configuration file.
- **Description**: Occurs when the script encounters an error while loading or parsing the configuration file.
- **Location**: In the `try` block where the configuration file is loaded.
  
---

### **Exit Code 8**
- **Meaning**: No sections to process (empty or null `sections` property).
- **Description**: Occurs when the `sections` property in the configuration file is empty or null, and no sections can be processed.
- **Location**: In the `GetSectionsToProcess` function.
  
---

### **Exit Code 9**
- **Meaning**: No sections to process (duplicate check for empty or null `sections` property).
- **Description**: A duplicate check for the same condition as Exit Code 8. This ensures no sections are processed if the `sections` property is empty or null.
- **Location**: In the `GetSectionsToProcess` function.
  
---

### **Exit Code 10**
- **Meaning**: Failed to write the output JSON file.
- **Description**: Occurs when the script encounters an error while writing the `resume.json` file.
- **Location**: When saving the final JSON structure to the output file.
  
---

### **Exit Code 11**
- **Meaning**: Unhandled exception.
- **Description**: Catches any unexpected errors that occur during script execution.
- **Location**: In the global `catch` block.
  
---

## **Summary Table**

| Exit Code | Meaning                                      | Description                                                                 |
|-----------|----------------------------------------------|-----------------------------------------------------------------------------|
| 0         | Successful completion                        | Script executed successfully without errors. Congratulations! :-)           |
| 1         | Failed to create or reset the log file       | Unable to initialize the log file.                                         |
| 2         | Input folder does not exist                  | Specified input folder is inaccessible.                                    |
| 3         | Configuration file does not exist            | Specified configuration file is inaccessible.                              |
| 4         | Failed to create the output directory        | Unable to create the directory for the output file.                        |
| 5         | Configuration file contains invalid JSON     | Configuration file cannot be parsed as valid JSON.                         |
| 6         | Invalid configuration structure              | Required fields are missing in the configuration file.                     |
| 7         | Failed to load or parse the configuration    | Error encountered while loading or parsing the configuration file.         |
| 8         | No sections to process (empty `sections`)    | `sections` property in the configuration file is empty or null.            |
| 9         | No sections to process (duplicate check)     | Duplicate check for empty or null `sections` property.                     |
| 10        | Failed to write the output JSON file         | Error encountered while saving the `resume.json` file.                     |
| 11        | Unhandled exception                          | Catches any unexpected errors during script execution.                     |

---
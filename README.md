# Generate Resume JSON

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
  - [Example `config.json`](#example-configjson)
  - [Key Configuration Fields](#key-configuration-fields)
- [Usage](#usage)
  - [Running the Script Locally](#running-the-script-locally)
- [Troubleshooting](#troubleshooting)
- [Tagging Elements in the JSON Files in the data folder](#tagging-elements-in-the-json-files-in-the-data-folder)
  - [How Tagging Works](#how-tagging-works)
  - [Example JSON Files](#example-json-files)
    - [work.json](#workjson)
    - [education.json](#educationjson)
  - [Default Behavior Without Tags](#default-behavior-without-tags)
  - [Best Practices for Tagging](#best-practices-for-tagging)
- [GitHub Actions Workflow](#github-actions-workflow)
  - [Workflow Triggers](#workflow-triggers)
  - [Workflow Steps](#workflow-steps)
  - [Workflow Permissions](#workflow-permissions)
- [Contributing](#contributing)
- [Future Enhancements](#future-enhancements)
- [License](#license)



## Overview
`GenerateResume.ps1` is a PowerShell script designed to automate the generation of resume data in [JsonResume](https://jsonresume.org/) format. The script processes input data, validates configurations, and outputs a structured JSON file. Additionally, the project includes a GitHub Actions workflow to publish the generated JSON to a GitHub Gist.


## Features
- **Dynamic Resume Generation**: Processes input data and generates a JSON file (`resume.json`).
- **Configuration-Driven**: Reads settings from a `config.json` file to customize behavior.
- **Logging**: Logs all operations to a specified log file for debugging and traceability.
- **GitHub Actions Integration**: Automates the process of generating and publishing the resume JSON to a Gist.

## Prerequisites
- **PowerShell**: Requires PowerShell 7 or later. You can download it from [PowerShell GitHub Releases](https://github.com/PowerShell/PowerShell/releases).
- **GitHub Actions**: Ensure your repository is set up with GitHub Actions for automated workflows.
- **JSON Resume Data**: Place JSON files for each resume section in the `data` folder.


## Configuration
The script uses a `config.json` file to control its behavior. Below is an example configuration:
### Example `config.json`
```json
{
  "deployment": {
	"resumetype": "projectmanagement",
	"language": "en",
	"gist_id": "your-gist-id",
	"sections": [
	  "basics",
	  "work",
	  "education",
	  "skills",
	  "projects"
	]
  },
  "environment": {
	"debug": "1",
	"dryrun": "0",
	"tagsmaintenance": "0"
  }
}
```


### Key Configuration Fields
- **`deployment.resumetype`**: Specifies the type of resume to generate.
- **`deployment.language`**: Language for the resume content.
- **`deployment.gist_id`**: ID of the GitHub Gist where the JSON will be published.
- **`environment.debug`**: Enables debug mode (`1` for enabled, `0` for disabled).
- **`environment.dryrun`**: If set to `1`, skips publishing to the Gist.
- **`environment.tagsmaintenance`**: If set to `1`, includes all data without filtering.


## Usage

### Running the Script Locally
1. Clone the repository:
   git clone https://github.com/HarrySolsem/JsonResume.git 

1. cd your-repo-name

1. Run the script:

```
pwsh ./GenerateResume.ps1 -inputFolder "./data" -outputFile "./resume.json" -configFile "./config.json" -Verbose -Debug
```
   
1. Check the output:
   - Generated JSON: `resume.json`
   - Logs: `dynamic_creation.log`



### Troubleshooting
- **GitHub Actions Workflow Fails**:
  - Verify that `config.json` exists in the repository.
  - Ensure the `TOKEN` secret is configured in your repository settings.
- **Generated JSON is Empty**:
  - Check the `data` folder to ensure it contains valid JSON files for each section.
  - Verify that the `sections` field in `config.json` matches the available files.
  - Verify that you have tagged your data accordingly and that you are deploying the correct resume



## Tagging Elements in the JSON Files in the data folder

### How Tagging Works
1. Each JSON file in the `data` folder corresponds to a specific section of the resume (e.g., `basics.json`, `work.json`, `education.json`).
2. Each element in these files can include a `tags` property, which is an array of strings.
3. The `tags` array should include the `resumetype` value from `config.json` for the element to be included in the generated resume.

### Example JSON Files

#### work.json
```json
{
  "company": "TechCorp",
  "position": "Project Manager",
  "startDate": "2020-01-01",
  "endDate": "2022-12-31",
  "summary": "Managed multiple projects across various teams.",
  "tags": [
    "projectmanagement",
    "general"
  ]
}
```


#### education.json
```json
{
  "institution": "University of Tech",
  "area": "Project Management",
  "studyType": "Master's",
  "startDate": "2016-09-01",
  "endDate": "2018-06-30",
  "tags": [
    "projectmanagement"
  ]
}
```


### Default Behavior Without Tags
If an element does not include a `tags` property:
- It will be excluded from the generated resume unless the `tagsmaintenance` setting in `config.json` is set to `1`.
- When `tagsmaintenance` is enabled, all elements will be included regardless of their tags.

### Best Practices for Tagging
1. **Use Consistent Tags**:
   - Ensure that the tags in your JSON files match the `resumetype` values in `config.json`.
   - For example, if your `resumetype` is `"projectmanagement"`, use `"projectmanagement"` as a tag in your JSON files.

2. **Tag Multiple Resumetypes**:
   - If an element is relevant to multiple resume types, include all applicable tags in the `tags` array.
   - Example:
    ```json "tags": ["projectmanagement", "softwaredevelopment"]```


### GitHub Actions Workflow
The project includes a GitHub Actions workflow (`.github/workflows/GenerateResumeJsonAndPublishToGist.yml`) to automate the process.

#### Workflow Triggers
- Runs on a push to the `main` or `test` branch.

#### Workflow Steps
1. **Checkout Repository**: Clones the repository.
2. **Read Configuration**: Extracts `gist_id`, `dryrun`, and `tagsmaintenance` from `config.json`.
3. **Run PowerShell Script**: Executes `GenerateResume.ps1` to generate the JSON.
4. **Publish to Gist**: Updates the specified Gist with the generated JSON (if `dryrun` is `0` and 'tagsmaintenance' is '0').

### Workflow Permissions
The GitHub Actions workflow requires the following permissions:
- **`contents: read`**: To read the repository contents.
- **`secrets.TOKEN`**: A GitHub personal access token with `gist` scope to update the Gist.

Ensure you add the `TOKEN` secret in your repository settings under **Settings > Secrets and variables > Actions**.


## Contributing
We welcome contributions to this project! To contribute:
1. Fork the repository.
1. Create a new branch for your feature or bug fix.
1. Submit a pull request with a detailed description of your changes.

For issues or feature requests, please open an issue in the repository.

## Future Enhancements
- time will show


## License
This project is licensed under the MIT License. See the `LICENSE` file for details.



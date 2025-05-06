#!/bin/bash
set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel || { echo "Error: Not inside a Git repository." >&2; exit 1; })
LOG_FILE="$REPO_ROOT/.dynamic_creation.log"

# Default language (if none provided)
LANGUAGE="${1:-no}"

# Optional tag filter - if provided, only JSON objects with this tag in "tags" will be selected.
TAG_FILTER="${2:-}"

# Validate the language selection
if [[ "$LANGUAGE" != "no" && "$LANGUAGE" != "en" ]]; then
    echo "Error: Invalid language '$LANGUAGE'. Please use 'no' for Norwegian or 'en' for English."
    exit 1
fi

# Define file paths
declare -A JSON_FILES=(
    ["BASICS_JSON"]="$REPO_ROOT/data/basics.json"
    ["VOLUNTEER_JSON"]="$REPO_ROOT/data/volunteer.json"
    ["WORK_JSON"]="$REPO_ROOT/data/work.json"
    ["EDUCATION_JSON"]="$REPO_ROOT/data/education.json"
    ["AWARDS_JSON"]="$REPO_ROOT/data/awards.json"
    ["CERTIFICATES_JSON"]="$REPO_ROOT/data/certificates.json"
    ["PUBLICATIONS_JSON"]="$REPO_ROOT/data/publications.json"
    ["SKILLS_JSON"]="$REPO_ROOT/data/skills.json"
    ["LANGUAGES_JSON"]="$REPO_ROOT/data/languages.json"
    ["INTERESTS_JSON"]="$REPO_ROOT/data/interests.json"
    ["REFERENCES_JSON"]="$REPO_ROOT/data/references.json"
    ["PROJECTS_JSON"]="$REPO_ROOT/data/projects.json"
    ["RESUME_JSON"]="$REPO_ROOT/resume.json"
)

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local output="[$timestamp] $level $message"
    echo "$output" | tee -a "$LOG_FILE"
}

validate_json_files() {
    log "[INFO]" "Validating required JSON files..."
    local missing=0
    
    for file_key in "${!JSON_FILES[@]}"; do
        local file_path="${JSON_FILES[$file_key]}"
        if [[ ! -f "$file_path" ]]; then
            log "[ERROR]" "Missing JSON file: $file_path"
            missing=$((missing + 1))
        fi
    done

    if [[ $missing -gt 0 ]]; then
        log "[ERROR]" "$missing required JSON files are missing. Execution aborted."
        exit 1
    fi
}

fetch_certificates() {
    local json_file="${JSON_FILES["CERTIFICATES_JSON"]}"
    if [[ -n "$TAG_FILTER" ]]; then
        jq --arg lang "$LANGUAGE" --arg tag "$TAG_FILTER" '.certificates[$lang].data // [] | map(select(.tags | index($tag)))' "$json_file"
    else
        jq --arg lang "$LANGUAGE" '.certificates[$lang].data // []' "$json_file"
    fi
}

check_prerequisites() {
    log "[INFO]" "Checking prerequisites..."
    if ! command -v jq &> /dev/null; then
        log "[ERROR]" "jq is not installed. Install it with: sudo apt install jq (Linux) or brew install jq (Mac)."
        exit 1
    fi
}

# Step 1: Validate files and prerequisites
validate_json_files
check_prerequisites

# Optionally, report the tag filter
if [[ -n "$TAG_FILTER" ]]; then
    log "[INFO]" "Applying tag filter: $TAG_FILTER"
fi

log "[INFO]" "Resetting resume.json..."
echo '{
    "basics": [],
    "volunteer": [],
    "work": [],
    "education": [],
    "awards": [],
    "certificates": [],
    "publications": [],
    "skills": [],
    "languages": [],
    "interests": [],
    "references": [],
    "projects": []
}' > "${JSON_FILES["RESUME_JSON"]}"

fetch_resume_data() {
    local json_file="${JSON_FILES[$1]}"
    log "[DEBUG]" "Fetching data for section: $1, language: $LANGUAGE${TAG_FILTER:+, tag filter: $TAG_FILTER}"
    if [[ -n "$TAG_FILTER" ]]; then
        jq --arg lang "$LANGUAGE" --arg tag "$TAG_FILTER" '.[$lang].data // [] | map(select(.tags | index($tag)))' "$json_file"
    else
        jq --arg lang "$LANGUAGE" '.[$lang].data // []' "$json_file"
    fi
}

# Step 3: Load multiple resume sections dynamically
declare -A SECTIONS=( 
    ["basics"]="BASICS_JSON" 
    ["volunteer"]="VOLUNTEER_JSON" 
    ["work"]="WORK_JSON" 
    ["education"]="EDUCATION_JSON" 
    ["awards"]="AWARDS_JSON" 
    ["certificates"]="CERTIFICATES_JSON" 
    ["publications"]="PUBLICATIONS_JSON" 
    ["skills"]="SKILLS_JSON" 
    ["languages"]="LANGUAGES_JSON" 
    ["interests"]="INTERESTS_JSON" 
    ["references"]="REFERENCES_JSON" 
    ["projects"]="PROJECTS_JSON"
)

log "[INFO]" "Loading resume sections for language: $LANGUAGE with tag filter: $TAG_FILTER"

updated_resume='{ }'
for section in "${!SECTIONS[@]}"; do
    data=$(fetch_resume_data "${SECTIONS[$section]}")
    updated_resume=$(jq --argjson new_data "$data" --arg section "$section" '.[$section] = $new_data' <<< "$updated_resume")
done

log "[INFO]" "Resume successfully updated for language: $LANGUAGE with tag filter: $TAG_FILTER"


#How to use
# ./script.sh <language> [tag]
# i.e ./script.sh en projectmanagement
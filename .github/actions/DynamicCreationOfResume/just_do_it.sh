#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel || { echo "Error: Not inside a Git repository." >&2; exit 1; })
LOG_FILE="$REPO_ROOT/.dynamic_creation.log"

export DEBUG_MODE=$(jq -r '.environment.debug // "0"' "$CONFIG_FILE")


# Define file paths
VOLUNTEER_JSON="$REPO_ROOT/data/no/volunteer.json"
WORK_JSON="$REPO_ROOT/data/no/work.json"
EDUCATION_JSON="$REPO_ROOT/data/no/education.json"
AWARDS_JSON="$REPO_ROOT/data/no/awards.json"
CERTIFICATES_JSON="$REPO_ROOT/data/no/certificates.json"
PUBLICATIONS_JSON="publications.json"
SKILLS_JSON="skills.json"
LANGUAGES_JSON="languages.json"
INTERESTS_JSON="interests.json"
REFERENCES_JSON="references.json"
PROJECTS_JSON="projects.json"
RESUME_JSON="resume.json"



log() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local output="[$timestamp] $level $message"
  echo "$output" | tee -a "$LOG_FILE"
}

# Debug log that only outputs when DEBUG_MODE is true.
debug_log() {
  # Handle DEBUG_MODE safely with a fallback default
  if [ "${DEBUG_MODE:-0}" = "1" ]; then
    log "[DEBUG]" "$1"
  fi
}

# Define relevant tags for filtering
declare -a TAGS=("projectmanagement" "management")

# Function to filter experiences based on tags
filter_experience() {
    local json_file="$1"
    local result="[]"

    for tag in "${TAGS[@]}"; do
        filtered=$(jq --arg tag "$tag" '[.items[] | select(.tags[] == $tag)]' "$json_file")
        result=$(jq --argjson new "$filtered" '. + $new' <<< "$result")
    done

    echo "$result"
}

# Step 1: Reset resume.json with predefined sections
echo '{
    "work": [],
    "volunteer": [],
    "education": [],
    "awards": [],
    "certificates": [],
    "publications": [],
    "skills": [],
    "languages": [],
    "interests": [],
    "references": [],
    "projects": []
}' > "$RESUME_JSON"

# Step 2: Load filtered experience from multiple sources
work=$(filter_experience "$WORK_JSON")
volunteer=$(filter_experience "$VOLUNTEER_JSON")
education=$(filter_experience "$EDUCATION_JSON")
awards=$(filter_experience "$AWARDS_JSON")
certificates=$(filter_experience "$CERTIFICATES_JSON")
publications=$(filter_experience "$PUBLICATIONS_JSON")
skills=$(filter_experience "$SKILLS_JSON")
languages=$(filter_experience "$LANGUAGES_JSON")
interests=$(filter_experience "$INTERESTS_JSON")
references=$(filter_experience "$REFERENCES_JSON")
projects=$(filter_experience "$PROJECTS_JSON")

# Step 3: Merge filtered data into respective resume sections
updated_resume=$(jq \
    --argjson work "$work" \
    --argjson volunteer "$volunteer" \
    --argjson edu "$education" \
    --argjson award "$awards" \
    --argjson cert "$certificates" \
    --argjson pub "$publications" \
    --argjson skill "$skills" \
    --argjson lang "$languages" \
    --argjson interest "$interests" \
    --argjson ref "$references" \
    --argjson proj "$projects" \
    '.workerience += $work |
    .volunteererience += $volunteer |
    .education += $edu |
    .awards += $award |
    .certificates += $cert |
    .publications += $pub |
    .skills += $skill |
    .languages += $lang |
    .interests += $interest |
    .references += $ref |
    .projects += $proj' "$RESUME_JSON")

# Step 4: Save the updated resume.json file
echo "$updated_resume" > "$RESUME_JSON"

echo "Resume successfully reset and populated with relevant experiences!"
#!/bin/bash

# Script that is creating the resume based on configs.

LOG_FILE="$REPO_ROOT/.generate-resume.log"

log() {
  #Do the actual logging to file and stdout
  local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1 $2"
  echo "$message" >> "$LOG_FILE"
  echo "$message"
}

log "INFO" "Starting resume generation"


# Sett filsti-variabler
CONFIG_FILE="FF44910D-7651-4051-A3A2-BF6E9FD3ADAD.json"
SOURCE_FILE="work.json"
OUTPUT_FILE="resume.json"

log "INFO" "Genererer CV basert på konfigurasjonen i $CONFIG_FILE og dataene i $SOURCE_FILE..."

# Sjekk at begge inndatafilene eksisterer
if [ ! -f "$CONFIG_FILE" ]; then
    log "ERROR" "Feil: Konfigurasjonsfilen $CONFIG_FILE finnes ikke."
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    log "ERROR" "Feil: Kildefilen $SOURCE_FILE finnes ikke."
    exit 1
fi

# Installer jq om den ikke finnes
if ! command -v jq &> /dev/null; then
    log "INFO" "jq er ikke installert. Forsøker å installere..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y jq
    elif command -v brew &> /dev/null; then
        brew install jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    else
        log "INFO" "Kan ikke installere jq automatisk. Vennligst installer jq manuelt og prøv igjen."
        exit 1
    fi
fi

# Hent konfigurasjonsdata
config_basics=$(jq -r '.configuration.basics' "$CONFIG_FILE")
config_work=$(jq -r '.configuration.work' "$CONFIG_FILE")
config_volunteer=$(jq -r '.configuration.volunteer' "$CONFIG_FILE")
config_education=$(jq -r '.configuration.education' "$CONFIG_FILE")
config_awards=$(jq -r '.configuration.awards' "$CONFIG_FILE")
config_certificates=$(jq -r '.configuration.certificates' "$CONFIG_FILE")
config_publications=$(jq -r '.configuration.publications' "$CONFIG_FILE")
config_skills=$(jq -r '.configuration.skills' "$CONFIG_FILE")
config_languages=$(jq -r '.configuration.languages' "$CONFIG_FILE")
config_interests=$(jq -r '.configuration.interests' "$CONFIG_FILE")
config_references=$(jq -r '.configuration.references' "$CONFIG_FILE")
config_projects=$(jq -r '.configuration.projects' "$CONFIG_FILE")

# Funksjon for å filtrere data basert på ID-er i konfigurasjonen
filter_data() {
    local data_type=$1
    local config_ids=$2
    
     # Filtrer basert på ID-er i konfigurasjonen
     jq --argjson ids "$config_ids" ".$data_type | map(select(.ID | tonumber | in(\$ids)))" "$SOURCE_FILE"
}

# Opprett resultat JSON-struktur
jq -n '{
    meta: input.meta,
    basics: input.basics,
    work: input.work,
    volunteer: input.volunteer,
    education: input.education,
    awards: input.awards,
    certificates: input.certificates,
    publications: input.publications,
    skills: input.skills,
    languages: input.languages,
    interests: input.interests,
    references: input.references,
    projects: input.projects
}' \
<(jq '.meta' "$SOURCE_FILE") \
<(if log "INFO" "$config_basics" | jq -e 'contains([0])' > /dev/null; then jq '.basics' "$SOURCE_FILE"; else echo "{}"; fi) \
<(filter_data "work" "$config_work") \
<(filter_data "volunteer" "$config_volunteer") \
<(filter_data "education" "$config_education") \
<(filter_data "awards" "$config_awards") \
<(filter_data "certificates" "$config_certificates") \
<(filter_data "publications" "$config_publications") \
<(filter_data "skills" "$config_skills") \
<(filter_data "languages" "$config_languages") \
<(filter_data "interests" "$config_interests") \
<(filter_data "references" "$config_references") \
<(filter_data "projects" "$config_projects") \
> "$OUTPUT_FILE"

# Oppdater meta-beskrivelsen fra konfigurasjonsfilen
jq --arg desc "$(jq -r '.meta.description' "$CONFIG_FILE")" '.meta.description = $desc' "$OUTPUT_FILE" > temp.json && mv temp.json "$OUTPUT_FILE"

# Oppdater språk fra konfigurasjonsfilen
jq --arg lang "$(jq -r '.meta.language' "$CONFIG_FILE")" '.meta.language = $lang' "$OUTPUT_FILE" > temp.json && mv temp.json "$OUTPUT_FILE"

log "INFO" "CV generert og lagret i $OUTPUT_FILE"
log "INFO" "Konfigurasjon brukt:"
log "INFO" "  - basics: $(echo   $config_basics | jq -c .)"
log "INFO" "  - work: $(echo  $config_work | jq -c .)"
log "INFO" "  - volunteer: $(echo  $config_volunteer | jq -c .)"
log "INFO" "  - education: $(echo  $config_education | jq -c .)"
log "INFO" "  - certificates: $(echo  $config_certificates | jq -c .)"
log "INFO" "  - skills: $(echo  $config_skills | jq -c .)"
log "INFO" "  - languages: $(echo  $config_languages | jq -c .)"
log "INFO" "  - interests: $(echo  $config_interests | jq -c .)"
log "INFO" "  - projects: $(echo  $config_projects | jq -c .)"

exit 0


log "INFO" "Completed resume generation"
exit 0
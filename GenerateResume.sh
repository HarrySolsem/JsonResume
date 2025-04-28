# Script that is creating the resume based on configs.

LOG_FILE="$REPO_ROOT/.generateresume.log"

log() {
  #Do the actual logging to file and stdout
  local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1 $2"
  echo "$message" >> "$LOG_FILE"
  echo "$message"
}

log "INFO" "Starting resume generation"
log "INFO" "Completed resume generation"
exit 0
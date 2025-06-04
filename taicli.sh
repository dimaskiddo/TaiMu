#!/bin/bash
#
# Create By: Donni Triosa (donni.triosa94@gmail.com)
# Creates subtasks in Taiga from a formatted input file with the format:
# First line: Story ID
# Subsequent lines: Summary|Date|Time|TimeSpent
#
# Usage: ./taicli.sh <input_file>
# Load auth credentials from .env file


# Function to log errors
log_error() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  local error_log="logs/error.log"
  echo "[${timestamp}] $1" | tee -a "$error_log"
}

# Check if file is provided as argument
if [ "$#" -ne 1 ]; then
    log_error "Error: No input file provided"
    echo "Usage: $0 <input_file>"
    exit 1
fi

INPUT_FILE="$1"

# Load environment variables from .env file
if [ -f .env ]; then
  echo "Loading configuration from .env file"
  source .env
  # check if the input file exists
  if [ ! -f "$INPUT_FILE" ]; then
    log_error "Error: Input file '$INPUT_FILE' not found!"
    exit 1
  fi
else
  log_error "Error: .env file not found!"
  exit 1
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Login to Taiga and get authentication token
AUTH_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"normal\",\"username\":\"$TAIGA_USER\",\"password\":\"$TAIGA_PASSWORD\"}" \
  "$TAIGA_URL/api/v1/auth")

AUTH_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.auth_token')

if [ "$AUTH_TOKEN" == "null" ] || [ -z "$AUTH_TOKEN" ]; then
  log_error "Authentication failed. Please check your credentials in .env file."
  exit 1
fi
echo "Authentication successful"

# Read the story ID from first line
read -r STORY_ID < "$INPUT_FILE"

# Process each line after the first one until blank line
tail -n +2 "$INPUT_FILE" | while IFS='|' read -r TASK_SUBJECT ACTIVITY_DATE START_TIME TIME_SPENT; do
  # Trim whitespace
  TASK_SUBJECT=$(echo "$TASK_SUBJECT" | xargs)
  ACTIVITY_DATE=$(echo "$ACTIVITY_DATE" | xargs)
  START_TIME=$(echo "$START_TIME" | xargs)
  TIME_SPENT=$(echo "$TIME_SPENT" | xargs)

  #skip empty lines
  if [[ -z "$TASK_SUBJECT" ]]; then
    continue
  fi
  
  # Validate date format
  if ! [[ $ACTIVITY_DATE =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    log_error "Invalid date format for task '$TASK_SUBJECT': $ACTIVITY_DATE (expected YYYY-MM-DD)"
    continue
  fi

  # Extract the month and year from the DATE field
  TASK_YEAR=$(echo "$ACTIVITY_DATE" | cut -d '-' -f 1)
  TASK_MONTH=$(echo "$ACTIVITY_DATE" | cut -d '-' -f 2)

  # Create the log file name based on the task month
  CREATED_TASKS_FILE="logs/created_tasks_$TASK_YEAR-$TASK_MONTH.log"

  # Check if the subtask has already been created
  if grep -q "$TASK_SUBJECT | $ACTIVITY_DATE | $START_TIME | $TIME_SPENT" "$CREATED_TASKS_FILE"; then
    echo "Task '$TASK_SUBJECT' already created, skipping."
    continue
  fi
    
  # Create the task
  TASK_RESPONSE=$(curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -d "{
      \"subject\": \"${TASK_SUBJECT}\",
      \"assigned_to\": ${TAIGA_USER_ID},
      \"status\": ${STATUS_DONE_ID},
      \"project\": ${PROJECT_ID},
      \"user_story\": ${STORY_ID},
      \"is_blocked\": false,
      \"is_closed\": true
    }" \
    -s "${TAIGA_URL}/api/v1/tasks")
     
  # Extract the task ID
  TASK_ID=$(echo $TASK_RESPONSE | jq -r '.id')
    
  if [ "$TASK_ID" == "null" ] || [ -z "$TASK_ID" ]; then
    log_error "Failed to create task: $TASK_SUBJECT"
    log_error "Error response: $TASK_RESPONSE"
    continue
  fi
    
  # Update the custom fields
  CUSTOM_FIELDS_RESPONSE=$(curl -X PATCH \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -d "{
      \"attributes_values\": {
        \"5504\": \"${ACTIVITY_DATE}\",
        \"5505\": \"${START_TIME}\",
        \"5506\": \"${TIME_SPENT}\"
      },
      \"version\": 1
    }" \
    -s "${TAIGA_URL}/api/v1/tasks/custom-attributes-values/${TASK_ID}")

  if echo "$CUSTOM_FIELDS_RESPONSE" | grep -q "error"; then
    log_error "Failed to update custom fields for task: $TASK_ID"
    log_error "Error response: $CUSTOM_FIELDS_RESPONSE"
    continue
  fi
    
  echo "$TASK_SUBJECT | $ACTIVITY_DATE | $START_TIME | $TIME_SPENT" >> "$CREATED_TASKS_FILE"
  echo "Subtask '$TASK_SUBJECT' created and the custom fields updated."

done

echo "All tasks done. Check logs for details."
exit 0

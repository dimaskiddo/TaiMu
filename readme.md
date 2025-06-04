# TaiCLI (Taiga Automation Scripts)
A  scripts to automate task creation in Taiga project management tool.

## Overview
These scripts help you create tasks in Taiga from the command line or from a bulk input file, with support for custom fields like Activity Date, Start Time, and Total Time Spent.

## Prerequisites
-   bash shell
-   curl
-   jq (for JSON parsing)
-   Taiga account with API access

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/taicli.git
   cd taicli
   ```
2. Make the scripts executable:
   ```bash
   chmod +x *.sh
   ```
   This grants execute permissions to all shell scripts in the directory.

3. Create directories for logs and tasks:
   ```bash
   mkdir -p logs tasks
   ```

## Setup
1.  Create a  .env  file in the script directory with the following variables:
```
TAIGA_URL=https://your-taiga-instance.com
TAIGA_USER=your_username
TAIGA_PASSWORD=your_password
PROJECT_ID=123
TAIGA_USER_ID=456
STATUS_DONE_ID=789
```
Replace the values with your actual Taiga credentials and IDs.

## Scripts
#### taicli.sh
Create multiple tasks from a structured input file.
`./taicli.sh  tasks/task.txt`

#### Input File Format
```
STORY_ID
Task Subject | YYYY-MM-DD | HH:MM | Minutes
Another Task | YYYY-MM-DD | HH:MM | Minutes
```
-   First line: The ID of the user story where tasks will be created
-   Following lines: Task data with fields separated by  `|`  character:
    -   Task subject
    -   Activity date (YYYY-MM-DD format)
    -   Start time (HH:MM format)
    -   Time spent (in minutes)

## Logs
All operations are logged in the  logs  directory:
-   `error.log`: Contains error messages
-   `created_tasks_YYYY-MM.log`: Lists tasks created in a specific year and month

## Example   
#### example task file
```
597462
Daily Standup Meeting | 2025-06-02 | 09:30 | 30
Code Review Session | 2025-06-02 | 14:00 | 120
```
run with:
`./taicli.sh  tasks/task.txt`
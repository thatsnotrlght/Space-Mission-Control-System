/* 
   ####################################################
   IMPLEMENT FUNCTIONS 4 & 5:
    - load_missions_from_file() (15 points)
    - save_mission_report() (10 points)
   ################################################### 
*/


#include "space_mission.h"

/**
 * FUNCTION 4: load_missions_from_file()
 * 
 * PURPOSE: Load mission data from a text file using fscanf()
 * 
 * File format:
 * Line 1: number_of_missions
 * Following lines: mission_id mission_name launch_date
 * 
 * PARAMETERS:
 *   system - Pointer to mission control system
 *   filename - Path to input file
 * 
 * RETURNS:
 *   0 on success, -1 on failure
 * 
 * REQUIREMENTS:
 *  - Use fscanf() for file input parsing
 *  - Validate file operations and parsed data before creating missions
 *  - Create missions using existing create_mission_with_crew() function in mission_control.c
 *  - Handle file errors and invalid data gracefully
 *  - Support loading 0 missions (empty file case)
 */
int load_missions_from_file(MissionControl* system, const char* filename) {
    
    // TODO: Implement load_missions_from_file() with file I/O
    //
    // 1. INPUT VALIDATION:
    //    - Check system and filename for NULL
    //    - Return -1 if invalid
    //
    // 2. OPEN FILE:
    //    - Use fopen() to open file for reading ("r" mode)
    //    - Return -1 if file cannot be opened
    //
    // 3. READ MISSION COUNT:
    //    - Use fscanf() to read number of missions from first line
    //    - Validate mission count is non-negative
    //    - Handle case where mission count is 0 (empty file)
    //
    // 4. READ MISSION DATA:
    //    - Loop through each mission entry
    //    - Use fscanf() to read: mission_id, mission_name, launch_date
    //    - Validate each field (mission_id > 0, valid date format)
    //    - Call create_mission_with_crew() function in mission_control.cfor each valid mission
    //    - Return -1 if any mission creation fails
    //
    // 5. CLEANUP:
    //    - Close file using fclose()
    //    - Return 0 for success
    
    // Your implementation here:
    if (system == NULL || filename == NULL || filename[0] == '\0') {
        return -1;
    }

    FILE *fp = fopen(filename, "r");

    if (fp == NULL) {
        return -1;
    }

    int num_missions = 0;
    int scanned_items = fscanf(fp, "%d", &num_missions);

    if (scanned_items != 1) {
        fclose(fp);
        return -1;
    }

    if (num_missions < 0) {
        fclose(fp);
        return -1;
    }

    if (num_missions == 0) {
        fclose(fp);
        return 0;
    }

    
    int temp_id;
    char temp_name[MAX_NAME_LENGTH];
    char temp_date[MAX_DATE_LENGTH];

    for (int i = 0; i < num_missions; i++) {
        int scanned_items = fscanf(fp, "%d %s %s", &temp_id, temp_name, temp_date);
    
        if (scanned_items != 3) {
        fclose(fp);
        return -1;
        }

        if (temp_id <= 0 || !is_valid_date_format(temp_date)) {
            fclose(fp);
            return -1;
        }

        int result = create_mission_with_crew(system, temp_id, temp_name, temp_date);
    
        if (result == -1) {
            fclose(fp);
            return -1;
        }
    }

    fclose(fp);
    return 0;
}

/*
 * FUNCTION 5: save_mission_report()
 * 
 * PURPOSE: Generate a comprehensive mission status report using fprintf()
 * 
 * PARAMETERS:
 *   system - Pointer to mission control system
 *   filename - Path to output file
 * 
 * RETURNS:
 *   0 on success, -1 on failure
 * 
 * REQUIREMENTS:
 *  - Use fprintf() for formatted output
 *  - Write professional report header with system statistics - refer to the 'SAMPLE_report.txt' file provided
 *  - For each mission: display mission details, communication counts by priority
 *  - Calculate and display system totals (total missions, total communications)
 *  - Handle file operations with proper error checking
 */
int save_mission_report(const MissionControl* system, const char* filename) {
    
    // TODO: Implement save_mission_report with formatted output
    //
    // 1. INPUT VALIDATION:
    //    - Check system and filename for NULL
    //    - Return -1 if invalid
    //
    // 2. OPEN FILE:
    //    - Use fopen() to open file for writing ("w" mode)
    //    - Return -1 if file cannot be opened
    //
    // 3. WRITE REPORT HEADER: - refer to the 'SAMPLE_report.txt' file provided:
    //    - Use fprintf() to write professional header
    //    - Include total missions count
    //    - Add appropriate formatting and separators
    //
    // 4. WRITE MISSION DETAILS:
    //    - Loop through all missions in system
    //    - For each mission, write:
    //      * Mission ID, name, launch date, status
    //      * Communication count
    //      * Communication summary by priority (routine/urgent/emergency counts)
    //
    // 5. WRITE SYSTEM TOTALS: - refer to the 'SAMPLE_report.txt' file provided:
    //    - Calculate and write total communications across all missions
    //    - Add footer formatting
    //
    // 6. CLEANUP:
    //    - Close file using fclose()
    //    - Return 0 for success
    
    // Your implementation here:
    int total_system_comms = 0;
    if (system == NULL || filename == NULL || filename[0] == '\0') {
        return -1;
    }

    FILE *fp = fopen(filename, "w");

    if (fp == NULL) {
        return -1;
    }

    fprintf(fp, "===============================================\n");
    fprintf(fp, "SPACE MISSION CONTROL REPORT\n");
    fprintf(fp, "===============================================\n");
    fprintf(fp, "Total Missions in System: %d\n", system->mission_count);

    for (int i = 0; i < system->mission_count; i++) {
        const Mission *m = &system->missions[i];

        total_system_comms += m->comm_count;

        int routine = 0;
        int urgent = 0;
        int emergency = 0;

        for (int j = 0; j < m->comm_count; j++) {
            MessagePriority priority = m->communications[j].priority;
            if (priority == ROUTINE) routine++;
            else if (priority == URGENT) urgent++;
            else if (priority == EMERGENCY) emergency++;
        }

        if (i > 0) fprintf(fp, "\n"); 

        fprintf(fp, "Mission ID: %d\n", m->mission_id);
        fprintf(fp, "Mission Name: %s\n", m->mission_name);
        fprintf(fp, "Launch Date: %s\n", m->launch_date);
        
        fprintf(fp, "Status: ");
        switch(m->status) {
            case PLANNED: 
                fprintf(fp, "Planned\n"); 
                break;
            case ACTIVE:  
                fprintf(fp, "Active\n"); 
                break;
            case COMPLETED: 
                fprintf(fp, "Completed\n"); 
                break;
            default:      
                fprintf(fp, "Unknown\n"); 
                break;
        }
        fprintf(fp, "Communications: %d\n", m->comm_count);
        fprintf(fp, "-------------------\n");
        fprintf(fp, "Communication Summary:\n");
        fprintf(fp, "  Routine: %d, Urgent: %d, Emergency: %d\n", routine, urgent, emergency);
    }

    fprintf(fp, "\n===============================================\n");
    fprintf(fp, "SYSTEM TOTALS:\n");
    fprintf(fp, "Total Communications: %d\n", total_system_comms);
    fprintf(fp, "===============================================\n");

    fclose(fp);
    return 0;
}
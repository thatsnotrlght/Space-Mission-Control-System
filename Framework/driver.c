/**
 * @file driver.c
 * @brief Space Mission Control System - Test Framework Driver
 * 
 * This driver processes test commands and executes student functions
 * with timeout protection and standardized output formatting.
 * 
 * 💀 Students: DO NOT modify this file!
 */

#include "space_mission.h"

/* ========================================
 * TIMEOUT AND SAFETY GLOBALS
 * ======================================== */
volatile int timeout_occurred = 0;

/* ========================================
 * GLOBAL TEST VARIABLES
 * ======================================== */
static MissionControl* g_system = NULL;
static int g_test_capacity;
static int g_test_mission_id;
static char g_test_name[MAX_NAME_LENGTH];
static char g_test_date[MAX_DATE_LENGTH];
static char g_test_timestamp[MAX_TIMESTAMP_LENGTH];
static int g_test_priority;
static char g_test_message[MAX_MESSAGE_LENGTH];
static char g_test_filename[256];
static char g_expected_result[20];

/* ========================================
 * DIRECTORY MANAGEMENT
 * ======================================== */
void ensure_mission_report_directory(void) {
    struct stat st = {0};
    
    if (stat("Mission_Report", &st) == -1) {
        mkdir("Mission_Report", 0755);
    }
}

/* ========================================
 * TIMEOUT HANDLING
 * ======================================== */
void setup_timeout_handler(void) {
    signal(SIGALRM, timeout_handler);
}

void timeout_handler(int sig) {
    timeout_occurred = 1;
    (void) sig;
}

/* ========================================
 * UTILITY FUNCTIONS
 * ======================================== */
void safe_strncpy(char* dest, const char* src, size_t size) {
    if (dest && src && size > 0) {
        strncpy(dest, src, size - 1);
        dest[size - 1] = '\0';
    }
}

/* ========================================
 * STRING CONVERSION UTILITIES (PROVIDED)
 * ======================================== */
const char* rank_to_string(AstronautRank rank) {
    switch (rank) {
        case COMMANDER: return "Commander";
        case PILOT: return "Pilot";
        case MISSION_SPECIALIST: return "Mission Specialist";
        case FLIGHT_ENGINEER: return "Flight Engineer";
        default: return "Unknown";
    }
}

const char* status_to_string(MissionStatus status) {
    switch (status) {
        case PLANNED: return "Planned";
        case ACTIVE: return "Active";
        case COMPLETED: return "Completed";
        case ABORTED: return "Aborted";
        default: return "Unknown";
    }
}

const char* priority_to_string(MessagePriority priority) {
    switch (priority) {
        case ROUTINE: return "Routine";
        case URGENT: return "Urgent";
        case EMERGENCY: return "Emergency";
        default: return "Unknown";
    }
}

/* ========================================
 * VALIDATION UTILITIES (PROVIDED)
 * ======================================== */
#include <string.h>
#include <stdlib.h>

int is_valid_date_format(const char* date_str) {
    if (date_str == NULL || strlen(date_str) != 10) {
        return 0;
    }
    
    // Check basic format: YYYY-MM-DD
    if (date_str[4] != '-' || date_str[7] != '-') {
        return 0;
    }
    
    // Check if year, month, day positions contain digits
    for (int i = 0; i < 10; i++) {
        if (i == 4 || i == 7) continue; // Skip dashes
        if (date_str[i] < '0' || date_str[i] > '9') {
            return 0;
        }
    }
    
    // Extract year, month, day
    char year_str[5], month_str[3], day_str[3];
    strncpy(year_str, date_str, 4);
    year_str[4] = '\0';
    strncpy(month_str, date_str + 5, 2);
    month_str[2] = '\0';
    strncpy(day_str, date_str + 8, 2);
    day_str[2] = '\0';
    
    int year = atoi(year_str);
    int month = atoi(month_str);
    int day = atoi(day_str);
    
    // Validate month (1-12)
    if (month < 1 || month > 12) {
        return 0;
    }
    
    // Days in each month
    int days_in_month[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    
    // Check for leap year
    if (month == 2 && ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))) {
        days_in_month[1] = 29;
    }
    
    // Validate day
    if (day < 1 || day > days_in_month[month - 1]) {
        return 0;
    }
    
    return 1;
}

int is_valid_timestamp_format(const char* timestamp_str) {
    if (timestamp_str == NULL || strlen(timestamp_str) != 16) {
        return 0;
    }
    
    // Check basic format: YYYY-MM-DD HH:MM
    if (timestamp_str[4] != '-' || timestamp_str[7] != '-' || 
        timestamp_str[10] != ' ' || timestamp_str[13] != ':') {
        return 0;
    }
    
    // Check if all other positions contain digits
    for (int i = 0; i < 16; i++) {
        if (i == 4 || i == 7 || i == 10 || i == 13) continue; // Skip separators
        if (timestamp_str[i] < '0' || timestamp_str[i] > '9') {
            return 0;
        }
    }
    
    return 1;
}

/* ========================================
 * ATOMIC TEST EXECUTION FUNCTIONS
 * ======================================== */

void execute_create_system_test(void) {
    // Always clean up previous system first
    if (g_system != NULL) {
        free_mission_control(g_system);
        g_system = NULL;
    }
    
    g_system = create_mission_control(g_test_capacity);
    
    if (strcmp(g_expected_result, "SUCCESS") == 0) {
        if (g_system != NULL) {
            printf("CREATE_SYSTEM: PASS SUCCESS\n");
        } else {
            printf("CREATE_SYSTEM: FAIL Expected=SUCCESS Got=NULL\n");
        }
    } else {
        if (g_system == NULL) {
            printf("CREATE_SYSTEM: PASS FAILURE\n");
            // For subsequent tests, create a valid system after failed test
            g_system = create_mission_control(5);  // Create valid system for next tests
        } else {
            printf("CREATE_SYSTEM: FAIL Expected=FAILURE Got=SUCCESS\n");
            free_mission_control(g_system);
            g_system = NULL;
            // Create valid system for subsequent tests
            g_system = create_mission_control(5);
        }
    }
}

void execute_create_mission_test(void) {
    if (g_system == NULL) {
        printf("CREATE_MISSION: FAIL System_not_initialized\n");
        return;
    }
    
    int result = create_mission_with_crew(g_system, g_test_mission_id, g_test_name, 
                                         g_test_date);
    
    if (strcmp(g_expected_result, "SUCCESS") == 0) {
        if (result == 0) {
            printf("CREATE_MISSION: PASS SUCCESS\n");
        } else {
            printf("CREATE_MISSION: FAIL Expected=SUCCESS Got=FAILURE\n");
        }
    } else {
        if (result != 0) {
            printf("CREATE_MISSION: PASS FAILURE\n");
        } else {
            printf("CREATE_MISSION: FAIL Expected=FAILURE Got=SUCCESS\n");
        }
    }
}

void execute_add_comm_test(void) {
    if (g_system == NULL) {
        printf("ADD_COMM: FAIL System_not_initialized\n");
        return;
    }
    
    int result = add_communication(g_system, g_test_mission_id, g_test_timestamp, 
                                  (MessagePriority)g_test_priority, g_test_message);
    
    if (strcmp(g_expected_result, "SUCCESS") == 0) {
        if (result == 0) {
            printf("ADD_COMM: PASS SUCCESS\n");
        } else {
            printf("ADD_COMM: FAIL Expected=SUCCESS Got=FAILURE\n");
        }
    } else {
        if (result != 0) {
            printf("ADD_COMM: PASS FAILURE\n");
        } else {
            printf("ADD_COMM: FAIL Expected=FAILURE Got=SUCCESS\n");
        }
    }
}

void execute_load_file_test(void) {
    if (g_system == NULL) {
        printf("LOAD_FILE: FAIL System_not_initialized\n");
        return;
    }
    
    int result = load_missions_from_file(g_system, g_test_filename);
    
    if (strcmp(g_expected_result, "SUCCESS") == 0) {
        if (result == 0) {
            printf("LOAD_FILE: PASS SUCCESS\n");
        } else {
            printf("LOAD_FILE: FAIL Expected=SUCCESS Got=FAILURE\n");
        }
    } else {
        if (result != 0) {
            printf("LOAD_FILE: PASS FAILURE\n");
        } else {
            printf("LOAD_FILE: FAIL Expected=FAILURE Got=SUCCESS\n");
        }
    }
}

void execute_save_report_test(void) {
    if (g_system == NULL) {
        printf("SAVE_REPORT: FAIL System_not_initialized\n");
        return;
    }
    
    // Ensure Mission_Report directory exists
    ensure_mission_report_directory();
    
    // Create full path with Mission_Report/ prefix
    char full_path[512];
    snprintf(full_path, sizeof(full_path), "Mission_Report/%s", g_test_filename);
    
    int result = save_mission_report(g_system, full_path);
    
    if (strcmp(g_expected_result, "SUCCESS") == 0) {
        if (result == 0) {
            printf("SAVE_REPORT: PASS SUCCESS\n");
        } else {
            printf("SAVE_REPORT: FAIL Expected=SUCCESS Got=FAILURE\n");
        }
    } else {
        if (result != 0) {
            printf("SAVE_REPORT: PASS FAILURE\n");
        } else {
            printf("SAVE_REPORT: FAIL Expected=FAILURE Got=SUCCESS\n");
        }
    }
}

void execute_free_system_test(void) {
    if (g_system != NULL) {
        free_mission_control(g_system);
        g_system = NULL;
        printf("FREE_SYSTEM: PASS SUCCESS\n");
    } else {
        printf("FREE_SYSTEM: PASS SUCCESS\n"); // NULL is OK for free
    }
}

/* ========================================
 * SAFE EXECUTION WRAPPER
 * ======================================== */
int execute_with_timeout(void (*test_func)(void), int timeout_seconds) {
    timeout_occurred = 0;
    
    alarm(timeout_seconds);
    test_func();
    alarm(0);
    
    return !timeout_occurred;
}

/* ========================================
 * PUBLIC TEST INTERFACE FUNCTIONS
 * ======================================== */

void test_create_system(int capacity, const char* expected_result) {
    g_test_capacity = capacity;
    safe_strncpy(g_expected_result, expected_result, sizeof(g_expected_result));
    
    if (!execute_with_timeout(execute_create_system_test, 3)) {
        printf("CREATE_SYSTEM: TIMEOUT\n");
    }
}

void test_create_mission(int mission_id, const char* name, const char* launch_date, 
                        const char* expected_result) {
    g_test_mission_id = mission_id;
    safe_strncpy(g_test_name, name, MAX_NAME_LENGTH);
    safe_strncpy(g_test_date, launch_date, MAX_DATE_LENGTH);
    safe_strncpy(g_expected_result, expected_result, sizeof(g_expected_result));
    
    if (!execute_with_timeout(execute_create_mission_test, 3)) {
        printf("CREATE_MISSION: TIMEOUT\n");
    }
}

void test_add_comm(int mission_id, const char* timestamp, int priority, 
                  const char* message, const char* expected_result) {
    g_test_mission_id = mission_id;
    
    // Convert timestamp format from "YYYY-MM-DD_HH:MM" to "YYYY-MM-DD HH:MM"
    char converted_timestamp[MAX_TIMESTAMP_LENGTH];
    safe_strncpy(converted_timestamp, timestamp, MAX_TIMESTAMP_LENGTH);
    
    // Replace underscore with space if present
    for (int i = 0; converted_timestamp[i] != '\0'; i++) {
        if (converted_timestamp[i] == '_') {
            converted_timestamp[i] = ' ';
            break;
        }
    }
    
    safe_strncpy(g_test_timestamp, converted_timestamp, MAX_TIMESTAMP_LENGTH);
    g_test_priority = priority;
    safe_strncpy(g_test_message, message, MAX_MESSAGE_LENGTH);
    safe_strncpy(g_expected_result, expected_result, sizeof(g_expected_result));
    
    if (!execute_with_timeout(execute_add_comm_test, 3)) {
        printf("ADD_COMM: TIMEOUT\n");
    }
}

void test_load_file(const char* filename, const char* expected_result) {
    safe_strncpy(g_test_filename, filename, sizeof(g_test_filename));
    safe_strncpy(g_expected_result, expected_result, sizeof(g_expected_result));
    
    if (!execute_with_timeout(execute_load_file_test, 3)) {
        printf("LOAD_FILE: TIMEOUT\n");
    }
}

void test_save_report(const char* filename, const char* expected_result) {
    safe_strncpy(g_test_filename, filename, sizeof(g_test_filename));
    safe_strncpy(g_expected_result, expected_result, sizeof(g_expected_result));
    
    if (!execute_with_timeout(execute_save_report_test, 3)) {
        printf("SAVE_REPORT: TIMEOUT\n");
    }
}

void test_free_system(const char* expected_result) {
    safe_strncpy(g_expected_result, expected_result, sizeof(g_expected_result));
    
    if (!execute_with_timeout(execute_free_system_test, 3)) {
        printf("FREE_SYSTEM: TIMEOUT\n");
    }
}

/* ========================================
 * MAIN TEST FILE PROCESSOR
 * ======================================== */
void process_test_file(const char* filename) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("ERROR: Cannot open test file %s\n", filename);
        return;
    }
    
    char line[512];
    while (fgets(line, sizeof(line), file)) {
        line[strcspn(line, "\n")] = 0; // Remove newline
        
        if (line[0] == '#' || line[0] == '\0') {
            continue; // Skip comments and empty lines
        }
        
        // Parse test commands
        if (strncmp(line, "TEST_CREATE_SYSTEM ", 19) == 0) {
            int capacity;
            char expected[20];
            if (sscanf(line + 19, "%d %19s", &capacity, expected) == 2) {
                test_create_system(capacity, expected);
            }
        } else if (strncmp(line, "TEST_CREATE_MISSION ", 20) == 0) {
            int mission_id;
            char name[MAX_NAME_LENGTH], date[MAX_DATE_LENGTH], expected[20];
            if (sscanf(line + 20, "%d %49s %11s %19s", 
                      &mission_id, name, date, expected) == 4) {
                test_create_mission(mission_id, name, date, expected);
            }
        } else if (strncmp(line, "TEST_ADD_COMM ", 14) == 0) {
            int mission_id, priority;
            char timestamp[MAX_TIMESTAMP_LENGTH], message[MAX_MESSAGE_LENGTH], expected[20];
            if (sscanf(line + 14, "%d %19s %d %199s %19s", 
                      &mission_id, timestamp, &priority, message, expected) == 5) {
                test_add_comm(mission_id, timestamp, priority, message, expected);
            }
        } else if (strncmp(line, "TEST_LOAD_FILE ", 15) == 0) {
            char filename[256], expected[20];
            if (sscanf(line + 15, "%255s %19s", filename, expected) == 2) {
                test_load_file(filename, expected);
            }
        } else if (strncmp(line, "TEST_SAVE_REPORT ", 17) == 0) {
            char filename[256], expected[20];
            if (sscanf(line + 17, "%255s %19s", filename, expected) == 2) {
                test_save_report(filename, expected);
            }
        } else if (strncmp(line, "TEST_FREE_SYSTEM ", 17) == 0) {
            char expected[20];
            if (sscanf(line + 17, "%19s", expected) == 1) {
                test_free_system(expected);
            }
        }
    }
    
    fclose(file);
    
    // Final cleanup
    if (g_system != NULL) {
        free_mission_control(g_system);
        g_system = NULL;
    }
}

/* ========================================
 * MAIN FUNCTION
 * ======================================== */
int main(int argc, char* argv[]) {
    setup_timeout_handler();
    
    const char* test_file = "TESTCASES.txt";
    if (argc > 1) {
        test_file = argv[1];
    }
    
    process_test_file(test_file);
    
    return 0;
}
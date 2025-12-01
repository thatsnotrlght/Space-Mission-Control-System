/**
 * @file space_mission.h
 * @brief Space Mission Control System - Header File
 * 
 * This header defines all structures, enumerations, and function prototypes
 * for the Space Mission Control System assignment.
 * 
 * 💀 Students: DO NOT modify this file!
 */

#ifndef SPACE_MISSION_H
#define SPACE_MISSION_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <sys/stat.h>

/* =============================================================================
 * CONSTANTS AND LIMITS
 * ============================================================================= */

#define MAX_NAME_LENGTH 50
#define MAX_DATE_LENGTH 12      // "YYYY-MM-DD\0"
#define MAX_TIMESTAMP_LENGTH 20 // "YYYY-MM-DD HH:MM\0"
#define MAX_MESSAGE_LENGTH 200
#define INITIAL_COMM_CAPACITY 5
#define INITIAL_MISSION_CAPACITY 3

/* =============================================================================
 * ENUMERATIONS
 * ============================================================================= */

/**
 * @brief Astronaut rank/specialization enumeration
 */
typedef enum {
    COMMANDER = 1,        // Mission commander
    PILOT = 2,           // Pilot/co-pilot
    MISSION_SPECIALIST = 3, // Mission specialist
    FLIGHT_ENGINEER = 4   // Flight engineer
} AstronautRank;

/**
 * @brief Mission status enumeration
 */
typedef enum {
    PLANNED = 0,    // Mission is in planning phase
    ACTIVE = 1,     // Mission is currently active/in progress
    COMPLETED = 2,  // Mission completed successfully
    ABORTED = 3     // Mission was aborted
} MissionStatus;

/**
 * @brief Communication message priority enumeration
 */
typedef enum {
    ROUTINE = 1,    // Standard operational messages
    URGENT = 2,     // High priority messages requiring prompt attention
    EMERGENCY = 3   // Emergency messages requiring immediate response
} MessagePriority;

/* =============================================================================
 * STRUCTURE DEFINITIONS
 * ============================================================================= */

/**
 * @brief Astronaut structure
 */
typedef struct {
    int astronaut_id;               // Unique astronaut identifier
    char name[MAX_NAME_LENGTH];     // Astronaut's full name
    AstronautRank rank;             // Astronaut's rank/specialization
    int flight_hours;               // Total flight experience hours
    int active_mission_id;          // Current mission ID (-1 if unassigned)
} Astronaut;

/**
 * @brief Communication log structure
 */
typedef struct {
    int log_id;                           // Unique log entry identifier
    char timestamp[MAX_TIMESTAMP_LENGTH]; // "YYYY-MM-DD HH:MM"
    MessagePriority priority;             // Message priority level
    char message[MAX_MESSAGE_LENGTH];     // Message content
    int acknowledged;                     // 0 = no, 1 = yes
} CommLog;

/**
 * @brief Mission structure
 */
typedef struct {
    int mission_id;                     // Unique mission identifier
    char mission_name[MAX_NAME_LENGTH]; // Mission name/designation
    char launch_date[MAX_DATE_LENGTH];  // Launch date "YYYY-MM-DD"
    MissionStatus status;               // Current mission status
    
    // Dynamic communication logs
    CommLog *communications;            // Dynamic array of communication logs
    int comm_count;                     // Current number of communications
    int comm_capacity;                  // Current communication array capacity
} Mission;

/**
 * @brief Main mission control system structure
 */
typedef struct {
    Mission *missions;      // Dynamic array of missions
    int mission_count;      // Current number of missions
    int capacity;           // Current mission array capacity
} MissionControl;

/* =============================================================================
 * STUDENT FUNCTION PROTOTYPES - 6 REQUIRED FUNCTIONS
 * 👍 Students implement only these 6 functions
 * ============================================================================= */

/**
 * FUNCTION 1: create_mission_control (10 points)
 * Topics: Dynamic memory allocation, structures, defensive programming
 */
MissionControl* create_mission_control(int initial_capacity);

/**
 * FUNCTION 2: create_mission_with_crew (25 points)
 * Topics: Structures, enumerations, defensive programming, dynamic memory (realloc)
 */
int create_mission_with_crew(MissionControl* system, int mission_id, const char* name, 
                            const char* launch_date);

/**
 * FUNCTION 3: add_communication (20 points)
 * Topics: Structures, enumerations, defensive programming, dynamic memory expansion
 */
int add_communication(MissionControl* system, int mission_id, const char* timestamp,
                     MessagePriority priority, const char* message);

/**
 * FUNCTION 4: load_missions_from_file (15 points)
 * Topics: File I/O (fscanf), defensive programming, structures
 */
int load_missions_from_file(MissionControl* system, const char* filename);

/**
 * FUNCTION 5: save_mission_report (10 points)
 * Topics: File I/O (fprintf), structures, enumerations
 */
int save_mission_report(const MissionControl* system, const char* filename);

/**
 * FUNCTION 6: free_mission_control (10 points)
 * Topics: Dynamic memory management, defensive programming
 */
void free_mission_control(MissionControl* system);

/* =============================================================================
 * 💀 FRAMEWORK FUNCTIONS (PROVIDED - Students don't implement)
 * ============================================================================= */

// String conversion utilities
const char* rank_to_string(AstronautRank rank);
const char* status_to_string(MissionStatus status);
const char* priority_to_string(MessagePriority priority);

// Validation utilities
int is_valid_date_format(const char* date_str);
int is_valid_timestamp_format(const char* timestamp_str);

// Test framework functions
void test_create_system(int capacity, const char* expected_result);
void test_create_mission(int mission_id, const char* name, const char* launch_date, 
                        const char* expected_result);
void test_add_comm(int mission_id, const char* timestamp, int priority, 
                  const char* message, const char* expected_result);
void test_load_file(const char* filename, const char* expected_result);
void test_save_report(const char* filename, const char* expected_result);
void test_free_system(const char* expected_result);

// Test file processor
void process_test_file(const char* filename);

// Timeout protection
extern volatile int timeout_occurred;
void setup_timeout_handler(void);
void timeout_handler(int sig);

#endif /* SPACE_MISSION_H */
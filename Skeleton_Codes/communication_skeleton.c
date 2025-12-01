/* 
   ####################################################
   IMPLEMENT FUNCTION 3:
    - add_communication() (20 points)
   ################################################### 
*/


#include "space_mission.h"

/**
 * FUNCTION 3: add_communication 
 * 
 * PURPOSE: Add a communication log entry to a specified mission
 * 
 * PARAMETERS:
 *   system - Pointer to mission control system
 *   mission_id - Target mission identifier
 *   timestamp - Communication timestamp in YYYY-MM-DD HH:MM format
 *   priority - Message priority (ROUTINE, URGENT, or EMERGENCY)
 *   message - Communication message content
 * 
 * RETURNS:
 *   0 on success, -1 on failure
 * 
 * REQUIREMENTS:
 *  - Validate all parameters: input parameters, enum values, NULL checks, timestamp format using `is_valid_timestamp_format()`
 *  - Validate MessagePriority enum values (ROUTINE, URGENT, EMERGENCY)
 *  - Find target mission by mission_id, return -1 if not found
 *  - Expand communications array using realloc when needed (double capacity)
 *  - Generate unique log_id and initialize communication structure
 */
int add_communication(MissionControl* system, int mission_id, const char* timestamp,
                     MessagePriority priority, const char* message) {
    
    // TODO: Implement add_communication with comprehensive validation
    //
    // 1. INPUT VALIDATION:
    //    - Check system, timestamp, and message for NULL
    //    - Verify message is not empty and within MAX_MESSAGE_LENGTH
    //    - Use/call is_valid_timestamp_format() in the driver to validate timestamp
    //    - Validate priority enum (ROUTINE, URGENT, EMERGENCY)
    //    - Return -1 if any validation fails
    //
    // 2. FIND TARGET MISSION:
    //    - Search through system->missions array for matching mission_id
    //    - Return -1 if mission not found
    //
    // 3. EXPAND COMMUNICATIONS ARRAY:
    //    - Check if communications array needs expansion (comm_count >= comm_capacity)
    //    - Use realloc() to double capacity if needed
    //    - Update mission's comm_capacity after successful realloc
    //
    // 4. ADD NEW COMMUNICATION:
    //    - Generate unique log_id (use comm_count + 1)
    //    - Copy timestamp and message to new communication entry
    //    - Set priority and acknowledged status (0 = not acknowledged)
    //    - Increment mission's comm_count
    //    - Return 0 for success
    
    // Your implementation here:
    
}
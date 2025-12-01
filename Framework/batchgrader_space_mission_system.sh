#!/bin/bash

# ===============================================================================
# Space Mission Control System Assignment - Batch Grading Script
# ===============================================================================
# This script processes all student submissions and generates grade files

echo "=========================================================================="
echo "        Space Mission Control System Assignment - Batch Grading"
echo "=========================================================================="
echo "Date: $(date)"
echo "Note: This script processes ANY .zip file containing C implementations"
echo

# Check if autograder script exists
if [ ! -f "autograder_space_mission_system.sh" ]; then
    echo "❌ ERROR: autograder_space_mission_system.sh not found in current directory!"
    echo "Please place the autograder script in the same directory as this batch script."
    exit 1
fi

# Check if required framework files exist
REQUIRED_FRAMEWORK_FILES=("driver.c" "space_mission.h" "Makefile" "TESTCASES.txt" "EXPECTED_OUTPUT.txt")
for file in "${REQUIRED_FRAMEWORK_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        # Also check for Makefile (capital M)
        if [ "$file" == "makefile" ] && [ -f "Makefile" ]; then
            continue
        fi
        echo "❌ ERROR: Required framework file '$file' not found!"
        echo "Please ensure all framework files are in the current directory."
        exit 1
    fi
done

# Check for test data files
TEST_DATA_FILES=("empty_missions_data.txt" "invalid_missions_data.txt" "rigorous_missions_data.txt")
for file in "${TEST_DATA_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "⚠️  WARNING: Test data file '$file' not found!"
        echo "Some tests may fail if this file is required."
    fi
done

# Make autograder script executable
chmod +x autograder_space_mission_system.sh

# Create results directory with fixed name
RESULTS_DIR="GRADING_RESULTS"
mkdir -p "$RESULTS_DIR"

# Create summary file
SUMMARY_FILE="$RESULTS_DIR/GRADING_SUMMARY.txt"
echo "Space Mission Control System Assignment - Grading Summary" > "$SUMMARY_FILE"
echo "Generated: $(date)" >> "$SUMMARY_FILE"
echo "=================================================================" >> "$SUMMARY_FILE"
echo >> "$SUMMARY_FILE"

# Create detailed log file
LOG_FILE="$RESULTS_DIR/batch_grading.log"
echo "Batch Grading Log - $(date)" > "$LOG_FILE"
echo "=================================" >> "$LOG_FILE"
echo >> "$LOG_FILE"

# Initialize counters
TOTAL_STUDENTS=0
SUCCESSFUL_GRADES=0
FAILED_GRADES=0
PERFECT_SCORES=0
COMPILATION_FAILURES=0

# Required C files for the assignment
REQUIRED_C_FILES=("mission_control.c" "communication.c" "file_io.c" "memory_mgmt.c")

# Function to log messages
log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Function to extract student name from filename
extract_student_name() {
    local filename="$1"
    # Remove .zip suffix and try to extract meaningful name
    local base_name=$(basename "$filename" .zip)
    
    # Try different patterns to extract student name
    if [[ "$base_name" =~ ^[Ss]pace.*[_\-\.]([A-Za-z]+[_\-\s]+[A-Za-z]+) ]]; then
        # Pattern: Space_Mission_FirstName_LastName
        echo "${BASH_REMATCH[1]}" | tr '_-' ' '
    elif [[ "$base_name" =~ ^[Aa]ssignment.*[_\-\.]([A-Za-z]+[_\-\s]+[A-Za-z]+) ]]; then
        # Pattern: Assignment4_FirstName_LastName
        echo "${BASH_REMATCH[1]}" | tr '_-' ' '
    elif [[ "$base_name" =~ ^([A-Za-z]+[_\-\s]+[A-Za-z]+)[_\-\.].*[Aa]ssignment ]]; then
        # Pattern: FirstName_LastName_Assignment4
        echo "${BASH_REMATCH[1]}" | tr '_-' ' '
    elif [[ "$base_name" =~ ^([A-Za-z]+[_\-\s]+[A-Za-z]+) ]]; then
        # Pattern: FirstName_LastName or FirstName-LastName
        echo "${BASH_REMATCH[1]}" | tr '_-' ' '
    elif [[ "$base_name" =~ ([A-Za-z]+)[\._\-]([A-Za-z]+) ]]; then
        # Pattern: john.doe or john_doe or john-doe
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    else
        # Fallback: use the entire filename (cleaned up)
        echo "$base_name" | tr '_-' ' ' | sed 's/[^A-Za-z0-9 ]//g'
    fi
}

# Function to create clean filename
create_clean_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Process all ZIP files in the directory
shopt -s nullglob
zip_files=(*.zip)

if [ ${#zip_files[@]} -eq 0 ]; then
    echo "❌ No ZIP files found in current directory"
    echo "Please ensure student submission ZIP files are in the current directory."
    echo "Supported format: Any .zip file containing the 4 required C implementation files"
    exit 1
fi

log_message "Found ${#zip_files[@]} student submission(s) to process"
log_message ""

# Process each ZIP file
for zip_file in "${zip_files[@]}"; do
    TOTAL_STUDENTS=$((TOTAL_STUDENTS + 1))
    
    # Extract student information
    STUDENT_NAME=$(extract_student_name "$zip_file")
    CLEAN_NAME=$(create_clean_name "$STUDENT_NAME")
    
    # If no meaningful name extracted, use the zip filename
    if [[ -z "$STUDENT_NAME" || "$STUDENT_NAME" =~ ^[[:space:]]*$ ]]; then
        STUDENT_NAME=$(basename "$zip_file" .zip)
        CLEAN_NAME=$(create_clean_name "$STUDENT_NAME")
    fi
    
    log_message "Processing: $STUDENT_NAME ($zip_file)"
    
    # Create temporary directory for extraction
    TEMP_DIR="temp_${CLEAN_NAME}_$$"
    mkdir -p "$TEMP_DIR"
    
    # Extract ZIP file
    log_message "  📦 Extracting submission..."
    if ! unzip -q "$zip_file" -d "$TEMP_DIR" 2>/dev/null; then
        log_message "  ❌ ERROR: Failed to extract $zip_file"
        echo "$STUDENT_NAME: EXTRACTION_FAILED - Could not extract ZIP file" >> "$SUMMARY_FILE"
        FAILED_GRADES=$((FAILED_GRADES + 1))
        rm -rf "$TEMP_DIR"
        continue
    fi
    
    # Search for required C files recursively
    log_message "  🔍 Searching for required C implementation files..."
    FOUND_FILES=()
    MISSING_FILES=()
    
    for required_file in "${REQUIRED_C_FILES[@]}"; do
        found_file=$(find "$TEMP_DIR" -name "$required_file" -type f | head -1)
        if [ -n "$found_file" ]; then
            FOUND_FILES+=("$required_file:$found_file")
            log_message "    ✅ Found: $required_file"
        else
            MISSING_FILES+=("$required_file")
            log_message "    ❌ Missing: $required_file"
        fi
    done
    
    # Check if all required files are found
    if [ ${#MISSING_FILES[@]} -gt 0 ]; then
        log_message "  ❌ ERROR: Missing required implementation files: ${MISSING_FILES[*]}"
        
        # List all C files found for debugging
        log_message "  📁 All C files found in submission:"
        find "$TEMP_DIR" -name "*.c" -type f | sed 's/^/    /' | tee -a "$LOG_FILE"
        
        echo "$STUDENT_NAME: MISSING_FILES - Missing: ${MISSING_FILES[*]}" >> "$SUMMARY_FILE"
        FAILED_GRADES=$((FAILED_GRADES + 1))
        rm -rf "$TEMP_DIR"
        continue
    fi
    
    # Copy student files to current directory
    log_message "  📋 Copying student implementation files..."
    for file_info in "${FOUND_FILES[@]}"; do
        file_name=$(echo "$file_info" | cut -d':' -f1)
        file_path=$(echo "$file_info" | cut -d':' -f2)
        
        if ! cp "$file_path" "./$file_name"; then
            log_message "  ❌ ERROR: Failed to copy $file_name"
            echo "$STUDENT_NAME: COPY_FAILED - Could not copy $file_name" >> "$SUMMARY_FILE"
            FAILED_GRADES=$((FAILED_GRADES + 1))
            rm -rf "$TEMP_DIR"
            continue 2
        fi
        
        log_message "    ✅ Copied: $file_name"
    done
    
   # Check for README file with flexible case-insensitive matching
    README_FOUND=false
    README_FILE_FOUND=""

    # Find any file with "readme" in name (case-insensitive)
    readme_candidates=$(find "$TEMP_DIR" -type f -iname "*readme*" 2>/dev/null)
    
    if [ -n "$readme_candidates" ]; then
        # Priority: PDF > DOCX > TXT > MD > No extension > Any other
        
        # Try PDF first
        found_readme=$(echo "$readme_candidates" | grep -i '\.pdf' | head -1)
        
        # Try DOCX
        if [ -z "$found_readme" ]; then
            found_readme=$(echo "$readme_candidates" | grep -i '\.docx' | head -1)
        fi
        
        # Try TXT
        if [ -z "$found_readme" ]; then
            found_readme=$(echo "$readme_candidates" | grep -i '\.txt' | head -1)
        fi
        
        # Try MD
        if [ -z "$found_readme" ]; then
            found_readme=$(echo "$readme_candidates" | grep -i '\.md' | head -1)
        fi
        
        # Try no extension (README, readme)
        if [ -z "$found_readme" ]; then
            found_readme=$(echo "$readme_candidates" | grep -iE '/readme$' | head -1)
        fi
        
        # # Take any file with readme in name
        # if [ -z "$found_readme" ]; then
        #     found_readme=$(echo "$readme_candidates" | head -1)
        # fi
        
        if [ -n "$found_readme" ]; then
            README_FOUND=true
            README_FILE_FOUND="$found_readme"
            log_message "    ✅ Found README: $(basename "$README_FILE_FOUND")"
        fi
    fi
    
    if [ "$README_FOUND" = false ]; then
        log_message "  ❌ ERROR: Missing README file"
        echo "$STUDENT_NAME: MISSING_README - No README file found" >> "$SUMMARY_FILE"
        FAILED_GRADES=$((FAILED_GRADES + 1))
        rm -rf "$TEMP_DIR"
        echo ""
        continue
    fi
    
    
    # Create individual grade report
    GRADE_FILE="$RESULTS_DIR/${CLEAN_NAME}_Grade.txt"
    log_message "  🚀 Running autograder..."
    
    # Generate grade report header
    {
        echo "=========================================================================="
        echo "              GRADE REPORT FOR: $STUDENT_NAME"
        echo "=========================================================================="
        echo "Submission File: $zip_file"
        echo "Graded on: $(date)"
        echo "Graded by: Space Mission Control System Autograder"
        echo
        
        if [ -n "$README_INFO" ]; then
            echo "Student Information from README:"
            echo "--------------------------------"
            echo "$README_INFO"
            echo
        fi
        
        echo "Implementation Files Submitted:"
        echo "-------------------------------"
        for file_info in "${FOUND_FILES[@]}"; do
            file_name=$(echo "$file_info" | cut -d':' -f1)
            echo "✅ $file_name"
        done
        echo
        
        echo "Autograder Results:"
        echo "==================="
        echo
    } > "$GRADE_FILE"
    
    # Run the autograder with timeout protection (20 seconds)
    AUTOGRADER_OUTPUT=$(timeout 20 ./autograder_space_mission_system.sh 2>&1)
    AUTOGRADER_EXIT_CODE=$?
    
    # Append autograder output to grade file
    echo "$AUTOGRADER_OUTPUT" >> "$GRADE_FILE"
    
    if [ $AUTOGRADER_EXIT_CODE -eq 0 ]; then
        log_message "  ✅ Grading completed successfully"
        
        # Extract final score and percentage from autograder output
        AUTOGRADER_TOTAL=$(echo "$AUTOGRADER_OUTPUT" | grep "AUTOGRADER TOTAL:" | tail -1 | grep -o '[0-9]\+/[0-9]\+' | head -1)
        PERCENTAGE=$(echo "$AUTOGRADER_OUTPUT" | grep "AUTOGRADER PERCENTAGE:" | tail -1 | grep -o '[0-9]\+%' | head -1)
        
        # Extract compilation status
        COMPILATION_CHECK=$(echo "$AUTOGRADER_OUTPUT" | grep "Compilation successful" | head -1)
        
        if [ -n "$AUTOGRADER_TOTAL" ]; then
            if [ -n "$PERCENTAGE" ]; then
                echo "$STUDENT_NAME: $AUTOGRADER_TOTAL ($PERCENTAGE)" >> "$SUMMARY_FILE"
                log_message "  📊 Score: $AUTOGRADER_TOTAL ($PERCENTAGE)"
                
                # Check for perfect score (100% on autograder portion)
                if [[ "$PERCENTAGE" == "100%" ]]; then
                    PERFECT_SCORES=$((PERFECT_SCORES + 1))
                fi
            else
                echo "$STUDENT_NAME: $AUTOGRADER_TOTAL" >> "$SUMMARY_FILE"
                log_message "  📊 Score: $AUTOGRADER_TOTAL"
            fi
        else
            echo "$STUDENT_NAME: COMPLETED - Check individual grade file" >> "$SUMMARY_FILE"
            log_message "  📊 Grading completed - check grade file for details"
        fi
        
        # Check if compilation failed
        if [[ -z "$COMPILATION_CHECK" ]]; then
            COMPILATION_FAILURES=$((COMPILATION_FAILURES + 1))
        fi
        
        SUCCESSFUL_GRADES=$((SUCCESSFUL_GRADES + 1))
        
    elif [ $AUTOGRADER_EXIT_CODE -eq 124 ]; then
        log_message "  ⏱️  ERROR: Autograder timed out (20-second limit)"
        echo >> "$GRADE_FILE"
        echo "ERROR: Autograder timed out after 20 seconds" >> "$GRADE_FILE"
        echo "This usually indicates infinite loops in your C implementations." >> "$GRADE_FILE"
        echo "Common causes in C programming:" >> "$GRADE_FILE"
        echo "- Missing pointer increment statements in loops" >> "$GRADE_FILE"
        echo "- Missing loop increment statements (i++ missing)" >> "$GRADE_FILE"
        echo "- Incorrect pointer arithmetic causing endless loops" >> "$GRADE_FILE"
        echo "- Wrong loop conditions or array bounds" >> "$GRADE_FILE"
        echo "- Check mission_control.c, communication.c, file_io.c, and memory_mgmt.c functions" >> "$GRADE_FILE"
        echo "$STUDENT_NAME: TIMEOUT - Infinite loop detected" >> "$SUMMARY_FILE"
        FAILED_GRADES=$((FAILED_GRADES + 1))
        
    else
        log_message "  ❌ ERROR: Student code caused autograder failure (exit code: $AUTOGRADER_EXIT_CODE)"
        echo >> "$GRADE_FILE"
        echo "ERROR: Your C code caused the autograder to fail" >> "$GRADE_FILE"
        echo "This indicates problems in your implementation:" >> "$GRADE_FILE"
        echo "- Compilation errors (syntax errors, missing semicolons, etc.)" >> "$GRADE_FILE"
        echo "- Runtime crashes (segmentation faults, null pointer access)" >> "$GRADE_FILE"
        echo "- Infinite loops (missing pointer increments or incorrect conditions)" >> "$GRADE_FILE"
        echo "- Missing or incomplete function implementations" >> "$GRADE_FILE"
        echo "- Memory allocation/deallocation errors" >> "$GRADE_FILE"
        echo "- Check your C code carefully for these common issues" >> "$GRADE_FILE"
        echo >> "$GRADE_FILE"
        echo "The problem is in YOUR CODE, not the grading system." >> "$GRADE_FILE"
        echo "$STUDENT_NAME: CODE_ERROR - Student implementation issue" >> "$SUMMARY_FILE"
        FAILED_GRADES=$((FAILED_GRADES + 1))
    fi
    
    # Save Mission_Report directory for this student (if it exists)
    if [ -d "Mission_Report" ]; then
        STUDENT_MISSION_DIR="$RESULTS_DIR/${CLEAN_NAME}_Mission_Report"
        log_message "  📁 Saving Mission_Report directory..."
        cp -r "Mission_Report" "$STUDENT_MISSION_DIR"
        log_message "    ✅ Mission reports saved to: $STUDENT_MISSION_DIR"
        
        # Clean up Mission_Report for next student
        rm -rf "Mission_Report"
    else
        log_message "  ⚠️  No Mission_Report directory generated"
    fi
    
    # Clean up temporary files and student implementation files
    log_message "  🧹 Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    
    # Remove student implementation files
    for file in "${REQUIRED_C_FILES[@]}"; do
        rm -f "$file" 2>/dev/null
    done
    
    # Remove any generated files from autograder
    rm -f STUDENT_OUTPUT.txt space_mission *.o STUDENT_OUTPUT_RAW.txt 2>/dev/null
    
    log_message "  💾 Grade saved to: $GRADE_FILE"
    log_message ""
done

# Generate final summary statistics
echo >> "$SUMMARY_FILE"
echo "=================================================================" >> "$SUMMARY_FILE"
echo "                    GRADING STATISTICS" >> "$SUMMARY_FILE"
echo "=================================================================" >> "$SUMMARY_FILE"
echo "Total Students Processed: $TOTAL_STUDENTS" >> "$SUMMARY_FILE"
echo "Successfully Graded: $SUCCESSFUL_GRADES" >> "$SUMMARY_FILE"
echo "Failed to Grade: $FAILED_GRADES" >> "$SUMMARY_FILE"
echo "Perfect Autograder Scores: $PERFECT_SCORES" >> "$SUMMARY_FILE"
echo "Compilation Failures: $COMPILATION_FAILURES" >> "$SUMMARY_FILE"
echo >> "$SUMMARY_FILE"
if [ $TOTAL_STUDENTS -gt 0 ]; then
    echo "Success Rate: $(( (SUCCESSFUL_GRADES * 100) / TOTAL_STUDENTS ))%" >> "$SUMMARY_FILE"
    echo "Perfect Score Rate: $(( (PERFECT_SCORES * 100) / TOTAL_STUDENTS ))%" >> "$SUMMARY_FILE"
    echo "Compilation Failure Rate: $(( (COMPILATION_FAILURES * 100) / TOTAL_STUDENTS ))%" >> "$SUMMARY_FILE"
fi
echo >> "$SUMMARY_FILE"
echo "Individual grade files are in: $RESULTS_DIR/" >> "$SUMMARY_FILE"
echo "Individual Mission_Report directories are in: $RESULTS_DIR/" >> "$SUMMARY_FILE"
echo "Detailed log file: $LOG_FILE" >> "$SUMMARY_FILE"
echo >> "$SUMMARY_FILE"
echo "Note: Manual grading (10 points) for code quality, comments," >> "$SUMMARY_FILE"
echo "and README still needs to be added to autograder scores." >> "$SUMMARY_FILE"

# Display final results
echo "=========================================================================="
echo "                    BATCH GRADING COMPLETE"
echo "=========================================================================="
echo "🚀 Total Students Processed: $TOTAL_STUDENTS"
echo "✅ Successfully Graded: $SUCCESSFUL_GRADES"
echo "❌ Failed to Grade: $FAILED_GRADES"
echo "🌟 Perfect Autograder Scores: $PERFECT_SCORES"
echo "🔨 Compilation Failures: $COMPILATION_FAILURES"
if [ $TOTAL_STUDENTS -gt 0 ]; then
    echo "📈 Success Rate: $(( (SUCCESSFUL_GRADES * 100) / TOTAL_STUDENTS ))%"
    echo "⭐ Perfect Score Rate: $(( (PERFECT_SCORES * 100) / TOTAL_STUDENTS ))%"
fi
echo
echo "📁 Results Directory: $RESULTS_DIR/"
echo "📋 Summary File: $SUMMARY_FILE"
echo "📝 Detailed Log: $LOG_FILE"
echo
echo "📄 Individual Grade Files:"
find "$RESULTS_DIR" -name "*_Grade.txt" -type f | sed 's/^/  /' | sort
echo
echo "📁 Individual Mission Report Directories:"
find "$RESULTS_DIR" -name "*_Mission_Report" -type d | sed 's/^/  /' | sort
echo
echo "⏰ Grading completed at: $(date)"
echo "=========================================================================="

# Final cleanup
echo "🧹 Final cleanup completed."
echo
echo "📝 REMINDER: Add manual grading scores (10 points) for:"
echo "   - Code quality and style"
echo "   - Comments and documentation" 
echo "   - README file completeness"
echo
echo "🚀 Ready for final grade submission!"

exit 0
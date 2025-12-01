#!/bin/bash

# ===============================================================================
# SPACE MISSION CONTROL SYSTEM AUTOGRADER - FIXED VERSION
# Simple, elegant autograder following the restaurant pattern
# Total Points: 90 (Function 1: 10, Function 2: 25, Function 3: 20, Function 4: 15, Function 5: 10, Function 6: 10)
# 
# BUGFIX: Fixed printf formatting issue in show_function_differences function
# ===============================================================================

echo "=========================================="
echo "  Space Mission Control Autograder"
echo "=========================================="
echo ""

# Initialize scores
compilation_score=0
function1_score=0
function2_score=0
function3_score=0
function4_score=0
function5_score=0
function6_score=0

# Step 1: Check required files
echo "🔍 Checking required files..."
required_files=("TESTCASES.txt" "EXPECTED_OUTPUT.txt" "space_mission.h" 
                "mission_control.c" "communication.c" "file_io.c" 
                "memory_mgmt.c" "driver.c")

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -ne 0 ]; then
    echo "❌ ERROR: Missing files: ${missing_files[*]}"
    echo ""
    echo "Required files for submission:"
    for file in "${required_files[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Make sure all files are in the current directory and try again."
    exit 1
fi

if [ ! -f "Makefile" ] && [ ! -f "makefile" ]; then
    echo "❌ ERROR: Makefile not found!"
    echo "Please ensure Makefile is present and try again."
    exit 1
fi

echo "✅ All required files found"

# Step 2: Clean rebuild with timeout protection
echo "🔨 Building space mission system..."
if timeout 10 make clean >/dev/null 2>&1; then
    echo "   Clean completed"
else
    echo "   Clean skipped (not critical)"
fi

if timeout 15 make >/dev/null 2>&1; then
    compilation_score=10
    echo "✅ Compilation successful"
else
    echo "❌ Compilation failed"
    echo ""
    echo "Compilation errors:"
    make 2>&1 | head -10
    echo ""
    echo "Please fix compilation errors and resubmit."
    exit 1
fi

# Check if executable was created
if [ ! -x "space_mission" ]; then
    echo "❌ ERROR: space_mission executable not created"
    echo "Make sure your Makefile creates an executable named 'space_mission'"
    exit 1
fi

# Step 3: Generate student output with timeout protection
echo "🚀 Running space mission system..."
if timeout 20 ./space_mission > STUDENT_OUTPUT_RAW.txt 2>&1; then
    echo "✅ Space mission system executed"    
    # BUGFIX: Properly handle output processing
    # Remove any trailing whitespace and ensure consistent line endings
    sed 's/[[:space:]]*$//' STUDENT_OUTPUT_RAW.txt > STUDENT_OUTPUT.txt
    rm STUDENT_OUTPUT_RAW.txt
else
    exit_code=$?
    if [ $exit_code -eq 124 ]; then
        echo "❌ Space mission system timed out (possible infinite loop)"
    else
        echo "❌ Space mission system crashed or failed"
    fi
    echo ""
    echo "Debug your implementation and try again."
    echo "Common issues:"
    echo "  - Infinite loops in functions"
    echo "  - Segmentation faults (NULL pointer access)"
    echo "  - Missing return statements"
    exit 1
fi

echo ""

# Step 4: Compare outputs and grade functions
echo "🔍 Grading Function Implementations..."

# Extract function data function
extract_function_data() {
    local function_prefix="$1"
    local file="$2"
    
    if [[ ! -f "$file" ]]; then
        echo ""
        return
    fi
    
    grep "^${function_prefix}" "$file" 2>/dev/null || echo ""
}

# Compare function data with exact matching
compare_function_data() {
    local student_data="$1"
    local expected_data="$2"
    
    if [[ -z "$expected_data" ]]; then
        echo "0"
        return
    fi
    
    if [[ -z "$student_data" ]]; then
        echo "0"
        return
    fi
    
    # BUGFIX: Normalize whitespace before comparison
    local normalized_student=$(echo "$student_data" | sed 's/[[:space:]]*$//')
    local normalized_expected=$(echo "$expected_data" | sed 's/[[:space:]]*$//')
    
    # Convert to arrays for exact comparison
    local -a expected_lines
    local -a student_lines
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            expected_lines+=("$line")
        fi
    done <<< "$normalized_expected"
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            student_lines+=("$line")
        fi
    done <<< "$normalized_student"
    
    # Must have exact same number of lines
    if [[ ${#student_lines[@]} -ne ${#expected_lines[@]} ]]; then
        echo "0"
        return
    fi
    
    # Check each line matches exactly
    local correct_count=0
    for ((i=0; i<${#expected_lines[@]}; i++)); do
        if [[ "${student_lines[i]}" == "${expected_lines[i]}" ]]; then
            correct_count=$((correct_count + 1))
        fi
    done
    
    # Calculate percentage
    if [[ ${#expected_lines[@]} -eq 0 ]]; then
        echo "100"
    else
        local percentage=$(( (correct_count * 100) / ${#expected_lines[@]} ))
        echo "$percentage"
    fi
}

# Show detailed differences for debugging - BUGFIX: Fixed printf formatting
show_function_differences() {
    local student_data="$1"
    local expected_data="$2"
    local function_name="$3"
    
    echo ""
    echo "   🔍 DETAILED ANALYSIS for $function_name:"
    echo "   =========================================="
    
    # BUGFIX: Normalize whitespace before processing
    local normalized_student=$(echo "$student_data" | sed 's/[[:space:]]*$//')
    local normalized_expected=$(echo "$expected_data" | sed 's/[[:space:]]*$//')
    
    local -a expected_lines
    local -a student_lines
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            expected_lines+=("$line")
        fi
    done <<< "$normalized_expected"
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            student_lines+=("$line")
        fi
    done <<< "$normalized_student"
    
    echo "   📊 EXPECTED OUTPUT (${#expected_lines[@]} lines):"
    for i in "${!expected_lines[@]}"; do
        printf "   %2d: %s\n" $((i+1)) "${expected_lines[i]}"
    done
    
    echo ""
    echo "   📊 YOUR OUTPUT (${#student_lines[@]} lines):"
    for i in "${!student_lines[@]}"; do
        printf "   %2d: %s\n" $((i+1)) "${student_lines[i]}"
    done
    
    echo ""
    echo "   🔍 LINE-BY-LINE COMPARISON:"
    
    local max_lines=${#expected_lines[@]}
    if [[ ${#student_lines[@]} -gt $max_lines ]]; then
        max_lines=${#student_lines[@]}
    fi
    
    local mismatches=0
    
    for ((i=0; i<max_lines; i++)); do
        local expected_line="${expected_lines[i]:-}"
        local student_line="${student_lines[i]:-}"
        
        if [[ "$expected_line" == "$student_line" ]]; then
            printf "   %2d: ✅ MATCH    %s\n" $((i+1)) "$expected_line"
        else
            # BUGFIX: Properly escape and format the diff output
            printf "   %2d: ❌ DIFF     Expected Output: %s\n" $((i+1)) "$expected_line"
            printf "   %2s 	           Your Output:     %s\n" "" "$student_line"
            mismatches=$((mismatches + 1))
        fi
    done
    
    echo ""
    echo "   📈 SUMMARY: $mismatches mismatches out of $max_lines lines"
    echo "   =========================================="
    echo ""
}

# Function testing with proper scoring according to rubric
test_functions() {
    # Define function tests: "PREFIX:function_name:max_points"
    local functions=(
        "CREATE_SYSTEM:Function1_create_mission_control:10"
        "CREATE_MISSION:Function2_create_mission_with_crew:25" 
        "ADD_COMM:Function3_add_communication:20"
        "LOAD_FILE:Function4_load_missions_from_file:15"
        "SAVE_REPORT:Function5_save_mission_report:10"
        # Function 6 (free_mission_control) is tested via valgrind memory check
    )

    for func_info in "${functions[@]}"; do
        local prefix=$(echo "$func_info" | cut -d':' -f1)
        local function_name=$(echo "$func_info" | cut -d':' -f2)
        local max_points=$(echo "$func_info" | cut -d':' -f3)

        echo "   Testing $function_name..."

        local student_data=$(extract_function_data "$prefix" "STUDENT_OUTPUT.txt")
        local expected_data=$(extract_function_data "$prefix" "EXPECTED_OUTPUT.txt")

        if [[ -n "$expected_data" ]]; then
            if [[ -n "$student_data" ]]; then
                local match_percentage=$(compare_function_data "$student_data" "$expected_data")
                local points=$(( (max_points * match_percentage) / 100 ))
            else
                local match_percentage=0
                local points=0
            fi
        else
            local match_percentage=0
            local points=0
            echo "   ⚠️  No expected data found for $function_name"
        fi

        # Store scores in corresponding variables
        case $prefix in
            "CREATE_SYSTEM") function1_score=$points ;;
            "CREATE_MISSION") function2_score=$points ;;
            "ADD_COMM") function3_score=$points ;;
            "LOAD_FILE") function4_score=$points ;;
            "SAVE_REPORT") function5_score=$points ;;
        esac

        # Show results with debugging for non-perfect scores
        if [[ $match_percentage -eq 100 ]]; then
            echo "   ✅ $function_name: Perfect implementation ($points/$max_points points)"
        elif [[ $match_percentage -ge 70 ]]; then
            echo "   🟡 $function_name: Good implementation ($match_percentage% match, $points/$max_points points)"
            show_function_differences "$student_data" "$expected_data" "$function_name"
        else
            echo "   ❌ $function_name: Issues detected ($match_percentage% match, $points/$max_points points)"
            show_function_differences "$student_data" "$expected_data" "$function_name"
        fi
    done
}

# Run function tests
test_functions

# Step 5: Memory leak testing (Function 6: free_mission_control)
echo "   Testing Function6_free_mission_control..."

if command -v valgrind > /dev/null 2>&1; then
    echo "      💧 Running valgrind memory leak detection"
    if timeout 30 valgrind --leak-check=full --error-exitcode=1 --quiet ./space_mission > /dev/null 2>&1; then
        function6_score=10
        echo "   ✅ Function6_free_mission_control: No memory leaks detected (10/10 points)"
    else
        function6_score=0
        echo "   ❌ Function6_free_mission_control: Memory leaks detected (0/10 points)"
        echo "   💡 Run 'valgrind --leak-check=full ./space_mission' to debug"
    fi
else
    function6_score=5  # Partial credit if valgrind unavailable
    echo "   ⚠️  Valgrind not available - giving partial credit (5/10 points)"
    echo "   📝 Install valgrind: sudo apt install valgrind"
fi

# Step 6: Final results following the agreed rubric
total_score=$((function1_score + function2_score + function3_score + function4_score + function5_score + function6_score))
max_total=90
percentage=$(( (total_score * 100) / max_total ))

echo ""
echo "=========================================="
echo "           AUTOGRADER RESULTS"
echo "=========================================="
echo "Function 1 (create_mission_control):     $function1_score/10 points"
echo "Function 2 (create_mission_with_crew):   $function2_score/25 points"  
echo "Function 3 (add_communication):          $function3_score/20 points"
echo "Function 4 (load_missions_from_file):    $function4_score/15 points"
echo "Function 5 (save_mission_report):        $function5_score/10 points"
echo "Function 6 (free_mission_control):       $function6_score/10 points"
echo "----------------------------------------"
echo "AUTOGRADER TOTAL:         $total_score/$max_total points"
echo "AUTOGRADER PERCENTAGE:    $percentage%"
echo "----------------------------------------"
echo "Manual Grading:           /10 points (README + Code Quality)"
echo "FINAL TOTAL:              /$((max_total + 10)) points"
echo "=========================================="

echo ""

# Grade classification
if [[ $total_score -eq $max_total ]]; then
    echo "🎉 PERFECT! All functions working correctly!"
elif [[ $total_score -ge 81 ]]; then  # 90% of 90
    echo "🌟 EXCELLENT! Outstanding implementation!"
elif [[ $total_score -ge 72 ]]; then  # 80% of 90
    echo "👍 VERY GOOD! Strong implementation!"
elif [[ $total_score -ge 63 ]]; then  # 70% of 90
    echo "✅ GOOD! Solid implementation!"
elif [[ $total_score -ge 54 ]]; then  # 60% of 90
    echo "⚠️  SATISFACTORY! Needs some improvement!"
else
    echo "❌ NEEDS SIGNIFICANT WORK!"
fi

echo ""

# Show debug files information
if [[ -f "STUDENT_OUTPUT.txt" ]]; then
    echo "📄 Debug files available:"
    echo "   - STUDENT_OUTPUT.txt (your program's output)"
    echo "   - EXPECTED_OUTPUT.txt (reference output)"  
    echo "   - Run 'diff STUDENT_OUTPUT.txt EXPECTED_OUTPUT.txt' for detailed comparison"
    echo "   - Mission reports saved to Mission_Report/ directory"
fi

echo ""
echo "📈 Test Levels Available:"
echo "   SIMPLE (5 tests):   cp simple_input.txt INPUT.txt; cp simple_expected_output.txt EXPECTED_OUTPUT.txt"
echo "   MODERATE (15 tests): cp moderate_input.txt INPUT.txt; cp moderate_expected_output.txt EXPECTED_OUTPUT.txt"  
echo "   RIGOROUS (30 tests): cp rigorous_input.txt INPUT.txt; cp rigorous_expected_output.txt EXPECTED_OUTPUT.txt"

echo ""

  rm STUDENT_OUTPUT.txt

# Exit with appropriate code
if [[ $percentage -ge 70 ]]; then
    exit 0
else
    exit 1
fi
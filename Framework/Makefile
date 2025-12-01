# Space Mission System Makefile

CC = gcc
CFLAGS = -std=c17 -Wall -Wextra -Werror -pedantic -g -O0
TARGET = space_mission
VALGRIND = valgrind
VALGRIND_FLAGS = --leak-check=full --show-leak-kinds=all --track-origins=yes --error-exitcode=1

# Source files
SOURCES = mission_control.c communication.c file_io.c memory_mgmt.c driver.c

# Default target - builds only (NO automatic testing for autograder compatibility)
all: $(TARGET)

# Build target
$(TARGET): $(SOURCES) space_mission.h
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCES)

# Build only (same as all - for clarity)
build: $(TARGET)

# Manual memory test (run this yourself during development)
memtest: $(TARGET)
	@echo "\n========================================="
	@echo "Running memory leak detection..."
	@echo "========================================="
	@$(VALGRIND) --leak-check=full --error-exitcode=1 --log-file=valgrind.log ./$(TARGET)
	@echo "\n----- Memory Leak Check -----"
	@if grep -q "All heap blocks were freed" valgrind.log || grep -q "no leaks are possible" valgrind.log; then \
		echo "✅ No memory leaks detected!"; \
	else \
		echo "❌ Memory leaks detected!"; \
		echo "\nDetailed leak information:"; \
		cat valgrind.log; \
	fi
	@echo "========================================="

# Detailed valgrind with full output
valgrind: $(TARGET)
	@echo "Running detailed valgrind check..."
	$(VALGRIND) $(VALGRIND_FLAGS) --verbose ./$(TARGET)

# Quick memory check
quickcheck: $(TARGET)
	@$(VALGRIND) --leak-check=full --error-exitcode=1 ./$(TARGET)

# Clean up generated files
clean:
	@echo "Cleaning up..."
	rm -f $(TARGET) *.o STUDENT_OUTPUT*.txt valgrind.log
	@echo "Cleanup complete."

# Rebuild everything from scratch
rebuild: clean all
	@echo "Build complete. Run './$(TARGET)' to execute."

# Show available commands
help:
	@echo "Available commands:"
	@echo "  make           - Build the program (autograder compatible)"
	@echo "  make memtest   - Run memory leak detection"
	@echo "  make valgrind  - Run detailed valgrind analysis"
	@echo "  make clean     - Remove generated files"
	@echo "  make rebuild   - Clean and rebuild"

.PHONY: all build clean rebuild help valgrind memtest quickcheck
#!/bin/bash
# C REPL - Interactive C experimentation tool
# by Claude.ai and Steve Ford - see https://github.com/fordsfords/crepl
# Usage: ./crepl.sh

# Prevent core files.
ulimit -c 0

GOLDEN_FILE="crepl_golden.c"
TEMP_FILE="crepl_temp.c"
ERR_LOG="crepl_errs.log"
EXECUTABLE="./crepl_exe"

usage() {
    echo "Usage: ./crepl.sh [-h] [-c]"
    echo "Where:"
    echo "  -h : help."
    echo "  -c : continue previous session."
    list_help
}

list_help() {
    echo "Commands:"
    echo "  !help  - Show this help"
    echo "  !errs  - Show full error log"
    echo "  !list  - Show current accumulated code"
    echo "  !new   - Clear all accumulated code"
    echo "  !quit  - Exit the REPL"
    echo "  !vi    - Edit accumulated code in vi"
    echo "Autoprint types handled:"
    echo "  char, unsigned char, short, unsigned short,"
    echo "  int, unsigned int, long, unsigned long,"
    echo "  long long, unsigned long long, float, double"
}

CLEAR=1
if [ "$1" = "" ]; then :;  # no option
elif [ "$1" = "-h" ]; then usage; exit 0
elif [ "$1" = "-c" ]; then CLEAR=0
else echo "Bad option '$1'" >&2; exit 1
fi

if [ $CLEAR -ne 0 ]; then :
  # Initialize golden file
  echo "" > "$GOLDEN_FILE"
fi

# Create main template
print_main() {
  cat <<__EOF__
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>

#define PRINT_VAL(x) do { \\
    __typeof__(x) _temp_val = (x); \\
    _Generic((_temp_val), \\
        char: printf("c %d (0x%02x)\n", (int)_temp_val, (unsigned char)_temp_val), \\
        unsigned char: printf("uc %u (0x%02x)\n", _temp_val, _temp_val), \\
        short: printf("s %d (0x%04x)\n", _temp_val, (unsigned short)_temp_val), \\
        unsigned short: printf("us %u (0x%04x)\n", _temp_val, _temp_val), \\
        int: printf("i %d (0x%08x)\n", _temp_val, (unsigned int)_temp_val), \\
        unsigned int: printf("ui %u (0x%08x)\n", _temp_val, _temp_val), \\
        long: printf("l %ld (0x%0*lx)\n", _temp_val, (int)(sizeof(long)*2), (unsigned long)_temp_val), \\
        unsigned long: printf("ul %lu (0x%*lx)\n", _temp_val, (int)(sizeof(long)*2), _temp_val), \\
        long long: printf("ll %lld (0x%016llx)\n", _temp_val, (unsigned long long)_temp_val), \\
        unsigned long long: printf("ul %llu (0x%016llx)\n", _temp_val, _temp_val), \\
        float: printf("f %f\n", (double)_temp_val), \\
        double: printf("d %f\n", _temp_val), \\
        default: printf("unprintable\n") \\
    ); \\
} while(0)

int main() {
__EOF__
}

cleanup() {
    echo "Goodbye!"
    exit 0
}

echo "C REPL - Enter C statements or expressions"
echo "Type !help for commands"

while true; do
    echo -n "c> "
    if ! read -r in_line; then
        in_line="!quit"
    fi

    # Handle empty lines
    if [[ -z "$in_line" ]]; then
        continue
    fi

    # Handle special commands
    if [[ "$in_line" == "!quit" ]]; then
        cleanup
    elif [[ "$in_line" == "!help" ]]; then
        list_help
        continue
    elif [[ "$in_line" == "!errs" ]]; then
        cat "$ERR_LOG"
        continue
    elif [[ "$in_line" == "!new" ]]; then
        echo "" > "$GOLDEN_FILE"
        echo "Progam cleared"
        continue
    elif [[ "$in_line" == "!list" ]]; then
        echo "Current code:"
        cat "$GOLDEN_FILE"
        continue
    elif [[ "$in_line" == "!vi" ]]; then
        vi "$GOLDEN_FILE"
        in_line=""
    fi

    # Build the new program file.
    print_main > "$TEMP_FILE"
    cat "$GOLDEN_FILE" >> "$TEMP_FILE"

    # Check if line ends with semicolon for auto-print logic
    if [[ "$in_line" == *";" ]]; then
        echo "$in_line" >> "$TEMP_FILE"
    else
        # Auto-wrap in PRINT_VAL using statement expression
        echo "PRINT_VAL(( $in_line ));" >> "$TEMP_FILE"
        in_line="$in_line;"  # expression needs a semicolon to be added to the golden file.
    fi

    echo "    return 0;" >> "$TEMP_FILE" 
    echo "}" >> "$TEMP_FILE" 

    # Try to compile
    if gcc -std=gnu11 -o "$EXECUTABLE" "$TEMP_FILE" -lm 2> $ERR_LOG; then
        # Compilation successful - run it
        if "$EXECUTABLE" 2> $ERR_LOG; then
            # Execution successful - the input line is OK.
            echo "$in_line" >> "$GOLDEN_FILE"
        else
            echo "Runtime error, line rejected. Enter '!errs' for details."
        fi
    else
        echo "Compilation error, line rejected. Enter '!errs' for details."
    fi
done

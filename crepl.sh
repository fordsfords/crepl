#!/bin/bash
# C REPL - Interactive C experimentation tool
# by Claude.ai and Steve Ford - see https://github.com/fordsfords/crepl
# Usage: ./crepl.sh
#
# This code and its documentation is Copyright 2025 Steven Ford
# and licensed "public domain" style under Creative Commons "CC0":
#   http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, the contributors to this project have
# waived all copyright and related or neighboring rights to this work.
# In other words, you can use this code for any purpose without any
# restrictions.  This work is published from: United States.  The project home
# is https://github.com/fordsfords/crepl


# Call this to print a message only if standard in is an interactive terminal,
# not if standard in is re-directed.
term_echo() {
    if (( "$TERMINAL" )); then :
        echo "$@"
    fi
}  # term_echo


usage() {
    echo "Usage: ./crepl.sh [-h] [-c]"
    echo "Where:"
    echo "  -h : help."
    echo "  -c : continue previous session."
    list_help
}  # usage


list_help() {
    echo "Commands:"
    echo "  !help  - Show this help."
    echo "  !errs  - Show compilation/runtime errors from last attempt."
    echo "           Note that line numbers refer to the 'crepl_temp.c' file."
    echo "  !new             - Clear all accumulated code."
    echo "  !obj filename    - Include an object file in the build."
    echo "  !list            - Show current accumulated code."
    echo "  !vi              - Edit accumulated code in vi."
    echo "  !source filename - read input from filename."
    echo "  !sh    - start an interactive subshell. Exit shell to return to crepl."
    echo "  !quit  - Exit the REPL"
    echo "Autoprint types handled:"
    echo "  char, unsigned char, short, unsigned short,"
    echo "  int, unsigned int, long, unsigned long,"
    echo "  long long, unsigned long long, float, double"
}  # list_help


# Handle command-line.
parse_options()
{
    # Parse command-line options
    OPT_CONTINUE=0
    while getopts "hc" OPTION  # ???
    do
      case $OPTION in
        h) usage; exit 1 ;;
        c) OPT_CONTINUE=1 ;;
        \?) usage; exit 1 ;;
      esac
    done
    shift `expr $OPTIND - 1`  # Make $1 the first positional param after options

    if (( $OPT_CONTINUE )); then :
        if [[ ! -f "$GOLDEN_FILE" ]]; then :
            echo "Error: cannot continue previous session ($GOLDEN_FILE not found)" >&2
            exit;
        else :
            term_echo "Continuing previous session"
        fi
    else :
        # Initialize golden file
        if [ -f "$GOLDEN_FILE" ]; then :
            echo "Saving previous session to .prev"
            cp "$GOLDEN_FILE" "$GOLDEN_FILE.prev"
            touch "$OBJ_FILE"
            cp "$OBJ_FILE" "$OBJ_FILE.prev"
        fi
        cat /dev/null >"$GOLDEN_FILE"
        cat /dev/null >"$OBJ_FILE"
    fi
}


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
        unsigned long: printf("ul %lu (0x%0*lx)\n", _temp_val, (int)(sizeof(long)*2), _temp_val), \\
        long long: printf("ll %lld (0x%016llx)\n", _temp_val, (unsigned long long)_temp_val), \\
        unsigned long long: printf("ull %llu (0x%016llx)\n", _temp_val, _temp_val), \\
        float: printf("f %f\n", (double)_temp_val), \\
        double: printf("d %f\n", _temp_val), \\
        default: printf("unprintable\n") \\
    ); \\
} while(0)

int main() {
__EOF__
}  # print_main


cleanup() {
    term_echo "Goodbye!"
    exit 0
}  # cleanup


#####################
# Main
#####################

# Prevent core files.
ulimit -c 0

GOLDEN_FILE="crepl_golden.c"
OBJ_FILE="crepl_golden.obj"
TEMP_FILE="crepl_temp.c"
ERR_LOG="crepl_errs.log"
EXECUTABLE="./crepl_exe"

# See if standard in is an interactive terminal. We want to be less verbose if input is re-directed.
TERMINAL=0
if [ -t 0 ]; then :
  TERMINAL=1
fi

parse_options "$@"

term_echo "C REPL - Enter C statements or expressions"
term_echo "Type !help for commands"

while true; do :
    term_echo -n "c> "
    # Handle EOF (control-d).
    if ! read -r in_line; then
        in_line="!quit"
    fi

    # Handle empty lines
    if [[ "$in_line" == "" ]]; then
        continue
    fi

    # Handle special commands
    if [[ "$in_line" == !* ]]; then
        if [[ "$in_line" == "!quit" ]]; then
            cleanup
        elif [[ "$in_line" == "!help" ]]; then
            list_help
            continue
        elif [[ "$in_line" == "!errs" ]]; then
            cat "$ERR_LOG"
            continue
        elif [[ "$in_line" == "!obj "* ]]; then
            filename="${in_line#!obj }"
            if [[ -f "$filename" ]]; then
                echo "$filename" >>"$OBJ_FILE"
            else
                echo "File not found: $filename"
            fi
            continue
        elif [[ "$in_line" == "!sh" ]]; then
            sh
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
            in_line=";"  # trigger recompile
        elif [[ "$in_line" == "!source "* ]]; then
            filename="${in_line#!source }"
            if [[ -f "$filename" ]]; then
                ./crepl.sh -c < "$filename"
            else
                echo "File not found: $filename"
            fi
            continue
        else
            echo "Unrecognized command '$in_line'"
            continue
        fi
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
    if gcc -std=gnu11 -o "$EXECUTABLE" $(cat "$OBJ_FILE") "$TEMP_FILE" -lm 2> $ERR_LOG; then
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

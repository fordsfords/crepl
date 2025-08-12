# crepl
Simple C REPL (Read, Eval, Print, Loop) for interactive experimentation
with lines of C code.
This was written primarly to make simple arithmetic experiments easy.


## Table of contents

<!-- mdtoc-start -->
<!-- TOC created by '../mdtoc/mdtoc.pl README.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

This simple interactive C language REPL is written in Bash shell script.
It was written mostly by Claude.ai with a good amount of help from Steve Ford.

It lets you interactively experiment with C code without the overhead of creating,
compiling, and running complete programs.
It's particularly useful for testing arithmetic operations, bit manipulation,
type conversions, and sign extension behavior.

Each line you enter gets wrapped in a minimal C program,
compiled with gcc, and executed immediately.
Lines that compile and run successfully are accumulated in a
"golden file" so you can build up state across multiple inputs.

## Basic Usage

```bash
./crepl.sh
```

This starts a fresh session. Use `-c` to continue a previous session:

```bash
./crepl.sh -c
```

## The Semicolon Rule

The REPL's behavior depends on whether your input ends with a semicolon:

- **Without semicolon**: Treated as an expression, automatically printed.
- **With semicolon**: Treated as a statement, executed but not printed.

Examples:
```
c> 2 + 3
i 5 (0x00000005)

c> int x = 42;

c> x
i 42 (0x0000002a)

c> ++x
i 43 (0x0000002b)
```

This rule exists because C statements like `int x = 42;` aren't expressions and can't be automatically printed. The semicolon tells the REPL whether you want output or not.

If you make a mistake and it doesn't compile, the line is not added to the "golden file".
The goal is for the golden file to always be compilable.

## Auto-Print Format

When expressions are auto-printed, the output shows:
- Type abbreviation (i=int, l=long, f=float, etc.)
- Decimal value
- Hexadecimal value (for integer types)

Supported types: char, unsigned char, short, unsigned short, int, unsigned int, long, unsigned long, long long, unsigned long long, float, double.

## Commands

- `!help` - Show available commands
- `!list` - Show all accumulated code
- `!new` - Clear all accumulated code and start fresh
- `!errs` - Show compilation/runtime errors from last attempt
- `!vi` - Edit accumulated code in vi
- `!quit` - Exit the REPL

## Practical Examples

Testing sign extension:
```
c> char c = -1;
c> c
c -1 (0xff)
c> (int)c
i -1 (0xffffffff)
c> (unsigned char)c
uc 255 (0xff)
```

Bit manipulation:
```
c> int mask = 0x0f;
c> int val = 0x1234;
c> val & mask
i 4 (0x00000004)
c> val >> 4
i 291 (0x00000123)
```

Simple functions (yes, this works):
```
c> int square(int n) { return n * n; };
c> square(7)
i 49 (0x00000031)
```

## Quirks and Limitations

crepl.sh is very limited.
Each line entered must be a fully-compilable fragment of C code.
For example, if you want to define a function, the whole definition must fit
on one line (although there's no particular limit on line length).
Alternatively, you can use the "!vi" command to edit the golden file directly
and enter multi-line constructs.
But that kind of defeats the purpose of a simple REPL, doesn't it? :-)

The semicolon rule can feel awkward.
Sometimes you need a trailing semicolon to suppress auto-print even when it's not syntactically required:

```
c> int add(int a, int b) { return a + b; };
```

The trailing semicolon prevents the REPL from trying to print the function definition.

Variables and functions persist across inputs during a session, but there's no namespace isolation - everything lives in the same scope.

When you exit, the tool leaves its temporary files for you to examine:
* crepl_golden.c - your commands so far.
* crepl_temp.c - the most-recent full C file that was compiled.
If you get a compile error, you can examine the full program.
* crepl_errs.log - Either compile errors or run-time errors.


## Requirements

- gcc with C11 support
- bash
- Standard Unix utilities (vi for the `!vi` command)

The script uses `gcc -std=gnu11` and links with the math library (`-lm`).




## License

I want there to be NO barriers to using this code, so I am releasing it to the public domain.  But "public domain" does not have an internationally agreed upon definition, so I use CC0:

Copyright 2025 Steven Ford http://geeky-boy.com and licensed
"public domain" style under
[CC0](http://creativecommons.org/publicdomain/zero/1.0/):
![CC0](https://licensebuttons.net/p/zero/1.0/88x31.png "CC0")

To the extent possible under law, the contributors to this project have
waived all copyright and related or neighboring rights to this work.
In other words, you can use this code for any purpose without any
restrictions.  This work is published from: United States.  The project home
is https://github.com/fordsfords/crepl

To contact me, Steve Ford, project owner, you can find my email address
at http://geeky-boy.com.  Can't see it?  Keep looking.

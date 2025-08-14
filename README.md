# crepl
Simple C [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)
(Read, Eval, Print, Loop) for interactive experimentation
with lines of C code.
This was written primarily to make simple arithmetic experiments easy.


## Table of contents

<!-- mdtoc-start -->
&bull; [crepl](#crepl)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Table of contents](#table-of-contents)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Basic Usage](#basic-usage)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [The Semicolon Rule](#the-semicolon-rule)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Auto-Print Format](#auto-print-format)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Commands](#commands)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Practical Examples](#practical-examples)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Quirks and Limitations](#quirks-and-limitations)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Multi-line Statements](#multi-line-statements)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Re-Defining Variables and Functions](#re-defining-variables-and-functions)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Awkward Semicolon Use](#awkward-semicolon-use)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Auto-Print of Unsupported Types](#auto-print-of-unsupported-types)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Printf Confusion](#printf-confusion)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Non-Deterministic Functions](#non-deterministic-functions)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Temp Files Persist](#temp-files-persist)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Globals?](#globals)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Requirements](#requirements)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [TODO](#todo)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Rlwrap](#rlwrap)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [License](#license)  
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

Note that crepl.sh is well-suited for use with rlwrap to provide
command-line recall and editing; see [Rlwrap](#rlwrap).


## Basic Usage

```bash
./crepl.sh
```

This starts a fresh session. Use `-c` to continue a previous session:

```bash
./crepl.sh -c
```

WARNING: You probably want to run this tool in an otherwise empty directory
since it creates some files that it intentionally does not clean up.
Also, do not run two instances of the tool in the same directory at the
same time as they will conflict.


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

All commands start with exclamation point ("!").
Any that doesn't start with explanation point is treated as a line of code to
be executed.

- `!help` - Show available commands.
- `!errs` - Show compilation/runtime errors from last attempt. Note that line numbers refer to the 'crepl_temp.c' file.
- `!new` - Clear all accumulated code and start fresh.
- `!list` - Show all accumulated code.
- `!vi` - Edit accumulated code in vi.
- `!source filename` - read input from filename.
- `!sh` - start an interactive sub-shell. Exit shell to return to crepl.
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

### Multi-line Statements

Each line entered must be a fully-compilable fragment of C code.
For example, if you want to define a function, the whole definition must fit
on one line (although there's no particular limit on line length).
Alternatively, you can use the "!vi" command to edit the golden file directly
and enter multi-line constructs.
But that kind of defeats the purpose of a simple REPL, doesn't it? :-)

### Re-Defining Variables and Functions

Consider this session:
```
c> int i = 5000000000;
c> i
i 705032704 (0x2a05f200)
c> long long i = 5000000000;
Compilation error, line rejected. Enter '!errs' for details.
c> !errs
crepl_temp.c: In function ‘main’:
crepl_temp.c:28:9: warning: overflow in conversion from ‘long int’ to ‘int’ changes value from ‘5000000000’ to ‘705032704’ [-Woverflow]
   28 | int i = 5000000000;
      |         ^~~~~~~~~~
crepl_temp.c:30:11: error: conflicting types for ‘i’; have ‘long long int’
   30 | long long i = 5000000000;
      |           ^
crepl_temp.c:28:5: note: previous definition of ‘i’ with type ‘int’
   28 | int i = 5000000000;
      |     ^
```
I chose the wrong type for `i` the first time and the value wasn't right.
I tried to re-define `i`, and it got a compile error.
Since this REPL simply accumulates the lines, C sees it as an attempt to
re-define `i`, and doesn't allow it.

The same thing will happen if you try to re-define a C function.

The solution is to use the "!vi" command and simply edit the golden file
to update the earlier definition.


### Awkward Semicolon Use

The semicolon rule can feel awkward.
Sometimes you need a trailing semicolon to suppress auto-print even when it's not syntactically required:

```
c> int add(int a, int b) { return a + b; };
```

The trailing semicolon prevents the REPL from trying to print the function definition.

Variables and functions persist across inputs during a session, but there's no namespace isolation - everything lives in the same scope.


### Auto-Print of Unsupported Types

The code crepl.sh generates tries to automatically detect the type of an
expression and print it properly.
It currently supports the numeric types (integer and floating).
If you try to auto-print something that isn't supported, you will probably get
a many compile errors all referring to a set of printf calls.

The solution is to not try to auto-print non-numeric expressions.
You can typically just add a semicolon to the end of the line that isn't
a numeric type.

If you want to print something that isn't numeric, like a string or maybe a
pointer address, you'll have to code your own printf.


### Printf Confusion

If you code your own printf calls, you will see unexpected behavior:
```
c> int i = 1;
c> printf("printing i=%d\n", i);
printing i=1
c> printf("done\n");
printing i=1
done
c> ++i
printing i=1
done
i 2 (0x00000002)
```
This looks wrong.
We are used to the value print coming out only once.
But the printf lines are redisplayed with every code line entry.
This is because with each code line entry,
the collected liens of code are compiled and executed.
So of course all the printf calls happen each time.

But also confusing is the fact that after the "++i" line, it displayed
"printing i=1".
But the increment should have set `i` to 2.
But again, remember that all the lines of code are executed in sequence
with each entry.
When the printf is executed, `i` is just 1.

All of this becomes more clear if you use the "!list" command:
```
c> !list
Current code:

int i = 1;
printf("i=%d\n", i);
printf("done\n");
++i;
```
Now you can understand why I got my output when I entered "++i" -
entering that line executed all of the above lines in sequence.


### Non-Deterministic Functions

Most language REPLs are interpreters for the language.
As you enter lines of code, the interpreter evaluates them and saves state
in the interpreter.
I.e. if you say "i = 10", it stores 10 into the variable i and the prompts
for the next line.
When that line executes, say "++i", the variable i still exists,
and it is incremented.

In contrast, crepl.sh does not work that way.
It builds up the lines of code in its "golden file",
and executes all of them with each entry.
I.e. if you say "i = 10", it runs a program that sets the variable i to 10
and exits.
All state is lost.
If you then say "++i", now the program contains both lines.
It compiles that new program that contains both lines and runs them.
Thus, in the second run, both lines are executed, and the result is what you expect.

However, there can be cases where this model breaks down.
Consider the following sequence:
```
c> long t = time();
c> ++t
l 1755119484 (0x00000000689cff7c)
c> ++t
l 1755119489 (0x00000000689cff81)
```
As you can see, the value of t increased by 5, which makes sense since I waited about
4 seconds between the two "++t" lines.
The time() function is non-deterministic - it will return different values when called at
different times.
Each time a new line of code is added, the program is re-run, and "time()" returns a
potentially different value.

This same thing happens for calls to getrandom().

These non-deterministic functions break the illusion that state is saved between lines of
code.
But so long as you are aware of what it really happening, it can still be useful to test
behaviors of non-deterministic functions.
Just know that the "state" will change with each line of code entered.


### Temp Files Persist

When you exit, the tool leaves its temporary files for you to examine:
* crepl_golden.c - your commands so far ("golden file").
* crepl_golden.c.bak - golden file from your previous session.
* crepl_temp.c - the most-recent full C file that was compiled.
If you get a compile error, you can examine the full program.
* crepl_errs.log - Either compile errors or run-time errors.

When crepl.sh is executed normally, the "crepl_golden.c" is deleted
during initialization.
When crepl.sh is executed with "-c", the "crepl_golden.c" is not
deleted, letting you pick up where you left off previously.


### Globals?

It is easy to imagine that the lines of code you enter are somehow in a
global namespace, with variables and functions globally accessible.
However, the reality is that all entered code is wrapped inside the
function "main()", so variables are actually local to main().

So how are we able to define functions?
I.e. how does this even work:
```
c> int add(int a, int b) { return a + b; };
```

While not standard C, the gcc compiler supports nested functions.
So any functions you define are nested in main().
Gcc even uses
[trampolining](https://en.wikipedia.org/wiki/Trampoline_(computing))
so that the nested function can access main()'s local variables.

From the user's point of view, it seems to act as if your variables,
functions, and code lines are global, just like normal C.
However, I suspect there are cases where the behavior differs,
and crepl would act differently than "normal" C code.

If anybody encounters issues related to function nesting, let me know.


## Requirements

- gcc with C11 support
- bash
- Standard Unix utilities (vi for the `!vi` command)

The script uses `gcc -std=gnu11` and links with the math library (`-lm`).


## TODO

1. Have a way that you can specify external modules to be compiled and/or linked
with. I'm thinking of a "!link libnames" for just adding libraries and a
"!use cfiles" command for adding additional .c files.
And maybe a "!include headerfile" to add include directives above main().

2. Add an auto-print of string type.

3. Add '-q' option to suppress initial welcome msg.

4. Is there a way to leverage gdb to print entire complex structures?


## Rlwrap

The Unix rlwrap tool is an interesting oddity that is rarely needed,
but when used can be VERY handy.
It's intended for use with interactive tools that don't implement
advanced command-line editing and command recall.
Most popular interactive tools DO support command-line editing,
so rlwrap isn't needed very often.

But if you've developed your own tools that read from standard in
and perform tasks, you probably didn't go to the trouble of using
[readline()](https://www.man7.org/linux/man-pages/man3/readline.3.html)
so you can't recall older input lines, and your only editing
ability is deleting and re-typing.

The rlwrap command brings all those simple interactive tools into
full "bash-style" command-line editing.

For example:
```
rlwrap ./crepl.sh
```
Now you can enter commands, recall old ones, and edit them just like
bash.

There is a
[bug](https://github.com/hanslub42/rlwrap/issues/108)
in some versions of Linux which cases the prompt to be
cleared when a command is entered.
A workaround is to create a "~/.inputrc" file containing this line:
```
set enable-bracketed-paste off
```
I don't know if this has any undesired side effects elsewhere.

Personally, I like to set "vi" mode for my bash shells (set -o vi).
The only way I've found to change rlwrap to "vi" mode is
by adding this to the "~/.inputrc" file:
```
set editing-mode vi
```
But be aware that this changes the mode for ALL interactive tools
that use Gnu `readline`.
So, for example, gdb will also use that file and switch to "vi" mode.


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

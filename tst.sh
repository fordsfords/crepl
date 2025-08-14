#!/bin/bash

./bld.sh; if [ $? -ne 0 ]; then exit 1; fi

./crepl.sh <<__EOF__ >tst.1.log
123
char c=1;
++c
unsigned char uc=2;
++uc
short s=3;
++s
unsigned short us=4;
++us
int i = 5;
++i
unsigned int ui = 6;
++ui
long l = 7;
++l
unsigned long ul = 8;
++ul
long long ll = 9;
++ll
unsigned long long ull = 10;
++ull
float f = 11.5;
++f
double d = 12.5;
++d
!quit
999
__EOF__

cat <<__EOF__ >ok.1.log
i 123 (0x0000007b)
c 2 (0x02)
uc 3 (0x03)
s 4 (0x0004)
us 5 (0x0005)
i 6 (0x00000006)
ui 7 (0x00000007)
l 8 (0x0000000000000008)
ul 9 (0x0000000000000009)
ll 10 (0x000000000000000a)
ull 11 (0x000000000000000b)
f 12.500000
d 13.500000
__EOF__

if diff tst.1.log ok.1.log >/dev/null; then
  echo tst 1 OK
else
  echo tst 1 FAIL
  exit 1
fi

cat <<__EOF__ >tst.2.x
123
__EOF__
./crepl.sh <<__EOF__ >tst.2.log
11
!source tst.2.x
22
nodef;
!errs
33
!list
44
!new
55
!list
66
__EOF__

cat <<__EOF__ >ok.2.log
i 11 (0x0000000b)
i 123 (0x0000007b)
i 22 (0x00000016)
Compilation error, line rejected. Enter '!errs' for details.
crepl_temp.c: In function ‘main’:
crepl_temp.c:31:1: error: ‘nodef’ undeclared (first use in this function)
   31 | nodef;
      | ^~~~~
crepl_temp.c:31:1: note: each undeclared identifier is reported only once for each function it appears in
i 33 (0x00000021)
Current code:

11;
123;
22;
33;
i 44 (0x0000002c)
Progam cleared
i 55 (0x00000037)
Current code:

55;
i 66 (0x00000042)
__EOF__

if diff tst.2.log ok.2.log >/dev/null; then
  echo tst 2 OK
else
  echo tst 2 FAIL
  exit 1
fi

./crepl.sh -c <<__EOF__ >tst.3.log
11
!list
22
__EOF__

cat <<__EOF__ >ok.3.log
i 11 (0x0000000b)
Current code:

55;
66;
11;
i 22 (0x00000016)
__EOF__

if diff tst.3.log ok.3.log >/dev/null; then
  echo tst 3 OK
else
  echo tst 3 FAIL
  exit 1
fi

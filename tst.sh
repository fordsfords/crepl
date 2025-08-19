#!/bin/bash

./bld.sh; if [ $? -ne 0 ]; then exit 1; fi

rm -f crepl_*
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

if diff tst.1.log test_dir/tst.1.ok >/dev/null; then
  echo tst 1 OK
else
  echo tst 1 FAIL
  exit 1
fi

rm -f crepl_*
./crepl.sh <<__EOF__ >tst.2.log
11
!source test_dir/tst.2.src
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


if diff tst.2.log test_dir/tst.2.ok >/dev/null; then
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

if diff tst.3.log test_dir/tst.3.ok >/dev/null; then
  echo tst 3 OK
else
  echo tst 3 FAIL
  exit 1
fi


cd test_dir
gcc -c -o tst.4.o tst4.c
cd ..

./crepl.sh <<__EOF__ >tst.4.log
#include "test_dir/tst4.h" ;
123
!obj test_dir/tst.4.o
456
add_one(-2)
__EOF__

if diff tst.4.log test_dir/tst.4.ok >/dev/null; then
  echo tst 4 OK
else
  echo tst 4 FAIL
  exit 1
fi

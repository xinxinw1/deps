#!/bin/bash

function deps {
  local s=
  local d=${PWD##*/}   # original directory
  
  cd ../
  while read line; do
    if [ "${line:0:1}" == "#" ]; then continue; fi
    local arr=($line)
    local n=${#arr[@]}
    local cdir; local obj; local todir;
    if [ "$n" == "2" ]; then
      cdir=$d
      obj=${arr[0]}
      todir=${arr[1]}
    elif [ "$n" == "3" ]; then
      cdir=${arr[0]}
      obj=${arr[1]}
      todir=${arr[2]}
    fi
    local file=${obj##*:}
    local addnm=$todir/$file
    local loc=../$d/$addnm
    cd $cdir
    git show $obj > $loc
    s="$s $addnm"
    cd ../
  done < <(cat $d/deps)
  cd $d
  git add $s
  git commit
}

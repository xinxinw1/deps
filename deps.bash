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
    local dest=../$d/$todir
    local loc=$dest/$file
    if [ -d "$cdir" ]; then
      cd $cdir
      if git show $obj 1> /dev/null; then
        if [ ! -d "$dest" ]; then mkdir $dest; fi
        git show $obj > $loc
        s="$s $addnm"
      fi
      cd ../
    else
      echo "Directory $cdir doesn't exist"
    fi
  done < <(cat $d/deps)
  cd $d
  if [ -n "$s" ]; then
    git add $s
    git commit
  fi
}

deps

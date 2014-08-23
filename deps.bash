#!/bin/bash

function deps {
  local s=
  local d="${PWD##*/}"   # original directory
  
  local com=
  local lat=
  local out="../$d"
  while [[ $# > 0 ]]; do
    local key="$1"
    shift
    
    case $key in
      -nc)
        com="true"
        lat="true"
      ;;
      -n|--latest)
        lat="true"
      ;;
      -c|--commit)
        com="true"
      ;;
      -d|--output)
        out="$1"
        shift
      ;;
      *)
        # no args
      ;;
    esac
  done
  
  cd ../
  while read line; do
    if [ "${line:0:1}" == "#" ]; then continue; fi
    local arr=($line)
    local n="${#arr[@]}"
    local cdir; local obj; local todir;
    if [ "$n" == "2" ]; then
      cdir="$d"
      obj="${arr[0]}"
      todir="${arr[1]}"
    elif [ "$n" == "3" ]; then
      cdir="${arr[0]}"
      obj="${arr[1]}"
      todir="${arr[2]}"
    fi
    local file="${obj##*:}"
    local bran="${obj%%:*}"
    local addnm="$todir/$file"
    local dest="$out/$todir"
    local loc="$dest/$file"
    if [ -d "$cdir" ]; then
      cd "$cdir"
      if [ "$lat" != "true" ] || [ ! -f $file ]; then
        if git show "$obj" 1>/dev/null 2>/dev/null; then
          if [ ! -d "$dest" ]; then mkdir -p "$dest"; fi
          git show "$obj" > $loc
          local modestr="$(git ls-tree "$bran" -- "$file")"
          local modearr=($modestr)
          local mode="${modearr[0]:3:3}"
          chmod "$mode" "$loc"
          s="$s $addnm"
        fi
      else
        if [ -f $file ]; then
          if [ ! -d "$dest" ]; then mkdir -p "$dest"; fi
          cp --preserve=mode "$file" "$dest"
          s="$s $addnm"
        fi
      fi
      cd ../
    else
      echo "Directory $cdir doesn't exist"
    fi
  done < <(cat "$d/deps" 2>/dev/null)
  cd "$d"
  if [ "$com" == "true" ] && [ -n "$s" ]; then
    # no quotes around $s so that it expands
    git add $s
    git commit
  fi
}

deps "$@"

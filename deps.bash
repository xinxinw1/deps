#!/bin/bash

function deps {
  local s=
  local d="${PWD##*/}"   # original directory
  
  local com=
  local lat=
  local out="$(realpath -m .)"
  # http://stackoverflow.com/questions/284662/how-do-you-normalize-a-file-path-in-bash
  local depsfile="$(realpath -m deps)"
  local debug=
  while [[ $# > 0 ]]; do
    local key="$1"
    shift
    
    case $key in
      -lc|-cl)
        com="true"
        lat="true"
      ;;
      -ld|-dl)
        lat="true"
        debug="true"
      ;;
      -cd|-dc)
        com="true"
        debug="true"
      ;;
      -lcd|-ldc|-dlc|-dcl|-cld|-cdl)
        com="true"
        lat="true"
        debug="true"
      ;;
      -l|--latest)
        lat="true"
      ;;
      -c|--commit)
        com="true"
      ;;
      -o|--output)
        if [ -z "$1" ]; then
          echo "Warning: empty output param; sending to /dev/null" 1>&2
          out="/dev/null"
        else
          out="$(realpath -m "$1")"
        fi
        shift
      ;;
      -f|--depsfile)
        if [ -z "$1" ]; then
          echo "Warning: empty deps param; treating as empty deps file" 1>&2
          depsfile="/dev/null"
        else
          depsfile="$(realpath -m "$1")"
          if [ ! -f "$depsfile" ]; then
            echo "Warning: no such file $depsfile"
          fi
        fi
        shift
      ;;
      -d|--debug)
        debug="true"
      ;;
      -*)
        echo "Warning: unknown option $key" 1>&2
      ;;
      *)
        # no args
      ;;
    esac
  done
  if [ "$debug" == "true" ]; then
    echo "Depsfile is $depsfile"
    echo "Output is $out"
  fi
  
  
  cd ../
  while read line; do
    [ "${line:0:1}" == "#" ] && continue
    local arr=($line)
    local n="${#arr[@]}"
    [ "$n" == "0" ] && continue
    #[ "$debug" == "true" ] && echo "$line"
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
    [ "$lat" == "true" ] && obj="$file"
    local bran="${obj%%:*}"
    [ "$obj" == "$file" ] && bran=""
    local addnm="$todir/$file"
    local dest="$(realpath -m "$out/$todir")"
    [ "$out" == "/dev/null" ] && dest="/dev/null"
    local loc="$dest/$file"
    [ "$debug" == "true" ] && echo "$cdir $obj $todir"
    if [ -d "$cdir" ]; then
      cd "$cdir"
      
      if [ "$bran" == "" ]; then
        if [ -f $file ]; then
          if [ "$out" != "/dev/null" ]; then
            [ ! -d "$dest" ] && mkdir -p "$dest"
            cp --preserve=mode "$file" "$dest"
          fi
          s="$s $addnm"
        else
          echo "Warning: $obj not found in $cdir" 1>&2
        fi
      else
        # http://stackoverflow.com/questions/2180270/check-if-current-directory-is-a-git-repository
        local gitdir=""
        git rev-parse --git-dir >/dev/null 2>&1 && gitdir="true"
        
        local hasobj=""
        git show "$obj" >/dev/null 2>&1 && hasobj="true"
        
        if [ "$gitdir" == "true" ]; then
          if [ "$hasobj" == "true" ]; then
            if [ "$out" != "/dev/null" ]; then
              [ ! -d "$dest" ] && mkdir -p "$dest"
              git show "$obj" > $loc
              local modestr="$(git ls-tree "$bran" -- "$file")"
              local modearr=($modestr)
              local mode="${modearr[0]:3:3}"
              chmod "$mode" "$loc"
            fi
            s="$s $addnm"
          else
            echo "Warning: $obj not found in $cdir" 1>&2
          fi
        else
          echo "Warning: requested git obj $obj in non-git dir $cdir" 1>&2
        fi
      fi
      
      cd ../
    else
      echo "Warning: directory $cdir doesn't exist" 1>&2
    fi
  done < <(cat "$depsfile" 2>/dev/null)
  cd "$d"
  if [ "$com" == "true" ]; then
    if [ -n "$s" ]; then
      # no quotes around $s so that it expands
      git add $s
      git commit
    else
      echo "Warning: nothing to commit" 1>&2
    fi
  fi
}

deps "$@"

#!/bin/bash

function deps {
  local s=()
  local d="${PWD##*/}"   # original directory
  
  local com=
  local lat=
  local out="$(realpath -m .)"
  # http://stackoverflow.com/questions/284662/how-do-you-normalize-a-file-path-in-bash
  local depsfile="$(realpath -m deps)"
  local nomet=
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
      -n|--no-meta)
        nomet="true"
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
    echo ""
  fi
  
  if [ -f "$out/depsinfo.new" ]; then
    while true; do
      read -p "Fille $out/depsinfo.new exists? Delete and replace it? [Yn] " yn
      case $yn in
        [Yy]* | "")
          rm "$out/depsinfo.new"
          break
        ;;
        [Nn]*)
          exit
        ;;
        *)
          echo "Unknown answer."
        ;;
      esac
    done
  fi
  
  if [ -z "$nomet" ]; then
    echo "$(date)" >> "$out/depsinfo.new"
    echo "Depsfile is $depsfile" >> "$out/depsinfo.new"
    echo "Output is $out" >> "$out/depsinfo.new"
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
    local filenm="${file##*/}"
    local addnm="$todir/$filenm"
    local dest="$(realpath -m "$out/$todir")"
    [ "$out" == "/dev/null" ] && dest="/dev/null"
    local loc="$dest/$filenm"
    [ "$debug" == "true" ] && echo "$cdir $obj $todir --> $addnm"
    [ -z "$nomet" ] && echo "$cdir $obj $todir --> $addnm" >> "$out/depsinfo.new"
    if [ -d "$cdir" ]; then
      cd "$cdir"
      
      if [ "$bran" == "" ]; then
        if [ -f $file ]; then
          if [ "$out" != "/dev/null" ]; then
            [ ! -d "$dest" ] && mkdir -p "$dest"
            cp --preserve=mode "$file" "$dest"
          fi
          s+=("$addnm")
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
            s+=("$addnm")
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
  
  if git rev-parse --git-dir >/dev/null 2>&1; then
    if [ "${#s[@]}" != "0" ]; then
      s=($(awk '{ print $2 }' <(git status --porcelain "${s[@]}")))
    fi
  fi
    
  if [ "$debug" == "true" ]; then
    echo ""
    if [ "${#s[@]}" != "0" ]; then
      echo "Updated Files:"
      printf -- '%s\n' "${s[@]}"
    else
      echo "No files updated"
    fi
  fi
  
  if [ -z "$nomet" ]; then
    local hea="$(head -n3 "$out/depsinfo.new")"
    local tai="$(tail -n+4 "$out/depsinfo.new" | column -t)"
    
    echo "$hea" > "$out/depsinfo.new"
    echo "" >> "$out/depsinfo.new"
    echo "$tai" >> "$out/depsinfo.new"
    echo "" >> "$out/depsinfo.new"
    
    if [ "${#s[@]}" != "0" ]; then
      echo "Updated Files:" >> "$out/depsinfo.new"
      printf -- '%s\n' "${s[@]}" >> "$out/depsinfo.new"
      mv "$out/depsinfo.new" "$out/depsinfo"
    else
      echo "No files updated" >> "$out/depsinfo.new"
      rm "$out/depsinfo.new"
    fi
  fi
  
  if [ "$com" == "true" ]; then
    if git rev-parse --git-dir >/dev/null 2>&1; then
      if [ "${#s[@]}" != "0" ]; then
        # no quotes around $s so that it expands
        git add depsinfo ${s[@]}
        git commit -m "update deps"
      else
        echo "Warning: nothing to commit" 1>&2
      fi
    else
      echo "Warning: can't commit in a non-git dir"
    fi
  fi
}

deps "$@"

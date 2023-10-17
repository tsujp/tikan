#!/usr/bin/env bash

shopt -s lastpipe

declare -r datetime="$(date +%s)"

declare -r silence_char='-'

# Single character marker to start regex match of data from.
# An end user has the option to directly append a $silence_char which will stop
#   printing the original converted-from value. So, `u` is specified for
#   conversion to an unsigned integer and if a user supplies `u-` the
#   conversion will occur with the original value (e.g. hex) not printed after.
declare -r k_pfx='prefix'

# Whitespace delimited list of two-tuples (elements separated by semicolon)
#   where in each tuple:
#     - First element is the format specifier to pass to `printf`.
#     - Second element is character(s) to prefix (shim) in-front of data to
#       be printed.
# Multiple tuples = multiple conversions made.
# If no conversion is defined it will default to tuple '%s;0x' which effectively
#   does no conversion and adds back the removed 0x prefix (which is used
#   alongside `k_pfx` to help find data to convert).
declare -r k_cnv_default='%s;0x'
declare -r k_cnv='conversions'

# Hack to run arbitrary logic if a prefix is matched. If this is present in a
#   conversion definition it will run _after_ `k_cnv`. It should be set to
#   the name of a function to invoke. The function will receive as $1 the _name_
#   of the variable containing a space delimited string of conversions made
#   to the original value as well as the original value with the leading 0x
#   stripped (if $silence_char was not set). Use `declare -n foo="$1"` to access
#   the conversion varible. As it is a nameref it mutates the original e.g. for
#   preventing output in the case of the `_bitfield` conversion type. It also
#   receives $2 as the inclusive count of invocations of the hook for the
#   current line being processed; so if the hook is called three times $2 will
#   be 1 on the first invocation, 2 on the second, 3 on the third and if it is
#   then called with with $2 as 1 again it knows this is a new line of
#   conversions being made.
declare -r k_run='effect'

declare -Ar _unsigned=(
  ["$k_pfx"]='u'
  ["$k_cnv"]='%u;0x'
)

declare -Ar _char=(
  ["$k_pfx"]='c'
  ["$k_cnv"]='%b;\x %u;0x'
)

# Prefix `k` suitably un-overloaded. Could do this with awk but stdout is
#   already being fully examined by this (bash) script anyway and the goal
#   is to create some files so it's simpler this way.
declare -Ar _bitfield=(
  ["$k_pfx"]='k'
  ["$k_run"]='bitfield_frontend_debug'
)


write_bitfield_data ()
{
  # TODO: Relative to the current _script_ location.
  mkdir -p test_data
  printf '%s\n' "$1" >> "test_data/${datetime}.data"
}


bitfield_frontend_debug ()
{
  # Shellcheck intentionally does not consider indirect references as used.
  # shellcheck disable=SC2034
  declare -n conv="$1"

  # printf 'received: >%s< >%s<\n' "$conv" "$2"

  # Start of a new line of conversions.
  if (( $2 == 1 )); then
    unset test_tag
    declare test_tag="${conv#0x}"
    # printf '\n' >> "$test_{datetime}.data"# Blank line delimits each board in our simple format.
    # printf '%s\n' "$test_tag"
    write_bitfield_data
    write_bitfield_data "$test_tag"
    # printf '%s\n' "$test_tag"
    # printf -v foo_bar '{"%s": [{\n' "$test_tag"
  else
    write_bitfield_data "$conv"
    # printf '%s\n' "$conv"
  fi
 
  # Effectively swallows input by unsetting it (the referenced variable).
  unset conv
}


declare -ar convs=(
  '_unsigned'
  '_char'
  '_bitfield'
)


# Mapfile callback function is eval'd (I believe) so it's context is the same
#   as invoking `mapfile`s call-site; effectively a closure.
shim_data ()
{
  declare -i idx="$1"
  declare val="$2"

  # The data is prefixed (shimmed to disambiguate "prefix" term use) with
  #   characters required for printf to do neccersary conversions, for example
  #   the format specifier `%u` requires an input hex number, say `10` (which
  #   in decimal is 16), to be prefixed with `0x` so `0x10` whereas to print the
  #   ASCII character for a hex number no format specifier is required however
  #   the hex number must be in literal form, so `\x50` for character `P`.
  data_shim_pad[idx]="${cnv_shims[$idx]}${val}"
}

format_line ()
{
  declare -I ln

  # For each conversion prefix we have...
  for pfx_ptr in "${convs[@]}"; do  
    declare -n pfx="$pfx_ptr"

    # Remove all space characters from conversion list (delimited by spaces).
    declare cnv_stripped="${pfx[$k_cnv]// }"

    declare pad
    declare -a cnv_list
    declare -i ln_cnv_count=0

    if (( "${#cnv_stripped}" == 0 )); then
      cnv_list=("$k_cnv_default")
      pad='0'
    else
      # Take advantage of `printf`s zero-padding and precision specification to
      #   construct a string of N zeroes where N is the number of spaces in
      #   the conversion list plus 1. The +1 comes from adding a literal `0` at
      #   the end of the format specifier.
      # shellcheck disable=SC2183
      printf -v pad '%0*s0' "$(((${#pfx[$k_cnv]} - ${#cnv_stripped}) / 1))"
      
      printf '%s' "${pfx[$k_cnv]}" | mapfile -d ' ' -t  cnv_list
    fi
    
    declare -a cnv_shims=("${cnv_list[@]##*;}")
    declare -a cnv_fmts=("${cnv_list[@]%%;*}")

    # ...do convs for the current line match by match.
    while [[ "$ln" =~ "${pfx[$k_pfx]}"("$silence_char"?)0x([[:xdigit:]]+) ]]; do
      ((ln_cnv_count++))
      declare full_match="${BASH_REMATCH[0]}"
      declare orig_data="${BASH_REMATCH[2]}"

      if [[ "${BASH_REMATCH[1]}" =~ ^"$silence_char" ]]; then
        declare should_silence='true' # String, not a boolean.
      fi

      # Using parameterised format specifiers so to ensure all conversions are
      #   made (i.e. all format specifiers "filled"). The data to be formatted
      #   must occur at least as many times as there are format specifiers to
      #   "fill" them.
      # The data to format is also prefixed (in a mapfile callback function).
      declare -a data_shim_pad=()
      printf '%s' "${pad//0/$orig_data }" | mapfile -d ' ' -t -c 1 -C 'shim_data'
      unset MAPFILE # Very pedantic.

      if [[ ! "$should_silence" == 'true' ]]; then
        data_shim_pad+=("$orig_data")
      fi

      # Conversion logic, hard-coded grey colouring for original output value.
      declare converted=''
      printf -v converted "${cnv_fmts[*]} %s" "${data_shim_pad[@]}"
      converted="${converted/% /}" # Trim trailing space.

      # Call side-effect if it's a valid function name.
      if [[ $(declare -F "${pfx[$k_run]}") ]]; then
        "${pfx[$k_run]}" 'converted' "$ln_cnv_count"
       fi

      # Add hard-coded grey coloured original value, with removed prefix and
      #   literal `0x`.
      converted="${converted/% $orig_data/$'\033[38;5;243m'&$'\033[0m'}"
    
      # Replace original value in line with converted value(s).
      ln="${ln/$full_match/$converted}"
      ln="${ln/# /}" # Trim leading whitespace if any.
    done
  done

  # printf '>%Q<' "$ln"

  # printf 'len: %s <>' "${#ln}"
  # ln="${ln/#[[:blank:]]/[&]}"
  # ln="${ln/#[[:blank:]]/}"
  # printf 'len: %s <>' "${#ln}"

  if (( ${#ln} > 0 )); then
    printf '%s\n' "$ln"
  fi
}


# Nargo outputs its own test running information to `stderr`, and function
#   `println` to stdout. Merge these to keep ordering of output the same since
#   the processing we're doing takes at least some time and will mess up the
#   output order without this.
printf 'RUN_ID: %s\n' "$datetime"
nargo test --workspace --show-output 2>&1 |
  while IFS= read -r ln; do
    format_line
  done

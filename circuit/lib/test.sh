#!/usr/bin/env bash

shopt -s lastpipe

# Single character marker to start regex match of data from.
declare -r k_pfx='prefix'

# Whitespace delimited list of two-tuples (elements separated by semicolon)
#   where in each tuple:
#     - First element is the format specifier to pass to `printf`.
#     - Second element is character(s) to prefix (shim) in-front of data to
#       be printed.
# Multiple tuples = multiple conversions made.
declare -r k_cnv='conversions'

declare -Ar _unsigned=(
  ["$k_pfx"]='u'
  ["$k_cnv"]='%u;0x'
)

declare -Ar _char=(
  ["$k_pfx"]='c'
  ["$k_cnv"]='%b;\x %u;0x'
)

declare -ar convs=(
  '_unsigned'
  '_char'
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

    # Take advantage of `printf`s zero-padding and precision specification to
    #   construct a string of N zeroes where N is the number of spaces in
    #   the conversion list plus 1. The +1 comes from adding a literal `0` at
    #   the end of the format specifier.
    # shellcheck disable=SC2183
    printf -v pad '%0*s0' "$(((${#pfx[$k_cnv]} - ${#cnv_stripped}) / 1))"

    # ...do convs for the current line match by match.
    while [[ "$ln" =~ "${pfx[$k_pfx]}"0x([[:xdigit:]]+) ]]; do
      declare full_match="${BASH_REMATCH[0]}"
      declare orig_data="${BASH_REMATCH[1]}"

      # Cannot subscript array already accessed by parameterisation and perform
      #   replacing parameter expansion in one (apparent) operation (line).
      declare -a cnv_list
      printf '%s' "${pfx[$k_cnv]}" | mapfile -d ' ' -t  cnv_list
      declare -a cnv_shims=("${cnv_list[@]##*;}")
      declare -a cnv_fmts=("${cnv_list[@]%%;*}")
    
      # Using parameterised format specifiers so to ensure all conversions are
      #   made (i.e. all format specifiers "filled"). The data to be formatted
      #   must occur at least as many times as there are format specifiers to
      #   "fill" them.
      # The data to format is also prefixed (in a mapfile callback function).
      declare -a data_shim_pad=()
      printf '%s' "${pad//0/$orig_data }" | mapfile -d ' ' -t -c 1 -C 'shim_data'
      unset MAPFILE # Very pedantic.
      data_shim_pad+=("${full_match/#?0x/}") # Remove prefix and literal `0x`.

      # Conversion logic, hard-coded grey colouring for original output value.
      declare converted=''
      printf -v converted "${cnv_fmts[*]} \033[38;5;243m%s\033[0m" "${data_shim_pad[@]}"

      # Replace original value in line with converted value(s).
      ln="${ln/$full_match/$converted}"
    done
  done

  printf '%s\n' "$ln"
}

# Nargo outputs its own test running information to `stderr`, and function
#   `println` to stdout. Merge these to keep ordering of output the same since
#   the processing we're doing takes at least some time and will mess up the
#   output order without this.
nargo test --workspace --show-output 2>&1 |
  while IFS= read -r ln; do
    format_line
  done

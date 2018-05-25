#!/usr/bin/env bash

#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${scriptName} [-hV] [-dqlv] args ...
#%
#% DESCRIPTION
#%    This is a script template
#%    to start any good shell script.
#%
#% OPTIONS
#%    -d, --debug                   Runs script in BASH debug mode (set -x)
#%    -n, --noexec                  Runs script in BASH noexec mode (set -n)
#%    -q, --quiet                   Quiet (no output)
#%    -l, --log                     Print log to file
#%    -v, --verbose                 Output more information. (Items echoed to 'verbose')
#%    -h, --help                    Print this help
#%    -V, --version                 Print script information
#%
#% EXAMPLES
#%    ${scriptName} -l
#%
#================================================================
#- IMPLEMENTATION
#-    version         ${scriptName} 0.0.1
#-    author          Vinícius LEITE (http://www.viniciusleite.com)
#-    based on        Michel VONGVILAY (https://www.uxora.com)
#-                    Nathaniel LANDAU (https://natelandau.com)
#-    license         GNU GENERAL PUBLIC V3
#-    script_id       0
#-
#================================================================
#  HISTORY
#     2018/05/21 : vleite : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================


#============================
#  FILES AND VARIABLES
#============================

  # Basic variables
  # -----------------------------------
  # Variables with name of script and header info
  # Don't need any change.
  # -----------------------------------
    scriptName="$(basename "${0}")" # scriptname without path
    scriptDir="$( cd "$(dirname "${0}")" && pwd )" # script directory
    scriptFullPath="${scriptDir}/${scriptName}"
    scriptHeadSize=$(head -200 "${0}" |grep -n "^# END_OF_HEADER" | cut -f1 -d:)

  # Set Flags
  # -----------------------------------
  # Flags which can be overridden by user input.
  # Default values are below
  # -----------------------------------
    quiet='false'
    printLog='false'
    verbose='false'
    debug='false'
    noExec='false'

  # Logging
  # -----------------------------------
  # Log is only used when the '-l' flag is set.
  # To never save a logfile change variable to '/dev/null'
  # -----------------------------------
    logFile="$scriptDir/${scriptName}.log"

  # Set Colors
  # -----------------------------------
  # Define color to be used in output messages.
  # If you want to include a new one, declare here.
  # -----------------------------------
    bold=$(tput bold)
    underline=$(tput sgr 0 1)
    purple=$(tput setaf 171)
    red=$(tput setaf 1)
    green=$(tput setaf 76)
    blue=$(tput setaf 38)
    yellow=$(tput setaf 3)
    reset=$(tput sgr0)

############## End Variables ###################


#============================
#  ALIAS AND FUNCTIONS
#============================

  # usage functions
  # -----------------------------------
  # functions that show the usage when the parameter is -h or
  # when some error with parameter is generated.
  # -----------------------------------
  usage() { printf "Usage: "; scriptInfo usg ; }
  usageFull() { scriptInfo ful ; }
  scriptInfo() { headFilter="^#-"
    test "$1" = "usg" && headFilter="^#+"
    test "$1" = "ful" && headFilter="^#[%+]"
    test "$1" = "ver" && headFilter="^#-"
    head -"${scriptHeadSize:-99}" "${0}" | grep -e "${headFilter}" | sed -e "s/${headFilter}//g" -e "s/\${scriptName}/${scriptName}/g";
  }

  # trapCleanup Function
  # -----------------------------------
  # Any actions that should be taken if the script is prematurely
  # exited.  Always call this function at the top of your script.
  # -----------------------------------
    trapCleanup() {
      echo ""
      # Delete temp files, if any
      if [ -e "${tmpDir}" ]; then
        rm -r "${tmpDir}"
      fi
      die "Exit trapped. In function: '${FUNCNAME[*]}'"
    }

  # safeExit
  # -----------------------------------
  # Non destructive exit for when script exits naturally.
  # Usage: Add this function at the end of every script.
  # -----------------------------------
    safeExit() {
      # Delete temp files, if any
      if [ -e "${tmpDir}" ]; then
        rm -r "${tmpDir}"
      fi
      trap - INT TERM EXIT
      exit
    }

  # Set Temp Directory
  # -----------------------------------
  # Create temp directory with three random numbers and the process ID
  # in the name.  This directory is removed automatically at exit.
  # -----------------------------------
    tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
    (umask 077 && mkdir "${tmpDir}") || {
      die "Could not create temporary directory! Exiting."
    }

  # Define type of messages
  # -----------------------------------
  # Functions to create and define the colors and also the output
  # of each type of message.
  # Usage:
  #     sucess "Backup was completed successfully."
  # -----------------------------------
    _alert() {
      if [ "${1}" = "emergency" ]; then local color="${bold}${red}"; fi
      if [ "${1}" = "error" ]; then local color="${red}"; fi
      if [ "${1}" = "warning" ]; then local color="${yellow}"; fi
      if [ "${1}" = "success" ]; then local color="${green}"; fi
      if [ "${1}" = "debug" ]; then local color="${purple}"; fi
      if [ "${1}" = "header" ]; then local color="${bold}""${yellow}"; fi
      if [ "${1}" = "input" ]; then local color="${bold}"; printLog="false"; fi
      if [ "${1}" = "info" ] || [ "${1}" = "notice" ]; then local color=""; fi
      # Don't use colors on pipes or non-recognized terminals
      if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then color=""; reset=""; fi

      # Print to $logFile
      if [[ ${printLog} = "true" ]] || [ "${printLog}" == "1" ]; then
        echo -e "$(date +"%m-%d-%Y %r") $(printf "[%9s]" "${1}") ${_message}" >> "${logFile}";
      fi

      # Print to console when script is not 'quiet'
      if [[ "${quiet}" = "true" ]] || [ "${quiet}" == "1" ]; then
       return
      else
       echo -e "$(date +"%r") ${color}$(printf "[%9s]" "${1}") ${_message}${reset}";
      fi

    }

    verbose() {
      if [[ "${verbose}" = "true" ]] || [ "${verbose}" == "1" ]; then
        debug "${@}"
      else
        "${@}"
      fi
    }

    die ()       { local _message="${*} Exiting."; "$(_alert error)"; safeExit;}
    error ()     { local _message="${*}"; "$(_alert error)"; }
    warning ()   { local _message="${*}"; "$(_alert warning)"; }
    notice ()    { local _message="${*}"; "$(_alert notice)"; }
    info ()      { local _message="${*}"; "$(_alert info)"; }
    debug ()     { local _message="${*}"; "$(_alert debug)"; }
    success ()   { local _message="${*}"; "$(_alert success)"; }
    input()      { local _message="${*}"; echo -n "$(_alert input)"; }
    header()     { local _message="========== ${*} ==========  "; "$(_alert header)"; }

  # mainScript
  # -----------------------------------
  # Begin your script here.
  #
  # -----------------------------------
    mainScript() {

      echo -e "===== BEGIN YOUR SCRIPT! ====="

    }

############## End Functions ###################


#============================
#  OPTIONS
#============================
  while test -n "$1"
  do
    case "$1" in
      -h|--help) usageFull >&2; safeExit ;;
      -V|--version) scriptInfo >&2; safeExit ;;
      -v|--verbose) verbose=true ;;
      -l|--log) printLog=true ;;
      -q|--quiet) quiet=true ;;
      -d|--debug) debug=true;;
      -n|--noexec) noExec=true;;
      *) die "invalid option: '$1'." ;;
    esac
    shift
  done

############## End Options ###################


# ############# ############# #############
# ##       TIME TO RUN THE SCRIPT        ##
# ##                                     ##
# ## You shouldn't need to edit anything ##
# ## beneath this line                   ##
# ##                                     ##
# ############# ############# #############

# Trap bad exits with your cleanup function
trap trapCleanup EXIT INT TERM

# Exit on error. Append '||true' when you run the script if you expect an error.
set -o errexit

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Run in noexec mode, if set
if ${noExec}; then set -n ; fi

# Bash will remember & return the highest exitcode in a chain of pipes.
# This way you can catch the error in case mysqldump fails in `mysqldump |gzip`, for example.
set -o pipefail

# Run your script
if ${quiet}; then
  mainScript > /dev/null
else
  mainScript
fi

# Exit cleanlyd
safeExit

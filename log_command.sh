# LogCommand

# Description:
#    LogCommand is a light terminal script to run a command, output its stdout & stderr, and the command's exit code.
#    It is especially useful for commands that do not output to the terminal where logging and auditablity is necessary.
#    This script was made to be used in conjunction with https://github.com/FMallon/LogAppend or tee.  It can also be used be used without these.

# Author: 
#    F Mallon
# ------------------------------------------------------------------------------------------------------------------------- #


# Return Codes

# Return 1 - Error: Command not found on the System - Internal facing, will not be directed to the User
# Return 2 - Error: Invalid number of args
# Return 3 - Error: Function dry_run() failed
# Return 4 - Error: Function usage() failed
# Return 5 - Error: Function run_command_safe() failed
# Return 6 - Error: Function run_command_unsafe() failed
# Return 7 - Error: Invalid arg




verify_command_exists(){

## Leave this out and leave it to User Error - it fixes output, but what if aliases etc are used?
# see how to handle aliases maybe - maybe type -a?
# actually due to array composition, aliases do not work anyways, so maybe

    if [[ -n "$ZSH_VERSION" ]]; then
    
        local index_specifier=1

    else

        local index_specifier=0

    fi


   if ! command -v "${COMMAND[$index_specifier]}" &>/dev/null; then

        \printf "\n[ERROR] The command \"%s\" does not appear to be available on this system\n\n" "${COMMAND[$index_specifier]}"
        return 1

    fi

    return 0


}


dry_run(){


    verify_command_exists || return $?

    
    local i=0

    \printf "\n[COMMAND] %s\n\n" "${COMMAND[*]}"

    for arg in "${COMMAND[@]}"; do

        \printf "\n[ARG %d] %q\n" "$i" "$arg"

        (( i++ ))

    done

    \printf "\n"

    return 0

}


run_command_unsafe(){

    
    # So basically, a way to not break existing workflow - and will allow for more complex piping, or ; & && || etc. 
    #local current_shell="$(ps -p $$ -o comm=)" - this could break, think about it;

    # This is a difficult one, so maybe just default to their Login Shell, most people aren't logging in to sh, then running Bash... 
    local current_shell="${SHELL:-/bin/sh}"


    # So basically 'bash -c', 'sh -c', 'zsh -c'
    local run_shell_args=("$current_shell" "-c")
    local command_converted_to_str="${COMMAND[@]}"


    \printf "\n[COMMAND] %s\n" "$command_converted_to_str"
    \printf "\n[COMMAND OUTPUT]\n"

    # Run the command, capture exit status
    "${run_shell_args[@]}" "$command_converted_to_str" 2>&1
    local command_exit_status=$?
    
    if (( command_exit_status == 0 )); then

        \printf "\n[COMMAND SUCCESS] The command exited with Exit Code: %d\n" "$command_exit_status"

    else 

        \printf "\n[COMMAND FAILED] The command exited with Exit Code: %d\n" "$command_exit_status"

    fi

    return 0


}


run_command_safe(){



    verify_command_exists || return $?


    \printf "\n[COMMAND] %s\n" "${COMMAND[*]}" 
    \printf "\n[COMMAND OUTPUT]\n"

    # Run the command, capture exit status
    "${COMMAND[@]}" 2>&1
    local command_exit_status=$?

    if (( command_exit_status == 0 )); then

        \printf "\n[COMMAND SUCCESS] The command exited with Exit Code: %d\n" "$command_exit_status"

    else 

        \printf "\n[COMMAND FAILED] The command exited with Exit Code: %d\n" "$command_exit_status"

    fi

    return 0


}


usage(){


    \printf "

    LogCommand is a light terminal script to run commands, output its stdout & stderr, and the command's exit code.
    It is especially useful for commands that do not output to the terminal where logging and auditability is necessary.
    This script was made to be used in conjunction with https://github.com/FMallon/LogAppend or tee.  It can also be used be used without these.
    
    
    [ -- ] <Command> Runs the args as a command

        Usage:

            -> logcom -- echo \"hello world\"

            This will run the command 'echo' with \"hello world\"



    [ --dry-run ] <Command> Prints the Command to the terminal but doesn't run it

        Usage:

            -> logcom --dry-run echo \"hello world\"
    
        [NOTE]

            This mode prints the command on an argument-by-argument basis.
            It is intended for debugging and verifying how the argument is parsed in the event of error or unsurity.

            Useful when commands fail due to incorrect argument splitting or quoting issues.

            For example:

                -> logcom --dry-run echo hello world 

                This will pass 3 args - this will still work due to the nature of echo;
                

                -> logcom --dry-run echo \"hello world\" 

                This will pass 2 args - this would be the correct use of echo, but you can see that by using quotes, the arg isn't being separated into 3 args

            Furthermore, if you run:

                -> logcom --dry-run ls | grep file.txt

                This will only display \"[ARG 0] ls\".

                This is because the pipe ('|') is handled by your shell before
                LogCommand receives the command. In this example, grep is receiving
                LogCommand's stdout and is not part of the command being inspected.

                Therefore, LogCommand only handles the command and arguments directly
                passed to it. Shell-specific operators such as:

                    |   &&   ;   >   >>

                are not interpreted.  They are interpreted by the calling shell before LogCommand receives the arguments.

                This is intentional, as LogCommand avoids using eval and executes
                commands using safe argument-based execution instead.


            If we run:

                -> logcom -- \"echo hello world\"

                This will fail because the whole command is passed as a single string.
                This will result in failure because logcom does not use eval, but opts for a safer array composition to run the specified command.


    
    [ -c ] "\<string\>" Runs the String as a Command, allowing for the usage of Shell-specific operators such as:

            |   &&   ;   >   >>

        Usage:

            -> logcom -c 'echo \"hello world\" | grep \"hello\"'



    [ -h | --help ] Prints the Usage to the terminal

        Usage:

            -> logcom -h

    
    Return Codes:

        Return 2 - Error: Invalid number of args
        Return 3 - Error: Function dry_run() failed
        Return 4 - Error: Function usage() failed
        Return 5 - Error: Function run_command_safe() failed
        Return 6 - Error: Function run_command_unsafe() failed
        Return 7 - Error: Invalid arg


    "
        

}


log_command_main(){



    case "$1" in


        --dry-run)

            shift

            if (( $# == 0 )); then

                \printf "\n[ERROR] Args cannot be empty!\n\n"
                return 2

            fi

            COMMAND=("${@}")
            dry_run || return 3

        ;;

        --help | -h)

            shift 

            if (( $# != 0 )); then

                \printf "\n[ERROR] --help take no args\n\n"
                return 2

            fi

            usage || return 4

        ;;

        
        -c)

            shift

            if (( $# != 1 )); then

                \printf "\n[ERROR] Only accepts one String arg!\n\n"
                return 2

            fi

            
            COMMAND=("${@}")
            run_command_unsafe || return 6

        ;;


        --) 

            shift

            if (( $# == 0 )); then

                \printf "\n[ERROR] Args cannot be empty!\n\n"
                return 2

            fi

            COMMAND=("${@}")
            run_command_safe || return 5

        ;;

        *)

            \printf "\n[ERROR] Invalid arg!\n\n"
            return 7

        ;;

    esac

}

log_command_main "$@"

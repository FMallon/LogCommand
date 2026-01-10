#!/bin/bash



COMMAND=$1


function execute_command(){


  eval $COMMAND 2>&1

  exit_status=$?

}

function echo_command(){


  if [[ $exit_status -eq 0 ]]; then 

    echo "### $COMMAND suceeded with Exit Code: $exit_status ###"

  else
    
    echo "### $COMMAND failed with Exit Code: $exit_status ###"

  fi




}

function clear_space(){


  echo ""


}


function main_log_command(){


  execute_command

  echo_command

}

main_log_command $@

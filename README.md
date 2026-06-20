<div align="center">

# LogCommand
LogCommand is a light terminal script to run commands, capture its stdout and stderr, and display the command's exit code, formatting it in a nicer output for the use of logging.
It is especially useful for commands that do not output to the terminal where logging and auditability is necessary.

</div>

---

## Contents

- [Description](#description)
- [Installation](#installation)
- [Example](#example)
- [Usage](#usage)

---

# Description
Initially this was one of a few scripts I wrote quickly for an old job I had where I needed to sanitize disks in a medical context.  I needed to have a GDPR-compliant disk-sanitization process up-and-running for legal reasons - it's a long story.  Anyways, at the time I was working basic Tech Support - again, long story - and some of the requirements for such a task require extreme proof.  One issue I was noticing was that nvme-cli was not outputting information I needed to the terminal, so I created this script in my own time due to work-load and time constraints on the job.  

The initial release worked to do what I needed, however, it used eval which is a big no-no, and I have learned a lot since then, thus decided to re-write the script from scratch.

Initially I said no Eval, and I have kept to that. I decided to add the -c option to replicate the previous shell-based behaviour. Instead of eval, I use $SHELL -c '<command>' when shell interpretation is explicitly requested. The behaviour is similar, but the execution path is now deliberate - $SHELL being your default login shell. 

I actually wrote this out many times and changed back-and-forth.  I decided to add logcom '<Command>' to function as before so as to not break existing workflows, however, I ultimately opted-out of this at the last minute - the reason being, what if the User does 'logcom !!' or 'logcom <wrong flag>'.

This would be very unsecure, so older workflows will require a '-c' to function - just as an extra safety layer.

So using:

```
logcom -c 'echo "hello world" | grep -o "hello"'
```
the output will show:

```
[COMMAND] echo "hello world" |  grep -o "hello"

[COMMAND OUTPUT]
hello

[COMMAND SUCCESS] The command exited with Exit Code: 0
```

Whereas with:

```
logcom -- echo "hello world" |  grep  -o "hello"
```

the output is:

```
hello
hello
```

This is because the shell handles the pipe before LogCommand receives the arguments. grep receives the stdout produced by LogCommand, not the output of the wrapped command itself:

```
[COMMAND] echo hello world

[COMMAND OUTPUT]
hello world

[COMMAND SUCCESS] The command exited with Exit Code: 0
```

A better example to display this is:

```
logcom -- echo "hello world" | grep "[COMMAND]"
```

Output:

```
[COMMAND] echo hello world
[COMMAND OUTPUT]
[COMMAND SUCCESS] The command exited with Exit Code: 0

```
So these are the differences in usage.  So be aware of these use-cases.  It is always safer to use a single command, and pipe that to tee or LogAppend.

E.g: 

```
logcom -- echo "hello world" | tee log.file
```

However, if you need to do more complex piping or using '&&', or ';', then the option is there.  The tool avoids accidental shell interpretation unless the user explicitly chooses string execution mode - so it is a necessary evil in a way.

E.g:

```
logcom -c 'echo "hello world" | grep -o "hello"' | tee log.file
```

Just think of this way as sh -c '<args>'

Note that if you use '<Command 1>; <Command 2>', and the second succeeds, the tool will imply success, even if the first fails.  
The tool isn't really meant to be used in this way... but you can do whatever you want!  

---

# Installation

cd to the directory where you wish to download to, then copy paste the following command:

## Forgejo

For all the revolutionaries out there who refuse to download from GitHub:

```
git clone https://v14.next.forgejo.org/FMallon/LogCommand && cd LogCommand && chmod +x log_command.sh && sudo ln -sf "$(pwd)/log_command.sh" /usr/local/bin/logcom
```

## Github

```
git clone https://github.com/FMallon/LogCommand && cd LogCommand && chmod +x log_command.sh && sudo ln -sf "$(pwd)/log_command.sh" /usr/local/bin/logcom
```

---

# Example

---

## Example 1:

In the CLI:
```
logcom -- echo "hello world"
```
Output:
```
[COMMAND] echo hello world

[COMMAND OUTPUT]
hello world

[COMMAND SUCCESS] The command exited with Exit Code: 0
```
---
## Example 2:

In the CLI:
```
grep "hello" non_existent_file.txt
```

Now, providing you don't actually have a file called "non_existent_file.txt", the output is:

```
grep: hello: No such file or directory

```
and $? (the return code) will be 2

Now, using LogCommand with the same example; in the CLI: 
```
logcom -- grep "hello" non_existent_file.txt
```

Output:
```
[COMMAND] grep hello non_existent_file.txt

[COMMAND OUTPUT]
grep: non_existent_file.txt: No such file or directory

[COMMAND FAILED] The command exited with Exit Code: 2
```

---

# Usage
    
    [ -- ] <Command> Runs the args as a command

        Usage:

            -> logcom -- echo "hello world"

            This will run the command 'echo' with "hello world"



    [ --dry-run ] <Command> Prints the Command to the terminal but doesn't run it

        Usage:

            -> logcom --dry-run echo "hello world"
    
        [NOTE]

            This mode prints the command on an argument-by-argument basis.
            It is intended for debugging and verifying how the argument is parsed in the event of error or unsurity.

            Useful when commands fail due to incorrect argument splitting or quoting issues.

            For example:

                -> logcom --dry-run echo hello world 

                This will pass 3 args - this will still work due to the nature of echo;
                

                -> logcom --dry-run echo "hello world" 

                This will pass 2 args - this would be the correct use of echo, but you can see that by using quotes, the arg isn't being separated into 3 args

            Furthermore, if you run:

                -> logcom --dry-run ls | grep file.txt

                This will only display "[ARG 0] ls".

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

                -> logcom -- "echo hello world"

                This will fail because the whole command is passed as a single string.
                This will result in failure because logcom does not use eval, but opts for a safer array composition to run the specified command.


    
    [ -c ] "<string>" Runs the String as a Command, allowing for the usage of Shell-specific operators such as:

            |   &&   ;   >   >>

        Usage:

            -> logcom -c 'echo "hello world" | grep "hello"'



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

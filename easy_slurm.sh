#!/bin/bash

##########################################################################################
#Script Name	:   Easy Slurm                                                                                          
#Description	:   Stores versions & dependancies for HPC modules in users workflow
#                   Quickly generates 'boilerplate' Slurm scripts for selected software
#Args           :   Optional string pattern for returning diff versions of given software                                                                                       
#Author       	:   Lee Bardon                                                
#Email         	:   leerbardon@gmail.com                                           
##########################################################################################

#-----------------------------------------------------------------------------------------
#                                       ASCII ART 
#-----------------------------------------------------------------------------------------

display_art () {
printf ' \n
----------------------------------------------------------
    ______                    _____ __                   
   / ____/___ ________  __   / ___// /_  ___________ ___ 
  / __/ / __ `/ ___/ / / /   \__ \/ / / / / ___/ __ `__ \
 / /___/ /_/ (__  ) /_/ /   ___/ / / /_/ / /  / / / / / /
/_____/\__,_/____/\__, /   /____/_/\__,_/_/  /_/ /_/ /_/ 
                 /____/                                  

------------------ FOR HPC WORKFLOWS --------------------

'
}


#-----------------------------------------------------------------------------------------
#                             PACKAGES & MODULES HASH TABLE 
#-----------------------------------------------------------------------------------------

declare -A all_packages=(
                        ["bwa/0.7.17"]="gcc/8.3.0 bwa/0.7.17"
                        ["samtools/1.10"]="gcc/8.3.0 samtools/1.10" 
                        ["samtools/18.0.4"]="gcc/9.2.0 samtools/18.0.4"
                        ["bowtie2/2.4.2"]="gcc/8.3.0 intel/19.0.4 bowtie2/2.4.2"
                        ["bowtie2/2.3.5.1"]="gcc/8.3.0 intel/18.0.4 bowtie2/2.3.5.1"
                        ["sratoolkit/2.10.7"] = "gcc/8.3.0 sratoolkit/2.10.7"
                        ["sratoolkit/2.11.0"] = "gcc/8.3.0 sratoolkit/2.11.0"
                        ["pilon/1.22"] = "gcc/8.3.0 pilon/1.22"
                        ["fastqc/0.11.9"] = "gcc/9.2.0 fastqc/0.11.9"
                        ["fastqc/0.11.7"] = "gcc/8.3.0  intel/19.0.4 fastqc/0.11.7"
                        ["spades/3.13.0"] = "gcc/8.3.0 spades/3.13.0"
                        ["blast-plus/2.11.0"] = "gcc/9.2.0 blast-plus/2.11.0"
                        ["iq-tree/2.0.6"] = "gcc/8.3.0 iq-tree/2.0.6"
                        ["trimal/1.4.1"] = "gcc/8.3.0 trimal/1.4.1"
                        ["muscle/3.8.1551"] = "gcc/8.3.0  intel/18.0.4 muscle/3.8.1551"
                        )
declare -A packages=()



#-----------------------------------------------------------------------------------------
#                                    MAIN FUNCTIONS  
#-----------------------------------------------------------------------------------------

check_for_argument () {

    # If argument is given at launch, calls "look_for_matches" function

    if [ $# -eq 0 ]
    then
        :
    else 
        look_for_matches $1
    fi
} 


look_for_matches () {

    # Searches keys in "all_packages" for patterns matching input argument
    # If no matches found, "all_packages" will be displayed for user selection
    # Else, "packages" containing matched pattern will be displayed

    matches=()
        while read; do
            matches+=( "$REPLY" )
        done < <(for p in "${!all_packages[@]}"; do echo $p; done | grep $1)

    if [ ${#matches[@]} -eq 0 ]
    then
        :
    else 
        for i in ${matches[@]}; 
        do
            packages[$i]="${all_packages[$i]}"
        done
    fi
}


select_package () {

    # Takes "all_packages" or "packages" hash table as arg
    # Uses bash native 'select' function to create menu
    # Assigns PACKAGE according to user selection 

    PS3=$'\n    ::    Select package (choose number): '

    select PACKAGE
    do 
        if ! [[ "$REPLY" =~ ^[0-9]+$ ]];
        then
            printf "\n** OOPS! Please enter an integer number ** \n"
            continue
        elif [[ "$REPLY" -lt 1 || "$REPLY" -gt $# ]];
        then
            printf "\n** OOPS! Number must be between 1 and $# ** \n"
            continue
        else 
            echo -e "\e[3m\nGenerating easy.slurm for: $PACKAGE  \e[0m \n"
            break
        fi
    done

}


generate_slurm () {

    # Generates Slurm script based on user's choices
    # Outputs in 'easy.slurm' in current directory

    now=$(date +'%m/%d/%Y')
    printf "#!/bin/bash 
#   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#   |  > This script was generated by Easy Slurm on $now <  |
#   |                                                             |
#   |    Before submitting ....                                   |
#   |            > SET RESOURCE REQUIREMENTS                      |
#   |            > ADJUST LAUNCHER VARIABLES (if applicable)      |
#   |            > DON'T FORGET THE CODE! :)                      |
#   |                                                             |
#   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#SBATCH --nodes=1 
#SBATCH --ntasks=5 
#SBATCH --cpus-per-task=1 
#SBATCH --mem=0 
#SBATCH --time=0:30:00 

module purge
" > easy.slurm
   
    modules=("$@")
    for mod in "${modules[@]}";
    do
        echo "module load $mod" >> easy.slurm
    done

}

check_if_launcher () {

    # Asks user if they'd like to create a Launcher script
    # Calls "add_launcher_lines" if user responds "y"

shopt -s nocasematch
printf "    ::    Will this be a Launcher script? (y/n) : "
read answer

    if [[ $answer = "y" ]]; then
        add_launcher_lines
    elif
        [[ $answer = "n" ]]; then
        :
    else
        printf "\n** OOPS! Please enter 'y' or 'n' **  \n\n"
        check_if_launcher
    fi

}


add_launcher_lines () {

    # Appends Launcher-specific lines to easy.slurm

    printf "module load launcher 


export LAUNCHER_DIR=\$LAUNCHER_ROOT
export LAUNCHER_RMI=SLURM
export LAUNCHER_PLUGIN_DIR=\$LAUNCHER_DIR/plugins
export LAUNCHER_SCHED=interleaved
export LAUNCHER_WORKDIR=\$PWD
export LAUNCHER_BIND=1
export LAUNCHER_JOB_FILE=ENTER_JOB_FILE_HERE
\$LAUNCHER_DIR/paramrun" >> easy.slurm

}


success_message () {

    echo -e "\e[3m\n\nYour script is now available at $PWD/easy.slurm \e[0m \n\n "
    echo "  ~~~~  (EASY) SLURM - It's Highly Addictive!  ~~~~     " 
    echo ""

}



#-----------------------------------------------------------------------------------------
#                                        PROCEDURE 
#-----------------------------------------------------------------------------------------

display_art && check_for_argument $1

if [ ${#packages[@]} -eq 0 ]
then
    select_package "${!all_packages[@]}"
else 
    select_package "${!packages[@]}"
fi

declare -a modules=(${all_packages[$PACKAGE]})

generate_slurm "${modules[@]}" && check_if_launcher && success_message

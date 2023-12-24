#!/bin/bash

function my_readlink() {
    cd $1
    pwd
    cd - > /dev/null
}

function cat_readme() {
    echo ""
    echo "Usage: $(basename $0) DELIVERY_DIR REPORTS_DIR"
    echo -e "\tDELIVERY_DIR\tShould be the directory where your project files are"
    echo -e "\tREPORTS_DIR\tShould be the directory where we output the reports"
    echo -e "\t\t\tTake note that existing reports will be overriden"
    echo ""
}

function banana_split() {
    CURRENT_FILE=".c"
    echo -e "${Yellow}BANANA NA NA NA NA${Color_Off}"
    if [ -f ".gitignore" ]; then
        git ls-files --others --ignored --exclude-standard > ignore.tmp
    fi
    while read p; do
        IFS=':' read -ra ADDR <<< "$p"
        if [ -f "ignore.tmp" ]; then
            while read ignored; do
                if [ "$ignored" -ef "${ADDR[0]}" ]; then
                    continue 2
                fi
            done < "ignore.tmp"
        fi
        if [ "$CURRENT_FILE" != "${ADDR[0]}" ]; then
            echo "‣ In file ${ADDR[0]}"
            CURRENT_FILE="${ADDR[0]}"
        fi
        if [ "${ADDR[2]}" = " MAJOR" ]; then
            echo -ne "${Red}[Major]"
        elif [ "${ADDR[2]}" = " MINOR" ]; then
            echo -ne "${Yellow}[MINOR]"
        elif [ "${ADDR[2]}" = " INFO" ]; then
            echo -ne "${Cyan}[INFO]"
        fi
        error="${ADDR[3]: 2}"
        echo -ne " ($error)${Color_Off} - ${errors[${error}]^}."
        echo -e " ${IBlack}(${ADDR[0]: 2}:${ADDR[1]})${Color_Off}"
    done < "$1"
    rm -f "ignore.tmp"
    echo -e "${Yellow}BANANA SPLIT${Color_Off}"
}

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Yellow='\033[0;33m'       # Yellow
Cyan='\033[0;36m'         # Cyan
IBlack='\033[0;90m'       # Black

declare -A errors

errors=(
["A3"]="file not ending with a line break (\\\\n)"
["C1"]="conditional block with more than 3 branches, or at a nesting level of 3 or more"
["C2"]="abusive ternary operator usage"
["C3"]="use of "goto" keyword"
["F2"]="function name not following the snake_case convention"
["F3"]="line of more than 80 columns"
["F4"]="line part of a function with more than 20 lines"
["F5"]="function with more than 4 parameters"
["F6"]="function with empty parameter list"
["F7"]="structure parameter received by copy"
["F8"]="comment inside function"
["F9"]="nested function defined"
["G1"]="file not starting with correctly formatted Epitech standard header"
["G2"]="zero, two, or more empty lines separating implementations of functions"
["G3"]="bad indentation of preprocessor directive"
["G4"]="global variable used"
["G5"]=""include" directive used to include file other than a header"
["G6"]="carriage return character (\\r) used"
["G7"]="trailing space"
["G8"]="leading or trailing empty line"
["G10"]="use of inline assembly"
["H1"]="bad separation between source file and header file"
["H2"]="header file not protected against double inclusion"
["H3"]="abusive macro usage"
["L1"]="multiple statements on the same line"
["L2"]="bad indentation at the start of a line"
["L3"]="misplaced or missing space(s)"
["L4"]="misplaced curly bracket"
["L5"]="variable not declared at the beginning of the function or several declarations with the same statement"
["L6"]="missing blank line after variable declarations or unnecessary blank line"
["O1"]="compiled, temporary or unnecessary file"
["O3"]="more than 10 functions or more than 5 non-static functions in the file"
["O4"]="file name not following the snake_case convention"
["V1"]="identifier name not following the snake_case convention"
["V3"]="misplaced pointer symbol"
)

if [ $# == 1 ] && [ $1 == "--help" ]; then
    cat_readme
elif [ $# = 2 ];
then
    DELIVERY_DIR=$(my_readlink "$1")
    REPORTS_DIR=$(my_readlink "$2")
    DOCKER_SOCKET_PATH=/var/run/docker.sock
    HAS_SOCKET_ACCESS=$(test -r $DOCKER_SOCKET_PATH; echo "$?")
    GHCR_REGISTRY_TOKEN=$(curl -s "https://ghcr.io/token?service=ghcr.io&scope=repository:epitech/coding-style-checker:pull" | grep -o '"token":"[^"]*' | grep -o '[^"]*$') 
    GHCR_REPOSITORY_STATUS=$(curl -I -f -s -o /dev/null -H "Authorization: Bearer $GHCR_REGISTRY_TOKEN" "https://ghcr.io/v2/epitech/coding-style-checker/manifests/latest" && echo 0 || echo 1)
    BASE_EXEC_CMD="docker"
    EXPORT_FILE="$REPORTS_DIR"/coding-style-reports.log
    ### delete existing report file
    rm -f "$EXPORT_FILE"

    ### Pull new version of docker image and clean olds

    if [ $HAS_SOCKET_ACCESS -ne 0 ]; then
        echo "WARNING: Socket access is denied"
        echo "To fix this we will add the current user to docker group with : sudo usermod -a -G docker $USER"
        read -p "Do you want to proceed? (yes/no) " yn
        case $yn in 
            yes | Y | y | Yes | YES) echo "ok, we will proceed";
                sudo usermod -a -G docker $USER;
                echo "You must reboot your computer for the changes to take effect";;
            no | N | n | No | NO) echo "ok, Skipping";;
            * ) echo "invalid response, Skipping";;
        esac
        BASE_EXEC_CMD="sudo ${BASE_EXEC_CMD}"
    fi


    if [ $GHCR_REPOSITORY_STATUS -eq 0 ]; then
        echo "Downloading new image and cleaning old one..."
        $BASE_EXEC_CMD pull ghcr.io/epitech/coding-style-checker:latest && $BASE_EXEC_CMD image prune -f
        echo "Download OK"
    else
        echo "WARNING: Skipping image download"
    fi

    ### generate reports
    $BASE_EXEC_CMD run --rm --security-opt "label:disable" -i -v "$DELIVERY_DIR":"/mnt/delivery" -v "$REPORTS_DIR":"/mnt/reports" ghcr.io/epitech/coding-style-checker:latest "/mnt/delivery" "/mnt/reports"
    # [[ -f "$EXPORT_FILE" ]] && echo "$(wc -l < "$EXPORT_FILE") coding style error(s) reported in "$EXPORT_FILE", $(grep -c ": MAJOR:" "$EXPORT_FILE") major, $(grep -c ": MINOR:" "$EXPORT_FILE") minor, $(grep -c ": INFO:" "$EXPORT_FILE") info"

    banana_split "$EXPORT_FILE"
    ### delete useless report file
    rm -f "$EXPORT_FILE"
else
    cat_readme
fi

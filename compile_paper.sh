#!/bin/sh

# Note this script only works if it's called from the main directory and the
# paper you want to copmile is one of the subdirectories (except docs/)

typeset -r modes=("draft" "revision")
typeset -i modeIdx=0
typeset sourceDir=""

function show_help()
{
    echo "Usage: ./$0 -p <paper_path> [OPTIONS]" > /dev/stderr
    echo " -p The path of the 'paper.bs' to compile" > /dev/stderr
    echo " -d Draft mode (default)" > /dev/stderr
    echo " -r Revision mode (excludes -d)" > /dev/stderr
    echo " -h Show this help and exit" > /dev/stderr
}

function set_source_paper()
{
    sourceDir="$1"
    if [[ ! -d "${sourceDir}" ]]
    then
        echo "Cannot find directory: '${sourceDir}'" > /dev/stderr
        return 1
    fi

    typeset -r sourcePaper="${sourceDir}/paper.bs"
    if [[ ! -e "${sourcePaper}" ]]
    then
        echo "Cannot find paper.bs: '${sourcePaper}'" > /dev/stderr
        return 1
    fi

    return 0
}

function make_paper()
{
    cd "$sourceDir"
    make
    cd -

    typeset -r targetDir="docs/${sourceDir}"
    mkdir -p "${targetDir}" || return 1

    typeset targetPaper=""

    typeset -r mode="${modes[$modeIdx]}"
    typeset -i i=0
    while :
    do
        targetPaper="${targetDir}/${mode}${i}.html"
        [[ ! -e "${targetPaper}" ]] && break
        ((i++))
    done

    typeset -r sourcePaper="${sourceDir}/paper.html"
    cp --verbose "${sourcePaper}" "${targetPaper}"
    return $?
}

function make_index()
{
    cd docs
    sh make_index.sh
    typeset -i errorCode=$?
    cd -
    return $errorCode
}

while getopts rdp:h name
do
    case ${name} in
        r)
            modeIdx=1
            ;;
        d)
            ;;
        p)
            set_source_paper "${OPTARG}" || exit 1
            ;;
        h)
            show_help
            exit 0
            ;;
        *)
            exit 1
            ;;
    esac
done

if [[ -z "${sourceDir}" ]]
then
    echo "Missing argument: -p" > /dev/stderr
    show_help
    exit 1
fi

echo "Paper Path: '${sourceDir}'"
echo "Mode Idx:   $modeIdx"
echo "Mode:       ${modes[$modeIdx]}"

make_paper || exit 1 
make_index || exit 1

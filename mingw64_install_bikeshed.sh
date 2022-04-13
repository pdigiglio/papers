#!/bin/sh

function package_exists()
{
    typeset -r output="`pacman --query --quiet --search $1`"
    [[ -n "$output" ]] && return 0 || return 1
    #                            ^ true      ^ false
}

function collect_dependencies()
{
    typeset -r pacman_deps=( \
        #mingw-w64-x86_64-libjpeg-turbo \
        #mingw-w64-x86_64-libxml2 \
        #mingw-w64-x86_64-libxslt \
        mingw-w64-x86_64-python-lxml \
        mingw-w64-x86_64-python-pillow \
        mingw-w64-x86_64-python-html5lib \
        mingw-w64-x86_64-python-cssselect \
        mingw-w64-x86_64-python-aiohttp \
    )

    typeset packages=""
    for dep in ${pacman_deps[@]}
    do
        if package_exists $dep
        then
            echo "Found package: $dep" > /dev/stderr
        else
            echo "Couldn't find package: $dep" > /dev/stderr
            packages="$dep $packages"
        fi
    done
    echo "$packages"
}

typeset -r packages="`collect_dependencies`"
if [[ -n "$packages" ]]
then
    echo "Installing deps: $packages"
    pacman -Syu $packages || exit 1
else
    echo "All dependencies already installed. Nothing to do."
fi


typeset -r PYTHON="`which python`"
#typeset -r PYTHON="/mingw64/lib/python3.10/venv/scripts/nt/python.exe"

echo ""
echo "Python is: $PYTHON" 
echo "Python version: `$PYTHON --version`"
echo ""

SETUPTOOLS_USE_DISTUTILS=stdlib CPATH=$CPATH:/mingw64/include/libxml2 \
    "$PYTHON" -m pip install bikeshed && bikeshed update

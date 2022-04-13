#!/bin/sh

function make_index()
{
    typeset -r index=index.html

    # Make backup 
    mv --force "$index" "${index}.bak"

    typeset -r tmpIndex="${index}.tmp"
    echo "<!DOCTYPE html>" > "$tmpIndex"
    echo "<html>" >> "$tmpIndex"
    echo "<body>" >> "$tmpIndex"
    for i in `find . -name "*.html"`
    do
        echo "<p><a href=\"$i\">$i</a></p>" >> "$tmpIndex"
    done
    echo "</body>" >> "$tmpIndex"
    echo "</html>" >> "$tmpIndex"

    mv --verbose "$tmpIndex" "$index"
}

make_index

$range = 1..500

$range | write-ProgressEx -Total $range.Count | ForEach-Object {
    # The progress name is equal to the script file name
}

function test-range {
    $range | write-ProgressEx -Total $range.Count | ForEach-Object {
        # The progress name is equal to the function name
    }
}

test-range
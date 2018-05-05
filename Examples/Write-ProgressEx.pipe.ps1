$nodes = 1..20
$names = 1..50

$nodes | Where-Object {$true} | write-ProgressEx "pipe nodes" -Total $nodes.Count -Status "outer" -ShowMessages | ForEach-Object {
    $names | Where-Object {$true} | write-ProgressEx "pipe names" -Total $names.Count -id 1 -Status "inner" | ForEach-Object {
        #...
    }
}

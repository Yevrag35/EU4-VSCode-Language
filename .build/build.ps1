[CmdletBinding()]
param ()

Function Read-SyntaxIntoList([string]$Directory) {

    $readContent = New-Object -TypeName 'System.Collections.Generic.List[string]' -ArgumentList 300

    $file = Get-ChildItem -Path $Directory -Filter *.tmLanguage.json
    $allLinesEnumerable = [System.IO.File]::ReadLines($file.FullName, [System.Text.Encoding]::UTF8)

    if ($null -ne $allLinesEnumerable) {
        $readContent.AddRange($allLinesEnumerable)
    }

    , $readContent
}

Function Replace-Content([string]$JoinedScopes, [System.Collections.Generic.List[string]]$Lines) {

    $index = $Lines.FindIndex([System.Predicate[object]]{
        param ($x)
        $x -like "*`"high-level-scopes`":*{*"
    })

    if ($index -le -1) {
        throw "The 'High-Level-Scopes' repository was not found in the syntax language file."
    }
    
    $nextIndex = $Lines.FindIndex($index, [System.Predicate[object]]{
        param ($x)
        $x -like "*`"match`":*"
    })

    $replaceWith = "\\b(?i:$JoinedScopes)\\b(?=[ ]*\\=[ ]*(?:\\{|$))"
    $Lines[$nextIndex] = $Lines[$nextIndex] -replace '^(\s*)\"match\":(\s*)(.+)$', ('$1"match":$2"{0}"' -f $replaceWith)
}

$eu4Code = "$PSScriptRoot\..\eu4-code"
#$eu4Code = "E:\Local_Repos\EUIV_Format_Syntax\eu4-code"
$scopesPath = Resolve-Path -Path "$eu4Code\high-level-scopes.txt" | % Path
$syntaxPath = Resolve-Path -Path "$eu4Code\syntaxes" | % Path

[string[]] $highLevelScopes = Get-Content -Path $scopesPath | Sort-Object
Set-Content -Path $scopesPath -Value $highLevelScopes -Force

$joinAll = $highLevelScopes -join '|'

$syntaxContent = Read-SyntaxIntoList -Directory $syntaxPath
Replace-Content -JoinedScopes $joinAll -Lines $syntaxContent

Set-Content -Path $syntaxFile.FullName -Value $syntaxContent -Force

Copy-Item -Path $eu4Code "$env:USERPROFILE\.vscode\extensions" -Recurse -Force
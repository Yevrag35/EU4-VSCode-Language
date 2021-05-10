$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$eu4Code = "$curDir\..\eu4-code"
[string[]] $highLevelScopes = Get-Content -Path "$eu4Code\high-level-scopes.txt" | Sort-Object
$joinAll = $highLevelScopes -join '|'

$syntaxFile = Get-ChildItem -Path "$eu4Code\syntaxes" -Filter *.tmLanguage.json
$syntaxContent = $syntaxFile | Get-Content -Raw

$replaceWith = $syntaxContent -creplace 'BOOM[_]REPLACE[_]ME[_]BOOM', $joinAll
Set-Content -Path $syntaxFile.FullName -Value $replaceWith -Force

Copy-Item -Path $eu4Code "$env:USERPROFILE\.vscode\extensions" -Recurse -Force
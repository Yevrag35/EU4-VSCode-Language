[CmdletBinding()]
param ()

#$allModules = Get-ChildItem -Path "$PSScriptRoot" -Filter *.psm1 -ErrorAction Stop
$allModules = Get-ChildItem -Path "E:\Local_Repos\EUIV_Format_Syntax\.build" -Filter *.psm1 -ErrorAction Stop
foreach ($module in $allModules) {
	Import-Module $module.FullName -ErrorAction Stop
}

#$eu4Code = "$PSScriptRoot\..\eu4-code"
$eu4Code = "E:\Local_Repos\EUIV_Format_Syntax\eu4-code"
#$scopesPath = Resolve-Path -Path "$eu4Code\high-level-scopes.txt" | % Path
$syntaxPath = Resolve-Path -Path "$eu4Code\syntaxes" | % Path

#[string[]] $highLevelScopes = Get-Content -Path $scopesPath | Sort-Object -Unique
[string[]] $highLevelScopes = Resolve-Path -Path "$eu4Code\high-level-scopes.txt" | Read-AndSortItems
#Set-Content -Path $scopesPath -Value $highLevelScopes -Force

$joinAll = $highLevelScopes -join '|'

$syntaxContent = New-Object -TypeName 'System.Collections.Generic.List[string]' -ArgumentList 300
$syntaxFilePath = Read-SyntaxIntoList -Directory $syntaxPath -Lines $syntaxContent
Replace-Content -JoinedScopes $joinAll -Lines $syntaxContent

Set-Content -Path $syntaxFilePath -Value $syntaxContent -Force

Copy-Item -Path $eu4Code "$env:USERPROFILE\.vscode\extensions" -Recurse -Force
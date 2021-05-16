Function Read-AndSortItems() {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [Alias("FullName")]
        [ValidateScript({
            # The file must exist and have a .txt extension
            (Test-Path $_ -PathType Leaf) -and [System.IO.Path]::GetExtension($_) -eq '.txt'
        })]
        [string]
        $Path,

        [Parameter(Mandatory=$false)]
        [switch]
        $ReadOnly
    )
    Process {
        [string[]] $fileContent = [System.IO.File]::ReadLines($Path) | Sort-Object -Unique

        if (-not $ReadOnly) {

            Set-Content -Path $Path -Value $fileContent -Force   
        }
        $fileContent
    }
}

Function Read-SyntaxIntoList {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [parameter(Mandatory=$true, Position=0)]
        [string]
        $Directory,

        [Parameter(Mandatory=$true, Position=1)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]
        $Lines,

        [Parameter(Mandatory=$false, DontShow=$true)]
        [ValidateNotNull()]
        [System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
    )
    
    if (-not (Test-Path -Path $Directory -PathType Container)) {
        throw "The specified folder '$Directory' is not a valid directory or does not exist."
    }

    [array] $files = Get-ChildItem -Path $Directory -Filter *.tmLanguage.json
    if ($files.Count -le 0) {
        throw "No valid tmLanguage.json file was found in '$Directory'."
    }
    elseif ($files.Count -gt 1) {
        throw "Too many tmLanguage.json files were found.  Modify this script to accomodate multiple results."
    }
    else {
        $file = $files[0]
        if ($null -eq $file) {
            throw "No file was located because an empty array was returned."
        }
    }

    $allLinesEnumerable = [System.IO.File]::ReadLines($file.FullName, $Encoding)

    if ($null -ne $allLinesEnumerable) {
        $Lines.AddRange($allLinesEnumerable)
    }
    else {
        throw "No were able to be read from '$($file.FullName)'."
    }

    $file.FullName
}

Function Replace-Content() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateScript({
            # Must not be null or empty
            -not [string]::IsNullOrEmpty($_)
        })]
        [string]
        $JoinedScopes,

        [Parameter(Mandatory=$true, Position=1)]
        [ValidateScript({
            # The incoming list/collection must NOT be empty
            $_.Count -gt 0
        })]
        [System.Collections.Generic.List[string]]
        $Lines
    )

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
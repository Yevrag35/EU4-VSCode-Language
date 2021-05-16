Function Append-Line() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [System.Text.StringBuilder]
        $Builder,

        [Parameter(Mandatory=$false)]
        [switch]
        $IncludeEmptyLines,

        [Parameter(Mandatory=$false)]
        [switch]
        $NoLineBreakAtEnd,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]
        $InputObject
    )
    Process {

        if (-not $IncludeEmptyLines) {
            $lines = $InputObject.Where({-not [string]::IsNullOrWhitespace($_)})
        }
        else {
            $lines = $InputObject
        }

        if ($NoLineBreakAtEnd) {
            for ($i = 0; $i -lt $lines.Count - 1; $i++) {

                [void] $Builder.AppendLine($lines[$i])
            }
            [void] $Builder.AppendLine($lines[$lines.Count - 1])
        }
        else {
            foreach ($line in $lines) {

                [void] $Builder.AppendLine($line)
            }
        }
    }
}

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
        [ValidateNotNull()]
        [System.Text.Encoding]
        $Encoding = [System.Text.Encoding]::UTF8,

        [Parameter(Mandatory=$false)]
        [switch]
        $ReadOnly
    )
    Process {
        $builder = New-Object System.Text.StringBuilder
        $lines,$comments = [System.IO.File]::ReadAllLines($Path, $Encoding).Where({$_ -notlike "#*"}, "Split")

        [string[]] $fileContent = $lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique
        $comments | Append-Line $builder
        $fileContent | Append-Line $builder -NoLineBreakAtEnd

        if (-not $ReadOnly) {
            
            Set-Content -Path $Path -Value $builder.ToString() -Force
        }
        else {
            Write-Host $builder.ToString() -f Yellow
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
        [AllowEmptyString()]
        # [ValidateScript({
        #     # The incoming list/collection must NOT be empty
        #     $_.Count -gt 0
        # })]
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
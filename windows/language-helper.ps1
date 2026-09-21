param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("translate", "fix")]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

$ErrorActionPreference = "Stop"

function Write-Result([string]$Text) {
    [System.IO.File]::WriteAllText(
        $OutputFile,
        $Text,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Has-Arabic([string]$Text) {
    return [regex]::IsMatch($Text, "[\u0600-\u06FF]")
}

function Invoke-DirectTranslation([string]$Text) {
    $target = if (Has-Arabic $Text) { "en" } else { "ar" }
    $encoded = [System.Uri]::EscapeDataString($Text)
    $uri = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$target&dt=t&q=$encoded"

    $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 20

    if ($null -eq $response -or $null -eq $response[0]) {
        throw "Translation service returned an empty response."
    }

    $translatedParts = foreach ($part in $response[0]) {
        if ($null -ne $part -and $part.Count -gt 0 -and $null -ne $part[0]) {
            [string]$part[0]
        }
    }

    return ($translatedParts -join "")
}

function Invoke-SmartFix([string]$Text) {
    $body = @{
        text     = $Text
        language = "auto"
    }

    $response = Invoke-RestMethod -Uri "https://api.languagetool.org/v2/check" -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body -TimeoutSec 20

    $fixed = $Text
    $matches = @($response.matches) | Sort-Object -Property offset -Descending

    foreach ($match in $matches) {
        if ($null -eq $match.replacements -or $match.replacements.Count -eq 0) {
            continue
        }

        $offset = [int]$match.offset
        $length = [int]$match.length
        $replacement = [string]$match.replacements[0].value

        if ($offset -lt 0 -or $length -lt 0) {
            continue
        }

        if (($offset + $length) -le $fixed.Length) {
            $fixed = $fixed.Remove($offset, $length).Insert($offset, $replacement)
        }
    }

    $fixed = [regex]::Replace($fixed, "[ \t]+", " ")
    $fixed = [regex]::Replace($fixed, "\s+([,.;:!?،؛])", '$1')
    $fixed = [regex]::Replace($fixed, "([,.;:!?،؛])([^\s\r\n])", '$1 $2')
    $fixed = [regex]::Replace($fixed, "(\r?\n){3,}", ([Environment]::NewLine + [Environment]::NewLine))

    return $fixed.Trim()
}

try {
    if (-not (Test-Path -LiteralPath $InputFile)) {
        throw "Input file was not found."
    }

    $text = [System.IO.File]::ReadAllText($InputFile, [System.Text.Encoding]::UTF8)

    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Result ""
        exit 0
    }

    switch ($Mode) {
        "translate" {
            Write-Result (Invoke-DirectTranslation $text)
        }
        "fix" {
            Write-Result (Invoke-SmartFix $text)
        }
    }

    exit 0
}
catch {
    Write-Result ("__ERROR__:" + $_.Exception.Message)
    exit 1
}

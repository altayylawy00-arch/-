param(
    [Parameter(Mandatory=$true)][ValidateSet("translate","fix")][string]$Mode,
    [Parameter(Mandatory=$true)][string]$InputFile,
    [Parameter(Mandatory=$true)][string]$OutputFile
)

$ErrorActionPreference = "Stop"

function Write-Result([string]$Text) {
    [System.IO.File]::WriteAllText($OutputFile,$Text,[System.Text.UTF8Encoding]::new($false))
}

function Has-Arabic([string]$Text) {
    return [regex]::IsMatch($Text,'[\u0600-\u06FF]')
}

function Invoke-Translation([string]$Text) {
    $source = if (Has-Arabic $Text) { "ar" } else { "en" }
    $target = if ($source -eq "ar") { "en" } else { "ar" }
    $encoded = [System.Uri]::EscapeDataString($Text)
    $headers = @{ "User-Agent" = "OneClickLanguage/3.1" }
    $errors = @()

    # Primary: Lingva. It is used first because its output is generally
    # more suitable for direct sentence translation than translation-memory matches.
    try {
        $uri = "https://lingva.ml/api/v1/$source/$target/$encoded"
        $r = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -TimeoutSec 20
        $candidate = [string]$r.translation
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $candidate = $candidate.Trim()
            if (($target -eq "ar" -and (Has-Arabic $candidate)) -or
                ($target -eq "en" -and [regex]::IsMatch($candidate,'[A-Za-z]'))) {
                return $candidate
            }
        }
        $errors += "Lingva returned no usable translation."
    } catch {
        $errors += "Lingva: " + $_.Exception.Message
    }

    # Fallback: MyMemory machine translation.
    try {
        $uri = "https://api.mymemory.translated.net/get?q=$encoded&langpair=$source%7C$target&mt=1"
        $r = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -TimeoutSec 20
        $candidate = [string]$r.responseData.translatedText
        if ($r.responseStatus -eq 200 -and -not [string]::IsNullOrWhiteSpace($candidate)) {
            $candidate = [System.Net.WebUtility]::HtmlDecode($candidate).Trim()
            if ($candidate -ne $Text.Trim() -and
                (($target -eq "ar" -and (Has-Arabic $candidate)) -or
                 ($target -eq "en" -and [regex]::IsMatch($candidate,'[A-Za-z]')))) {
                return $candidate
            }
        }
        $errors += "MyMemory returned no usable translation."
    } catch {
        $errors += "MyMemory: " + $_.Exception.Message
    }

    throw ("Translation services are unavailable right now. " + ($errors -join " | "))
}

function Replace-Word([string]$Text,[string]$Bad,[string]$Good,[bool]$IgnoreCase=$false) {
    $pattern = '(?<![\p{L}\p{M}])' + [regex]::Escape($Bad) + '(?![\p{L}\p{M}])'
    $options = if ($IgnoreCase) { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase } else { [System.Text.RegularExpressions.RegexOptions]::None }
    return [regex]::Replace($Text,$pattern,[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $Good },$options)
}

function Get-Levenshtein([string]$A,[string]$B) {
    if ($A -eq $B) { return 0 }
    if ($A.Length -eq 0) { return $B.Length }
    if ($B.Length -eq 0) { return $A.Length }

    $prev = New-Object 'int[]' ($B.Length + 1)
    $curr = New-Object 'int[]' ($B.Length + 1)
    for ($j=0; $j -le $B.Length; $j++) { $prev[$j] = $j }

    for ($i=1; $i -le $A.Length; $i++) {
        $curr[0] = $i
        for ($j=1; $j -le $B.Length; $j++) {
            $cost = if ($A[$i-1] -eq $B[$j-1]) { 0 } else { 1 }
            $curr[$j] = [Math]::Min([Math]::Min($curr[$j-1] + 1,$prev[$j] + 1),$prev[$j-1] + $cost)
        }
        $tmp=$prev; $prev=$curr; $curr=$tmp
    }
    return $prev[$B.Length]
}

function Invoke-WindowsSpellFix([string]$Text,[string]$LanguageTag) {
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        $tb = New-Object System.Windows.Controls.TextBox
        $tb.Language = [System.Windows.Markup.XmlLanguage]::GetLanguage($LanguageTag)
        [System.Windows.Controls.SpellCheck]::SetIsEnabled($tb,$true)
        $tb.Text = $Text
        $tb.UpdateLayout()

        $repairs = @()
        $idx = 0
        while ($idx -lt $tb.Text.Length) {
            $errIndex = $tb.GetNextSpellingErrorCharacterIndex($idx,[System.Windows.Documents.LogicalDirection]::Forward)
            if ($errIndex -lt 0) { break }

            $len = $tb.GetSpellingErrorLength($errIndex)
            if ($len -le 0) { $idx = $errIndex + 1; continue }

            $error = $tb.GetSpellingError($errIndex)
            $suggestions = @($error.Suggestions)
            if ($suggestions.Count -gt 0) {
                $original = $tb.Text.Substring($errIndex,$len)
                $suggestion = [string]$suggestions[0]
                $distance = Get-Levenshtein $original.ToLowerInvariant() $suggestion.ToLowerInvariant()
                $limit = if ($original.Length -le 4) { 1 } elseif ($original.Length -le 8) { 2 } else { 3 }

                if ($distance -le $limit -and $suggestion.Length -gt 0) {
                    $repairs += [pscustomobject]@{ Start=$errIndex; Length=$len; Text=$suggestion }
                }
            }
            $idx = $errIndex + [Math]::Max($len,1)
        }

        $fixed = $Text
        foreach ($r in ($repairs | Sort-Object Start -Descending)) {
            $fixed = $fixed.Remove([int]$r.Start,[int]$r.Length).Insert([int]$r.Start,[string]$r.Text)
        }
        return $fixed
    } catch {
        return $Text
    }
}

function Invoke-Fix([string]$Text) {
    $fixed = $Text

    if (Has-Arabic $fixed) {
        $arabic = [ordered]@{
            "هاذا"="هذا"; "هاذه"="هذه"; "لاكن"="لكن"; "اللذي"="الذي"; "اللتي"="التي";
            "خطء"="خطأ"; "اخطاء"="أخطاء"; "الى"="إلى"; "الان"="الآن"; "ايضا"="أيضًا";
            "مساله"="مسألة"; "مسئله"="مسألة"; "مسوول"="مسؤول"; "لغه"="لغة"; "كلمه"="كلمة";
            "هنااك"="هناك"; "هناا"="هنا"; "مشكله"="مشكلة"; "طريقه"="طريقة"; "ترجمه"="ترجمة";
            "انشاءالله"="إن شاء الله"; "شاءالله"="شاء الله"
        }
        foreach ($k in $arabic.Keys) { $fixed = Replace-Word $fixed $k $arabic[$k] $false }

        $before = $fixed
        $fixed = Invoke-WindowsSpellFix $fixed "ar-IQ"
        if ($fixed -eq $before) { $fixed = Invoke-WindowsSpellFix $fixed "ar-SA" }
    } else {
        $english = [ordered]@{
            "teh"="the"; "frend"="friend"; "freind"="friend"; "recieve"="receive"; "adress"="address";
            "becuase"="because"; "langauge"="language"; "englih"="english"; "transalte"="translate";
            "translte"="translate"; "thier"="their"; "wierd"="weird"; "seperate"="separate";
            "definately"="definitely"; "occured"="occurred"; "untill"="until"; "wich"="which"
        }
        foreach ($k in $english.Keys) { $fixed = Replace-Word $fixed $k $english[$k] $true }

        $fixed = Invoke-WindowsSpellFix $fixed "en-US"
        $fixed = [regex]::Replace($fixed,'(?i)\bI\s+has\b','I have')
        $fixed = [regex]::Replace($fixed,'(?i)\byou\s+is\b','you are')
        $fixed = [regex]::Replace($fixed,'(?i)\bthey\s+is\b','they are')
        $fixed = [regex]::Replace($fixed,'(?i)\bhe\s+have\b','he has')
        $fixed = [regex]::Replace($fixed,'(?i)\bshe\s+have\b','she has')
    }

    $fixed = [regex]::Replace($fixed,'[ \t]+',' ')
    $fixed = [regex]::Replace($fixed,'\s+([,.;:!?،؛])','$1')
    $fixed = [regex]::Replace($fixed,'([,.;:!?،؛])([^\s\r\n])','$1 $2')
    $fixed = [regex]::Replace($fixed,'(\r?\n){3,}',([Environment]::NewLine + [Environment]::NewLine))
    return $fixed.Trim()
}

try {
    if (-not (Test-Path -LiteralPath $InputFile)) { throw "Input file was not found." }
    $text = [System.IO.File]::ReadAllText($InputFile,[System.Text.Encoding]::UTF8)

    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Result ""
        exit 0
    }

    if ($Mode -eq "translate") { Write-Result (Invoke-Translation $text) }
    else { Write-Result (Invoke-Fix $text) }
    exit 0
}
catch {
    Write-Result ("__ERROR__:" + $_.Exception.Message)
    exit 1
}

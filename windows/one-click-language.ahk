#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; One-Click Language — Windows helper
; Caps Lock = switch Windows keyboard language
; Floating toolbar = switch / direct translate / smart fix selected text

global Toolbar := Gui("+AlwaysOnTop +ToolWindow", "One-Click Language")
global LastExternalWindow := 0
global StatusText := ""
global ToolbarVisible := true

Toolbar.SetFont("s10", "Segoe UI")
Toolbar.MarginX := 10
Toolbar.MarginY := 10

btnSwitch := Toolbar.AddButton("w110 h34", "AR ⇄ EN")
btnTranslate := Toolbar.AddButton("x+8 w110 h34", "Translate")
btnFix := Toolbar.AddButton("x+8 w110 h34", "Smart Fix")
btnSettings := Toolbar.AddButton("x+8 w110 h34", "Typing Settings")
StatusText := Toolbar.AddText("xm y+8 w464", "Ready")

btnSwitch.OnEvent("Click", (*) => SwitchLanguage())
btnTranslate.OnEvent("Click", (*) => TranslateSelection())
btnFix.OnEvent("Click", (*) => SmartFixSelection())
btnSettings.OnEvent("Click", (*) => Run("ms-settings:typing"))

Toolbar.Show("AutoSize x20 y20 NoActivate")
SetStatus("Ready — helper downloads automatically when needed")
SetTimer(TrackActiveWindow, 150)

CapsLock::{
    SwitchLanguage()
}

F8::{
    ToggleToolbar()
}

TrackActiveWindow() {
    global Toolbar, LastExternalWindow
    hwnd := WinExist("A")
    if (hwnd && hwnd != Toolbar.Hwnd)
        LastExternalWindow := hwnd
}

FocusPreviousWindow() {
    global LastExternalWindow
    if (LastExternalWindow && WinExist("ahk_id " LastExternalWindow)) {
        WinActivate("ahk_id " LastExternalWindow)
        Sleep 120
        return true
    }
    return false
}

ToggleToolbar() {
    global Toolbar, ToolbarVisible
    if ToolbarVisible {
        Toolbar.Hide()
        ToolbarVisible := false
    } else {
        Toolbar.Show("AutoSize x20 y20 NoActivate")
        ToolbarVisible := true
    }
}

SwitchLanguage() {
    Send("#{Space}")
    SetStatus("Language switched")
}

TranslateSelection() {
    txt := GetSelectedText()
    if (txt = "") {
        SetStatus("Select text first")
        return
    }

    SetStatus("Translating...")
    result := RunHelper("translate", txt)

    if (SubStr(result, 1, 10) = "__ERROR__:") {
        SetStatus("Translation failed")
        MsgBox(SubStr(result, 11), "One-Click Language")
        return
    }

    if (result = "") {
        SetStatus("No translation returned")
        return
    }

    ReplaceSelection(result)
    SetStatus("Translated and replaced")
}

SmartFixSelection() {
    txt := GetSelectedText()
    if (txt = "") {
        SetStatus("Select text first")
        return
    }

    SetStatus("Checking spelling & grammar...")
    result := RunHelper("fix", txt)

    if (SubStr(result, 1, 10) = "__ERROR__:") {
        SetStatus("Smart Fix failed")
        MsgBox(SubStr(result, 11), "One-Click Language")
        return
    }

    if (result = "") {
        SetStatus("No corrected text returned")
        return
    }

    ReplaceSelection(result)
    SetStatus("Corrected and replaced")
}

GetSelectedText() {
    if !FocusPreviousWindow()
        return ""

    saved := ClipboardAll()
    A_Clipboard := ""
    Send("^c")

    if !ClipWait(1.2) {
        A_Clipboard := saved
        return ""
    }

    txt := A_Clipboard
    A_Clipboard := saved
    return txt
}

ReplaceSelection(newText) {
    FocusPreviousWindow()
    saved := ClipboardAll()
    A_Clipboard := newText
    ClipWait(0.5)
    Send("^v")
    Sleep 120
    A_Clipboard := saved
}

RunHelper(mode, txt) {
    stamp := A_TickCount
    inputFile := A_Temp "\ocl_input_" stamp ".txt"
    outputFile := A_Temp "\ocl_output_" stamp ".txt"
    scriptFile := A_Temp "\ocl_helper_" stamp ".ps1"

    try {
        FileAppend(txt, inputFile, "UTF-8")

        ps := "
(
param(
    [Parameter(Mandatory=$true)][string]$Mode,
    [Parameter(Mandatory=$true)][string]$InputFile,
    [Parameter(Mandatory=$true)][string]$OutputFile
)
$ErrorActionPreference='Stop'

function Write-Result([string]$Text) {
    [System.IO.File]::WriteAllText($OutputFile,$Text,[System.Text.UTF8Encoding]::new($false))
}
function Has-Arabic([string]$Text) {
    return [regex]::IsMatch($Text,'[\u0600-\u06FF]')
}
function Translate-Text([string]$Text) {
    $target = if (Has-Arabic $Text) { 'en' } else { 'ar' }
    $encoded = [System.Uri]::EscapeDataString($Text)
    $uri = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=' + $target + '&dt=t&q=' + $encoded
    $r = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 20
    if ($null -eq $r -or $null -eq $r[0]) { throw 'Empty translation response.' }
    $parts = foreach($p in $r[0]) {
        if ($null -ne $p -and $p.Count -gt 0 -and $null -ne $p[0]) { [string]$p[0] }
    }
    return ($parts -join '')
}
function Fix-Text([string]$Text) {
    $body = @{ text=$Text; language='auto' }
    $r = Invoke-RestMethod -Uri 'https://api.languagetool.org/v2/check' -Method Post -ContentType 'application/x-www-form-urlencoded' -Body $body -TimeoutSec 20
    $fixed = $Text
    $matches = @($r.matches) | Sort-Object -Property offset -Descending
    foreach($m in $matches) {
        if ($null -eq $m.replacements -or $m.replacements.Count -eq 0) { continue }
        $off=[int]$m.offset
        $len=[int]$m.length
        $rep=[string]$m.replacements[0].value
        if ($off -ge 0 -and $len -ge 0 -and ($off+$len) -le $fixed.Length) {
            $fixed=$fixed.Remove($off,$len).Insert($off,$rep)
        }
    }
    $fixed=[regex]::Replace($fixed,'[ \t]+',' ')
    $fixed=[regex]::Replace($fixed,'\s+([,.;:!?،؛])','$1')
    $fixed=[regex]::Replace($fixed,'([,.;:!?،؛])([^\s\r\n])','$1 $2')
    return $fixed.Trim()
}
try {
    $text=[System.IO.File]::ReadAllText($InputFile,[System.Text.Encoding]::UTF8)
    if ([string]::IsNullOrWhiteSpace($text)) { Write-Result ''; exit 0 }
    if ($Mode -eq 'translate') { Write-Result (Translate-Text $text) }
    elseif ($Mode -eq 'fix') { Write-Result (Fix-Text $text) }
    else { throw 'Unknown mode.' }
    exit 0
} catch {
    Write-Result ('__ERROR__:' + $_.Exception.Message)
    exit 1
}
)"
        FileAppend(ps, scriptFile, "UTF-8")

        q := Chr(34)
        cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File "
            . q scriptFile q
            . " -Mode " q mode q
            . " -InputFile " q inputFile q
            . " -OutputFile " q outputFile q

        exitCode := RunWait(cmd, , "Hide")

        if !FileExist(outputFile)
            return "__ERROR__:No result was returned. Windows PowerShell may be blocked."

        result := FileRead(outputFile, "UTF-8")

        try FileDelete(inputFile)
        try FileDelete(outputFile)
        try FileDelete(scriptFile)

        if (exitCode != 0 && SubStr(result, 1, 10) != "__ERROR__:")
            return "__ERROR__:PowerShell failed with exit code " exitCode "."

        return result
    } catch as err {
        try FileDelete(inputFile)
        try FileDelete(outputFile)
        try FileDelete(scriptFile)
        return "__ERROR__:" err.Message
    }
}

SetStatus(message) {
    global StatusText
    StatusText.Text := message
}

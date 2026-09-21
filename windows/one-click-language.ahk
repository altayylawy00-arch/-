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
    helper := A_ScriptDir "\language-helper.ps1"
    if !FileExist(helper)
        return "__ERROR__:Missing language-helper.ps1 in the same folder."

    stamp := A_TickCount
    inputFile := A_Temp "\ocl_input_" stamp ".txt"
    outputFile := A_Temp "\ocl_output_" stamp ".txt"

    try {
        FileAppend(txt, inputFile, "UTF-8")

        q := Chr(34)
        cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File "
            . q helper q
            . " -Mode " q mode q
            . " -InputFile " q inputFile q
            . " -OutputFile " q outputFile q

        exitCode := RunWait(cmd, , "Hide")

        if !FileExist(outputFile)
            return "__ERROR__:The helper did not return a result."

        result := FileRead(outputFile, "UTF-8")

        try FileDelete(inputFile)
        try FileDelete(outputFile)

        if (exitCode != 0 && SubStr(result, 1, 10) != "__ERROR__:")
            return "__ERROR__:PowerShell helper failed with exit code " exitCode "."

        return result
    } catch as err {
        try FileDelete(inputFile)
        try FileDelete(outputFile)
        return "__ERROR__:" err.Message
    }
}

SetStatus(message) {
    global StatusText
    StatusText.Text := message
}

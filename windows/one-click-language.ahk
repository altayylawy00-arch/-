#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

global Toolbar := Gui("+AlwaysOnTop +ToolWindow", "One-Click Language")
global LastExternalWindow := 0
global ToolbarVisible := true
global StatusText := ""

Toolbar.SetFont("s10", "Segoe UI")
Toolbar.MarginX := 10
Toolbar.MarginY := 10

btnSwitch := Toolbar.AddButton("w110 h34", "AR ⇄ EN")
btnTranslate := Toolbar.AddButton("x+8 w125 h34", "Translate")
btnCheck := Toolbar.AddButton("x+8 w125 h34", "Check Writing")
btnSettings := Toolbar.AddButton("x+8 w125 h34", "Typing Settings")
StatusText := Toolbar.AddText("xm y+8 w500", "Ready — stable mode")

btnSwitch.OnEvent("Click", (*) => SwitchLanguage())
btnTranslate.OnEvent("Click", (*) => TriggerDeepL())
btnCheck.OnEvent("Click", (*) => TriggerLanguageTool())
btnSettings.OnEvent("Click", (*) => Run("ms-settings:typing"))

Toolbar.Show("AutoSize x20 y20 NoActivate")
SetTimer(TrackActiveWindow, 150)

CapsLock::SwitchLanguage()
F8::ToggleToolbar()
F9::TriggerDeepL()
F10::TriggerLanguageTool()

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
    SetStatus("Keyboard language switched")
}

TriggerDeepL() {
    if !FocusPreviousWindow() {
        SetStatus("No active text window found")
        return
    }

    ; Official DeepL browser extension shortcut on Windows.
    ; Install DeepL in the browser once, then select text and use this button/F9.
    Send("^+y")
    SetStatus("DeepL triggered")
}

TriggerLanguageTool() {
    if !FocusPreviousWindow() {
        SetStatus("No active text window found")
        return
    }

    ; LanguageTool supports a configurable browser shortcut.
    ; Configure it once as Ctrl+Shift+Space in LanguageTool settings.
    Send("^+{Space}")
    SetStatus("LanguageTool check triggered")
}

SetStatus(message) {
    global StatusText
    StatusText.Text := message
}

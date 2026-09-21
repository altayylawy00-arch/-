#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; One-Click Language — Windows helper
; Caps Lock = switch Windows keyboard language (AR <-> EN)
; Floating toolbar = switch / translate selected text / quick-fix selected text

global Toolbar := Gui("+AlwaysOnTop +ToolWindow", "One-Click Language")
Toolbar.SetFont("s10", "Segoe UI")
Toolbar.MarginX := 10
Toolbar.MarginY := 10

btnSwitch := Toolbar.AddButton("w110 h34", "AR ⇄ EN")
btnTranslate := Toolbar.AddButton("x+8 w110 h34", "Translate")
btnFix := Toolbar.AddButton("x+8 w110 h34", "Quick Fix")
btnSettings := Toolbar.AddButton("x+8 w110 h34", "Typing Settings")

btnSwitch.OnEvent("Click", (*) => SwitchLanguage())
btnTranslate.OnEvent("Click", (*) => TranslateSelection())
btnFix.OnEvent("Click", (*) => QuickFixSelection())
btnSettings.OnEvent("Click", (*) => Run("ms-settings:typing"))

Toolbar.Show("AutoSize x20 y20 NoActivate")

CapsLock::{
    SwitchLanguage()
}

SwitchLanguage() {
    ; Windows officially uses Win+Space to cycle installed input languages.
    Send "#{Space}"
    ShowTip("Language switched")
}

TranslateSelection() {
    txt := GetSelectedText()
    if (txt = "") {
        ShowTip("Select some text first")
        return
    }

    target := HasArabic(txt) ? "en" : "ar"
    url := "https://translate.google.com/?sl=auto&tl=" target "&text=" UrlEncode(txt) "&op=translate"
    Run(url)
    ShowTip(target = "en" ? "Opening English translation" : "Opening Arabic translation")
}

QuickFixSelection() {
    txt := GetSelectedText()
    if (txt = "") {
        ShowTip("Select some text first")
        return
    }

    fixed := txt
    fixed := RegExReplace(fixed, "[ \t]+", " ")
    fixed := RegExReplace(fixed, "\s+([,.;:!?،؛])", "$1")
    fixed := RegExReplace(fixed, "([,.;:!?،؛])([^\s\r\n])", "$1 $2")
    fixed := RegExReplace(fixed, "(\r?\n){3,}", "`n`n")
    fixed := Trim(fixed)

    ReplaceSelection(fixed)
    ShowTip("Quick formatting fixed")
}

GetSelectedText() {
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"

    if !ClipWait(0.8) {
        A_Clipboard := saved
        return ""
    }

    txt := A_Clipboard
    A_Clipboard := saved
    return txt
}

ReplaceSelection(newText) {
    saved := ClipboardAll()
    A_Clipboard := newText
    ClipWait(0.5)
    Send "^v"
    Sleep 80
    A_Clipboard := saved
}

HasArabic(txt) {
    return RegExMatch(txt, "[\x{0600}-\x{06FF}]")
}

UrlEncode(str) {
    size := StrPut(str, "UTF-8")
    buf := Buffer(size)
    StrPut(str, buf, "UTF-8")

    out := ""
    Loop size - 1 {
        b := NumGet(buf, A_Index - 1, "UChar")

        if (
            (b >= 0x30 && b <= 0x39)
            || (b >= 0x41 && b <= 0x5A)
            || (b >= 0x61 && b <= 0x7A)
            || b = 0x2D
            || b = 0x2E
            || b = 0x5F
            || b = 0x7E
        ) {
            out .= Chr(b)
        } else {
            out .= "%" Format("{:02X}", b)
        }
    }

    return out
}

ShowTip(message) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -1200)
}

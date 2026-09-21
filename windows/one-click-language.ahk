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
SetStatus("Ready v3.2 — Translate + Smart Fix")
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

global EngineBase64 := "cGFyYW0oCiAgICBbUGFyYW1ldGVyKE1hbmRhdG9yeT0kdHJ1ZSldW1ZhbGlkYXRlU2V0KCJ0cmFuc2xhdGUiLCJmaXgiKV1bc3RyaW5nXSRNb2RlLAogICAgW1BhcmFtZXRlcihNYW5kYXRvcnk9JHRydWUpXVtzdHJpbmddJElucHV0RmlsZSwKICAgIFtQYXJhbWV0ZXIoTWFuZGF0b3J5PSR0cnVlKV1bc3RyaW5nXSRPdXRwdXRGaWxlCikKCiRFcnJvckFjdGlvblByZWZlcmVuY2UgPSAiU3RvcCIKCmZ1bmN0aW9uIFdyaXRlLVJlc3VsdChbc3RyaW5nXSRUZXh0KSB7CiAgICBbU3lzdGVtLklPLkZpbGVdOjpXcml0ZUFsbFRleHQoJE91dHB1dEZpbGUsJFRleHQsW1N5c3RlbS5UZXh0LlVURjhFbmNvZGluZ106Om5ldygkZmFsc2UpKQp9CgpmdW5jdGlvbiBIYXMtQXJhYmljKFtzdHJpbmddJFRleHQpIHsKICAgIHJldHVybiBbcmVnZXhdOjpJc01hdGNoKCRUZXh0LCdbXHUwNjAwLVx1MDZGRl0nKQp9CgpmdW5jdGlvbiBJbnZva2UtVHJhbnNsYXRpb24oW3N0cmluZ10kVGV4dCkgewogICAgJHNvdXJjZSA9IGlmIChIYXMtQXJhYmljICRUZXh0KSB7ICJhciIgfSBlbHNlIHsgImVuIiB9CiAgICAkdGFyZ2V0ID0gaWYgKCRzb3VyY2UgLWVxICJhciIpIHsgImVuIiB9IGVsc2UgeyAiYXIiIH0KICAgICRlbmNvZGVkID0gW1N5c3RlbS5VcmldOjpFc2NhcGVEYXRhU3RyaW5nKCRUZXh0KQogICAgJGhlYWRlcnMgPSBAeyAiVXNlci1BZ2VudCIgPSAiTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgT25lQ2xpY2tMYW5ndWFnZS8zLjIiIH0KICAgICRlcnJvcnMgPSBAKCkKCiAgICAjIFByaW1hcnk6IHRoZSBDaHJvbWUgZGljdGlvbmFyeSB0cmFuc2xhdGlvbiBlbmRwb2ludC4KICAgICMgVGhpcyBpcyBkaWZmZXJlbnQgZnJvbSB0aGUgdHJhbnNsYXRlLmdvb2dsZWFwaXMuY29tIGVuZHBvaW50IHRoYXQgcmV0dXJuZWQgNDI5LgogICAgdHJ5IHsKICAgICAgICAkdXJpID0gImh0dHBzOi8vY2xpZW50czUuZ29vZ2xlLmNvbS90cmFuc2xhdGVfYS90P2NsaWVudD1kaWN0LWNocm9tZS1leCZzbD0kc291cmNlJnRsPSR0YXJnZXQmcT0kZW5jb2RlZCIKICAgICAgICAkciA9IEludm9rZS1SZXN0TWV0aG9kIC1VcmkgJHVyaSAtTWV0aG9kIEdldCAtSGVhZGVycyAkaGVhZGVycyAtVGltZW91dFNlYyAyMAogICAgICAgICRjYW5kaWRhdGUgPSBpZiAoJHIgLWlzIFtTeXN0ZW0uQXJyYXldIC1hbmQgJHIuQ291bnQgLWd0IDApIHsgW3N0cmluZ10kclswXSB9IGVsc2UgeyBbc3RyaW5nXSRyIH0KICAgICAgICBpZiAoLW5vdCBbc3RyaW5nXTo6SXNOdWxsT3JXaGl0ZVNwYWNlKCRjYW5kaWRhdGUpKSB7CiAgICAgICAgICAgICRjYW5kaWRhdGUgPSAkY2FuZGlkYXRlLlRyaW0oKQogICAgICAgICAgICBpZiAoKCR0YXJnZXQgLWVxICJhciIgLWFuZCAoSGFzLUFyYWJpYyAkY2FuZGlkYXRlKSkgLW9yCiAgICAgICAgICAgICAgICAoJHRhcmdldCAtZXEgImVuIiAtYW5kIFtyZWdleF06OklzTWF0Y2goJGNhbmRpZGF0ZSwnW0EtWmEtel0nKSkpIHsKICAgICAgICAgICAgICAgIHJldHVybiAkY2FuZGlkYXRlCiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICAgICAgJGVycm9ycyArPSAiUHJpbWFyeSB0cmFuc2xhdGlvbiByZXR1cm5lZCBubyB1c2FibGUgcmVzdWx0LiIKICAgIH0gY2F0Y2ggewogICAgICAgICRlcnJvcnMgKz0gIlByaW1hcnkgdHJhbnNsYXRpb246ICIgKyAkXy5FeGNlcHRpb24uTWVzc2FnZQogICAgfQoKICAgICMgRmFsbGJhY2sgMTogTGluZ3ZhLgogICAgdHJ5IHsKICAgICAgICAkdXJpID0gImh0dHBzOi8vbGluZ3ZhLm1sL2FwaS92MS8kc291cmNlLyR0YXJnZXQvJGVuY29kZWQiCiAgICAgICAgJHIgPSBJbnZva2UtUmVzdE1ldGhvZCAtVXJpICR1cmkgLU1ldGhvZCBHZXQgLUhlYWRlcnMgJGhlYWRlcnMgLVRpbWVvdXRTZWMgMjAKICAgICAgICAkY2FuZGlkYXRlID0gW3N0cmluZ10kci50cmFuc2xhdGlvbgogICAgICAgIGlmICgtbm90IFtzdHJpbmddOjpJc051bGxPcldoaXRlU3BhY2UoJGNhbmRpZGF0ZSkpIHsKICAgICAgICAgICAgJGNhbmRpZGF0ZSA9ICRjYW5kaWRhdGUuVHJpbSgpCiAgICAgICAgICAgIGlmICgoJHRhcmdldCAtZXEgImFyIiAtYW5kIChIYXMtQXJhYmljICRjYW5kaWRhdGUpKSAtb3IKICAgICAgICAgICAgICAgICgkdGFyZ2V0IC1lcSAiZW4iIC1hbmQgW3JlZ2V4XTo6SXNNYXRjaCgkY2FuZGlkYXRlLCdbQS1aYS16XScpKSkgewogICAgICAgICAgICAgICAgcmV0dXJuICRjYW5kaWRhdGUKICAgICAgICAgICAgfQogICAgICAgIH0KICAgICAgICAkZXJyb3JzICs9ICJMaW5ndmEgcmV0dXJuZWQgbm8gdXNhYmxlIHRyYW5zbGF0aW9uLiIKICAgIH0gY2F0Y2ggewogICAgICAgICRlcnJvcnMgKz0gIkxpbmd2YTogIiArICRfLkV4Y2VwdGlvbi5NZXNzYWdlCiAgICB9CgogICAgIyBGYWxsYmFjayAyOiBNeU1lbW9yeSBtYWNoaW5lIHRyYW5zbGF0aW9uLgogICAgdHJ5IHsKICAgICAgICAkdXJpID0gImh0dHBzOi8vYXBpLm15bWVtb3J5LnRyYW5zbGF0ZWQubmV0L2dldD9xPSRlbmNvZGVkJmxhbmdwYWlyPSRzb3VyY2UlN0MkdGFyZ2V0Jm10PTEiCiAgICAgICAgJHIgPSBJbnZva2UtUmVzdE1ldGhvZCAtVXJpICR1cmkgLU1ldGhvZCBHZXQgLUhlYWRlcnMgJGhlYWRlcnMgLVRpbWVvdXRTZWMgMjAKICAgICAgICAkY2FuZGlkYXRlID0gW3N0cmluZ10kci5yZXNwb25zZURhdGEudHJhbnNsYXRlZFRleHQKICAgICAgICBpZiAoJHIucmVzcG9uc2VTdGF0dXMgLWVxIDIwMCAtYW5kIC1ub3QgW3N0cmluZ106OklzTnVsbE9yV2hpdGVTcGFjZSgkY2FuZGlkYXRlKSkgewogICAgICAgICAgICAkY2FuZGlkYXRlID0gW1N5c3RlbS5OZXQuV2ViVXRpbGl0eV06Okh0bWxEZWNvZGUoJGNhbmRpZGF0ZSkuVHJpbSgpCiAgICAgICAgICAgIGlmICgkY2FuZGlkYXRlIC1uZSAkVGV4dC5UcmltKCkgLWFuZAogICAgICAgICAgICAgICAgKCgkdGFyZ2V0IC1lcSAiYXIiIC1hbmQgKEhhcy1BcmFiaWMgJGNhbmRpZGF0ZSkpIC1vcgogICAgICAgICAgICAgICAgICgkdGFyZ2V0IC1lcSAiZW4iIC1hbmQgW3JlZ2V4XTo6SXNNYXRjaCgkY2FuZGlkYXRlLCdbQS1aYS16XScpKSkpIHsKICAgICAgICAgICAgICAgIHJldHVybiAkY2FuZGlkYXRlCiAgICAgICAgICAgIH0KICAgICAgICB9CiAgICAgICAgJGVycm9ycyArPSAiTXlNZW1vcnkgcmV0dXJuZWQgbm8gdXNhYmxlIHRyYW5zbGF0aW9uLiIKICAgIH0gY2F0Y2ggewogICAgICAgICRlcnJvcnMgKz0gIk15TWVtb3J5OiAiICsgJF8uRXhjZXB0aW9uLk1lc3NhZ2UKICAgIH0KCiAgICB0aHJvdyAoIlRyYW5zbGF0aW9uIHNlcnZpY2VzIGFyZSB1bmF2YWlsYWJsZSByaWdodCBub3cuICIgKyAoJGVycm9ycyAtam9pbiAiIHwgIikpCn0KCmZ1bmN0aW9uIFJlcGxhY2UtV29yZChbc3RyaW5nXSRUZXh0LFtzdHJpbmddJEJhZCxbc3RyaW5nXSRHb29kLFtib29sXSRJZ25vcmVDYXNlPSRmYWxzZSkgewogICAgJHBhdHRlcm4gPSAnKD88IVtccHtMfVxwe019XSknICsgW3JlZ2V4XTo6RXNjYXBlKCRCYWQpICsgJyg/IVtccHtMfVxwe019XSknCiAgICAkb3B0aW9ucyA9IGlmICgkSWdub3JlQ2FzZSkgeyBbU3lzdGVtLlRleHQuUmVndWxhckV4cHJlc3Npb25zLlJlZ2V4T3B0aW9uc106Oklnbm9yZUNhc2UgfSBlbHNlIHsgW1N5c3RlbS5UZXh0LlJlZ3VsYXJFeHByZXNzaW9ucy5SZWdleE9wdGlvbnNdOjpOb25lIH0KICAgIHJldHVybiBbcmVnZXhdOjpSZXBsYWNlKCRUZXh0LCRwYXR0ZXJuLFtTeXN0ZW0uVGV4dC5SZWd1bGFyRXhwcmVzc2lvbnMuTWF0Y2hFdmFsdWF0b3JdeyBwYXJhbSgkbSkgJEdvb2QgfSwkb3B0aW9ucykKfQoKZnVuY3Rpb24gR2V0LUxldmVuc2h0ZWluKFtzdHJpbmddJEEsW3N0cmluZ10kQikgewogICAgaWYgKCRBIC1lcSAkQikgeyByZXR1cm4gMCB9CiAgICBpZiAoJEEuTGVuZ3RoIC1lcSAwKSB7IHJldHVybiAkQi5MZW5ndGggfQogICAgaWYgKCRCLkxlbmd0aCAtZXEgMCkgeyByZXR1cm4gJEEuTGVuZ3RoIH0KCiAgICAkcHJldiA9IE5ldy1PYmplY3QgJ2ludFtdJyAoJEIuTGVuZ3RoICsgMSkKICAgICRjdXJyID0gTmV3LU9iamVjdCAnaW50W10nICgkQi5MZW5ndGggKyAxKQogICAgZm9yICgkaj0wOyAkaiAtbGUgJEIuTGVuZ3RoOyAkaisrKSB7ICRwcmV2WyRqXSA9ICRqIH0KCiAgICBmb3IgKCRpPTE7ICRpIC1sZSAkQS5MZW5ndGg7ICRpKyspIHsKICAgICAgICAkY3VyclswXSA9ICRpCiAgICAgICAgZm9yICgkaj0xOyAkaiAtbGUgJEIuTGVuZ3RoOyAkaisrKSB7CiAgICAgICAgICAgICRjb3N0ID0gaWYgKCRBWyRpLTFdIC1lcSAkQlskai0xXSkgeyAwIH0gZWxzZSB7IDEgfQogICAgICAgICAgICAkY3Vyclskal0gPSBbTWF0aF06Ok1pbihbTWF0aF06Ok1pbigkY3Vyclskai0xXSArIDEsJHByZXZbJGpdICsgMSksJHByZXZbJGotMV0gKyAkY29zdCkKICAgICAgICB9CiAgICAgICAgJHRtcD0kcHJldjsgJHByZXY9JGN1cnI7ICRjdXJyPSR0bXAKICAgIH0KICAgIHJldHVybiAkcHJldlskQi5MZW5ndGhdCn0KCmZ1bmN0aW9uIEludm9rZS1XaW5kb3dzU3BlbGxGaXgoW3N0cmluZ10kVGV4dCxbc3RyaW5nXSRMYW5ndWFnZVRhZykgewogICAgdHJ5IHsKICAgICAgICBBZGQtVHlwZSAtQXNzZW1ibHlOYW1lIFByZXNlbnRhdGlvbkZyYW1ld29yayAtRXJyb3JBY3Rpb24gU3RvcAogICAgICAgICR0YiA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuQ29udHJvbHMuVGV4dEJveAogICAgICAgICR0Yi5MYW5ndWFnZSA9IFtTeXN0ZW0uV2luZG93cy5NYXJrdXAuWG1sTGFuZ3VhZ2VdOjpHZXRMYW5ndWFnZSgkTGFuZ3VhZ2VUYWcpCiAgICAgICAgW1N5c3RlbS5XaW5kb3dzLkNvbnRyb2xzLlNwZWxsQ2hlY2tdOjpTZXRJc0VuYWJsZWQoJHRiLCR0cnVlKQogICAgICAgICR0Yi5UZXh0ID0gJFRleHQKICAgICAgICAkdGIuVXBkYXRlTGF5b3V0KCkKCiAgICAgICAgJHJlcGFpcnMgPSBAKCkKICAgICAgICAkaWR4ID0gMAogICAgICAgIHdoaWxlICgkaWR4IC1sdCAkdGIuVGV4dC5MZW5ndGgpIHsKICAgICAgICAgICAgJGVyckluZGV4ID0gJHRiLkdldE5leHRTcGVsbGluZ0Vycm9yQ2hhcmFjdGVySW5kZXgoJGlkeCxbU3lzdGVtLldpbmRvd3MuRG9jdW1lbnRzLkxvZ2ljYWxEaXJlY3Rpb25dOjpGb3J3YXJkKQogICAgICAgICAgICBpZiAoJGVyckluZGV4IC1sdCAwKSB7IGJyZWFrIH0KCiAgICAgICAgICAgICRsZW4gPSAkdGIuR2V0U3BlbGxpbmdFcnJvckxlbmd0aCgkZXJySW5kZXgpCiAgICAgICAgICAgIGlmICgkbGVuIC1sZSAwKSB7ICRpZHggPSAkZXJySW5kZXggKyAxOyBjb250aW51ZSB9CgogICAgICAgICAgICAkZXJyb3IgPSAkdGIuR2V0U3BlbGxpbmdFcnJvcigkZXJySW5kZXgpCiAgICAgICAgICAgICRzdWdnZXN0aW9ucyA9IEAoJGVycm9yLlN1Z2dlc3Rpb25zKQogICAgICAgICAgICBpZiAoJHN1Z2dlc3Rpb25zLkNvdW50IC1ndCAwKSB7CiAgICAgICAgICAgICAgICAkb3JpZ2luYWwgPSAkdGIuVGV4dC5TdWJzdHJpbmcoJGVyckluZGV4LCRsZW4pCiAgICAgICAgICAgICAgICAkc3VnZ2VzdGlvbiA9IFtzdHJpbmddJHN1Z2dlc3Rpb25zWzBdCiAgICAgICAgICAgICAgICAkZGlzdGFuY2UgPSBHZXQtTGV2ZW5zaHRlaW4gJG9yaWdpbmFsLlRvTG93ZXJJbnZhcmlhbnQoKSAkc3VnZ2VzdGlvbi5Ub0xvd2VySW52YXJpYW50KCkKICAgICAgICAgICAgICAgICRsaW1pdCA9IGlmICgkb3JpZ2luYWwuTGVuZ3RoIC1sZSA0KSB7IDEgfSBlbHNlaWYgKCRvcmlnaW5hbC5MZW5ndGggLWxlIDgpIHsgMiB9IGVsc2UgeyAzIH0KCiAgICAgICAgICAgICAgICBpZiAoJGRpc3RhbmNlIC1sZSAkbGltaXQgLWFuZCAkc3VnZ2VzdGlvbi5MZW5ndGggLWd0IDApIHsKICAgICAgICAgICAgICAgICAgICAkcmVwYWlycyArPSBbcHNjdXN0b21vYmplY3RdQHsgU3RhcnQ9JGVyckluZGV4OyBMZW5ndGg9JGxlbjsgVGV4dD0kc3VnZ2VzdGlvbiB9CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICAgICAgJGlkeCA9ICRlcnJJbmRleCArIFtNYXRoXTo6TWF4KCRsZW4sMSkKICAgICAgICB9CgogICAgICAgICRmaXhlZCA9ICRUZXh0CiAgICAgICAgZm9yZWFjaCAoJHIgaW4gKCRyZXBhaXJzIHwgU29ydC1PYmplY3QgU3RhcnQgLURlc2NlbmRpbmcpKSB7CiAgICAgICAgICAgICRmaXhlZCA9ICRmaXhlZC5SZW1vdmUoW2ludF0kci5TdGFydCxbaW50XSRyLkxlbmd0aCkuSW5zZXJ0KFtpbnRdJHIuU3RhcnQsW3N0cmluZ10kci5UZXh0KQogICAgICAgIH0KICAgICAgICByZXR1cm4gJGZpeGVkCiAgICB9IGNhdGNoIHsKICAgICAgICByZXR1cm4gJFRleHQKICAgIH0KfQoKZnVuY3Rpb24gSW52b2tlLUZpeChbc3RyaW5nXSRUZXh0KSB7CiAgICAkZml4ZWQgPSAkVGV4dAoKICAgIGlmIChIYXMtQXJhYmljICRmaXhlZCkgewogICAgICAgICRhcmFiaWMgPSBbb3JkZXJlZF1AewogICAgICAgICAgICAi2YfYp9iw2KciPSLZh9iw2KciOyAi2YfYp9iw2YciPSLZh9iw2YciOyAi2YTYp9mD2YYiPSLZhNmD2YYiOyAi2KfZhNmE2LDZiiI9Itin2YTYsNmKIjsgItin2YTZhNiq2YoiPSLYp9mE2KrZiiI7CiAgICAgICAgICAgICLYrti32KEiPSLYrti32KMiOyAi2KfYrti32KfYoSI9Itij2K7Yt9in2KEiOyAi2KfZhNmJIj0i2KXZhNmJIjsgItin2YTYp9mGIj0i2KfZhNii2YYiOyAi2KfZiti22KciPSLYo9mK2LbZi9inIjsKICAgICAgICAgICAgItmF2LPYp9mE2YciPSLZhdiz2KPZhNipIjsgItmF2LPYptmE2YciPSLZhdiz2KPZhNipIjsgItmF2LPZiNmI2YQiPSLZhdiz2KTZiNmEIjsgItmE2LrZhyI9ItmE2LrYqSI7ICLZg9mE2YXZhyI9ItmD2YTZhdipIjsKICAgICAgICAgICAgItmH2YbYp9in2YMiPSLZh9mG2KfZgyI7ICLZh9mG2KfYpyI9ItmH2YbYpyI7ICLZhdi02YPZhNmHIj0i2YXYtNmD2YTYqSI7ICLYt9ix2YrZgtmHIj0i2LfYsdmK2YLYqSI7ICLYqtix2KzZhdmHIj0i2KrYsdis2YXYqSI7CiAgICAgICAgICAgICLYp9mG2LTYp9ih2KfZhNmE2YciPSLYpdmGINi02KfYoSDYp9mE2YTZhyI7ICLYtNin2KHYp9mE2YTZhyI9Iti02KfYoSDYp9mE2YTZhyIKICAgICAgICB9CiAgICAgICAgZm9yZWFjaCAoJGsgaW4gJGFyYWJpYy5LZXlzKSB7ICRmaXhlZCA9IFJlcGxhY2UtV29yZCAkZml4ZWQgJGsgJGFyYWJpY1ska10gJGZhbHNlIH0KCiAgICAgICAgJGJlZm9yZSA9ICRmaXhlZAogICAgICAgICRmaXhlZCA9IEludm9rZS1XaW5kb3dzU3BlbGxGaXggJGZpeGVkICJhci1JUSIKICAgICAgICBpZiAoJGZpeGVkIC1lcSAkYmVmb3JlKSB7ICRmaXhlZCA9IEludm9rZS1XaW5kb3dzU3BlbGxGaXggJGZpeGVkICJhci1TQSIgfQogICAgfSBlbHNlIHsKICAgICAgICAkZW5nbGlzaCA9IFtvcmRlcmVkXUB7CiAgICAgICAgICAgICJ0ZWgiPSJ0aGUiOyAiZnJlbmQiPSJmcmllbmQiOyAiZnJlaW5kIj0iZnJpZW5kIjsgInJlY2lldmUiPSJyZWNlaXZlIjsgImFkcmVzcyI9ImFkZHJlc3MiOwogICAgICAgICAgICAiYmVjdWFzZSI9ImJlY2F1c2UiOyAibGFuZ2F1Z2UiPSJsYW5ndWFnZSI7ICJlbmdsaWgiPSJlbmdsaXNoIjsgInRyYW5zYWx0ZSI9InRyYW5zbGF0ZSI7CiAgICAgICAgICAgICJ0cmFuc2x0ZSI9InRyYW5zbGF0ZSI7ICJ0aGllciI9InRoZWlyIjsgIndpZXJkIj0id2VpcmQiOyAic2VwZXJhdGUiPSJzZXBhcmF0ZSI7CiAgICAgICAgICAgICJkZWZpbmF0ZWx5Ij0iZGVmaW5pdGVseSI7ICJvY2N1cmVkIj0ib2NjdXJyZWQiOyAidW50aWxsIj0idW50aWwiOyAid2ljaCI9IndoaWNoIgogICAgICAgIH0KICAgICAgICBmb3JlYWNoICgkayBpbiAkZW5nbGlzaC5LZXlzKSB7ICRmaXhlZCA9IFJlcGxhY2UtV29yZCAkZml4ZWQgJGsgJGVuZ2xpc2hbJGtdICR0cnVlIH0KCiAgICAgICAgJGZpeGVkID0gSW52b2tlLVdpbmRvd3NTcGVsbEZpeCAkZml4ZWQgImVuLVVTIgogICAgICAgICRmaXhlZCA9IFtyZWdleF06OlJlcGxhY2UoJGZpeGVkLCcoP2kpXGJJXHMraGFzXGInLCdJIGhhdmUnKQogICAgICAgICRmaXhlZCA9IFtyZWdleF06OlJlcGxhY2UoJGZpeGVkLCcoP2kpXGJ5b3Vccytpc1xiJywneW91IGFyZScpCiAgICAgICAgJGZpeGVkID0gW3JlZ2V4XTo6UmVwbGFjZSgkZml4ZWQsJyg/aSlcYnRoZXlccytpc1xiJywndGhleSBhcmUnKQogICAgICAgICRmaXhlZCA9IFtyZWdleF06OlJlcGxhY2UoJGZpeGVkLCcoP2kpXGJoZVxzK2hhdmVcYicsJ2hlIGhhcycpCiAgICAgICAgJGZpeGVkID0gW3JlZ2V4XTo6UmVwbGFjZSgkZml4ZWQsJyg/aSlcYnNoZVxzK2hhdmVcYicsJ3NoZSBoYXMnKQogICAgfQoKICAgICRmaXhlZCA9IFtyZWdleF06OlJlcGxhY2UoJGZpeGVkLCdbIFx0XSsnLCcgJykKICAgICRmaXhlZCA9IFtyZWdleF06OlJlcGxhY2UoJGZpeGVkLCdccysoWywuOzohP9iM2JtdKScsJyQxJykKICAgICRmaXhlZCA9IFtyZWdleF06OlJlcGxhY2UoJGZpeGVkLCcoWywuOzohP9iM2JtdKShbXlxzXHJcbl0pJywnJDEgJDInKQogICAgJGZpeGVkID0gW3JlZ2V4XTo6UmVwbGFjZSgkZml4ZWQsJyhccj9cbil7Myx9JywoW0Vudmlyb25tZW50XTo6TmV3TGluZSArIFtFbnZpcm9ubWVudF06Ok5ld0xpbmUpKQogICAgcmV0dXJuICRmaXhlZC5UcmltKCkKfQoKdHJ5IHsKICAgIGlmICgtbm90IChUZXN0LVBhdGggLUxpdGVyYWxQYXRoICRJbnB1dEZpbGUpKSB7IHRocm93ICJJbnB1dCBmaWxlIHdhcyBub3QgZm91bmQuIiB9CiAgICAkdGV4dCA9IFtTeXN0ZW0uSU8uRmlsZV06OlJlYWRBbGxUZXh0KCRJbnB1dEZpbGUsW1N5c3RlbS5UZXh0LkVuY29kaW5nXTo6VVRGOCkKCiAgICBpZiAoW3N0cmluZ106OklzTnVsbE9yV2hpdGVTcGFjZSgkdGV4dCkpIHsKICAgICAgICBXcml0ZS1SZXN1bHQgIiIKICAgICAgICBleGl0IDAKICAgIH0KCiAgICBpZiAoJE1vZGUgLWVxICJ0cmFuc2xhdGUiKSB7IFdyaXRlLVJlc3VsdCAoSW52b2tlLVRyYW5zbGF0aW9uICR0ZXh0KSB9CiAgICBlbHNlIHsgV3JpdGUtUmVzdWx0IChJbnZva2UtRml4ICR0ZXh0KSB9CiAgICBleGl0IDAKfQpjYXRjaCB7CiAgICBXcml0ZS1SZXN1bHQgKCJfX0VSUk9SX186IiArICRfLkV4Y2VwdGlvbi5NZXNzYWdlKQogICAgZXhpdCAxCn0K"

WriteBase64File(base64, path) {
    size := 0
    if !DllCall("Crypt32\\CryptStringToBinaryW", "Str", base64, "UInt", 0, "UInt", 0x1, "Ptr", 0, "UIntP", &size, "Ptr", 0, "Ptr", 0)
        throw Error("Could not decode embedded language engine.")

    buf := Buffer(size)
    if !DllCall("Crypt32\\CryptStringToBinaryW", "Str", base64, "UInt", 0, "UInt", 0x1, "Ptr", buf.Ptr, "UIntP", &size, "Ptr", 0, "Ptr", 0)
        throw Error("Could not decode embedded language engine.")

    f := FileOpen(path, "w")
    bom := Buffer(3)
    NumPut("UChar", 0xEF, bom, 0)
    NumPut("UChar", 0xBB, bom, 1)
    NumPut("UChar", 0xBF, bom, 2)
    f.RawWrite(bom, 3)
    f.RawWrite(buf, size)
    f.Close()
}

RunHelper(mode, txt) {
    global EngineBase64

    stamp := A_TickCount
    inputFile := A_Temp "\\ocl_input_" stamp ".txt"
    outputFile := A_Temp "\\ocl_output_" stamp ".txt"
    scriptFile := A_Temp "\\ocl_engine_" stamp ".ps1"

    try {
        FileAppend(txt, inputFile, "UTF-8")
        WriteBase64File(EngineBase64, scriptFile)

        q := Chr(34)
        cmd := "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "
            . q scriptFile q
            . " -Mode " q mode q
            . " -InputFile " q inputFile q
            . " -OutputFile " q outputFile q

        exitCode := RunWait(cmd, , "Hide")

        if !FileExist(outputFile)
            return "__ERROR__:No result returned. Windows PowerShell may be blocked."

        result := FileRead(outputFile, "UTF-8")

        try FileDelete(inputFile)
        try FileDelete(outputFile)
        try FileDelete(scriptFile)

        if (exitCode != 0 && SubStr(result, 1, 10) != "__ERROR__:")
            return "__ERROR__:Language engine failed with exit code " exitCode "."

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

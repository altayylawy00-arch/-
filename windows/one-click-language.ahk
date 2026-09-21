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
SetStatus("Ready v3.1 — Translate + Smart Fix")
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

global EngineBase64 := "cGFyYW0oCiAgICBbUGFyYW1ldGVyKE1hbmRhdG9yeT0kdHJ1ZSldW1ZhbGlkYXRlU2V0KCJ0cmFuc2xhdGUiLCJmaXgiKV1bc3RyaW5nXSRNb2RlLAogICAgW1BhcmFtZXRlcihNYW5kYXRvcnk9JHRydWUpXVtzdHJpbmddJElucHV0RmlsZSwKICAgIFtQYXJhbWV0ZXIoTWFuZGF0b3J5PSR0cnVlKV1bc3RyaW5nXSRPdXRwdXRGaWxlCikKCiRFcnJvckFjdGlvblByZWZlcmVuY2UgPSAiU3RvcCIKCmZ1bmN0aW9uIFdyaXRlLVJlc3VsdChbc3RyaW5nXSRUZXh0KSB7CiAgICBbU3lzdGVtLklPLkZpbGVdOjpXcml0ZUFsbFRleHQoJE91dHB1dEZpbGUsJFRleHQsW1N5c3RlbS5UZXh0LlVURjhFbmNvZGluZ106Om5ldygkZmFsc2UpKQp9CgpmdW5jdGlvbiBIYXMtQXJhYmljKFtzdHJpbmddJFRleHQpIHsKICAgIHJldHVybiBbcmVnZXhdOjpJc01hdGNoKCRUZXh0LCdbXHUwNjAwLVx1MDZGRl0nKQp9CgpmdW5jdGlvbiBJbnZva2UtVHJhbnNsYXRpb24oW3N0cmluZ10kVGV4dCkgewogICAgJHNvdXJjZSA9IGlmIChIYXMtQXJhYmljICRUZXh0KSB7ICJhciIgfSBlbHNlIHsgImVuIiB9CiAgICAkdGFyZ2V0ID0gaWYgKCRzb3VyY2UgLWVxICJhciIpIHsgImVuIiB9IGVsc2UgeyAiYXIiIH0KICAgICRlbmNvZGVkID0gW1N5c3RlbS5VcmldOjpFc2NhcGVEYXRhU3RyaW5nKCRUZXh0KQogICAgJGhlYWRlcnMgPSBAeyAiVXNlci1BZ2VudCIgPSAiT25lQ2xpY2tMYW5ndWFnZS8zLjEiIH0KICAgICRlcnJvcnMgPSBAKCkKCiAgICAjIFByaW1hcnk6IExpbmd2YS4gSXQgaXMgdXNlZCBmaXJzdCBiZWNhdXNlIGl0cyBvdXRwdXQgaXMgZ2VuZXJhbGx5CiAgICAjIG1vcmUgc3VpdGFibGUgZm9yIGRpcmVjdCBzZW50ZW5jZSB0cmFuc2xhdGlvbiB0aGFuIHRyYW5zbGF0aW9uLW1lbW9yeSBtYXRjaGVzLgogICAgdHJ5IHsKICAgICAgICAkdXJpID0gImh0dHBzOi8vbGluZ3ZhLm1sL2FwaS92MS8kc291cmNlLyR0YXJnZXQvJGVuY29kZWQiCiAgICAgICAgJHIgPSBJbnZva2UtUmVzdE1ldGhvZCAtVXJpICR1cmkgLU1ldGhvZCBHZXQgLUhlYWRlcnMgJGhlYWRlcnMgLVRpbWVvdXRTZWMgMjAKICAgICAgICAkY2FuZGlkYXRlID0gW3N0cmluZ10kci50cmFuc2xhdGlvbgogICAgICAgIGlmICgtbm90IFtzdHJpbmddOjpJc051bGxPcldoaXRlU3BhY2UoJGNhbmRpZGF0ZSkpIHsKICAgICAgICAgICAgJGNhbmRpZGF0ZSA9ICRjYW5kaWRhdGUuVHJpbSgpCiAgICAgICAgICAgIGlmICgoJHRhcmdldCAtZXEgImFyIiAtYW5kIChIYXMtQXJhYmljICRjYW5kaWRhdGUpKSAtb3IKICAgICAgICAgICAgICAgICgkdGFyZ2V0IC1lcSAiZW4iIC1hbmQgW3JlZ2V4XTo6SXNNYXRjaCgkY2FuZGlkYXRlLCdbQS1aYS16XScpKSkgewogICAgICAgICAgICAgICAgcmV0dXJuICRjYW5kaWRhdGUKICAgICAgICAgICAgfQogICAgICAgIH0KICAgICAgICAkZXJyb3JzICs9ICJMaW5ndmEgcmV0dXJuZWQgbm8gdXNhYmxlIHRyYW5zbGF0aW9uLiIKICAgIH0gY2F0Y2ggewogICAgICAgICRlcnJvcnMgKz0gIkxpbmd2YTogIiArICRfLkV4Y2VwdGlvbi5NZXNzYWdlCiAgICB9CgogICAgIyBGYWxsYmFjazogTXlNZW1vcnkgbWFjaGluZSB0cmFuc2xhdGlvbi4KICAgIHRyeSB7CiAgICAgICAgJHVyaSA9ICJodHRwczovL2FwaS5teW1lbW9yeS50cmFuc2xhdGVkLm5ldC9nZXQ/cT0kZW5jb2RlZCZsYW5ncGFpcj0kc291cmNlJTdDJHRhcmdldCZtdD0xIgogICAgICAgICRyID0gSW52b2tlLVJlc3RNZXRob2QgLVVyaSAkdXJpIC1NZXRob2QgR2V0IC1IZWFkZXJzICRoZWFkZXJzIC1UaW1lb3V0U2VjIDIwCiAgICAgICAgJGNhbmRpZGF0ZSA9IFtzdHJpbmddJHIucmVzcG9uc2VEYXRhLnRyYW5zbGF0ZWRUZXh0CiAgICAgICAgaWYgKCRyLnJlc3BvbnNlU3RhdHVzIC1lcSAyMDAgLWFuZCAtbm90IFtzdHJpbmddOjpJc051bGxPcldoaXRlU3BhY2UoJGNhbmRpZGF0ZSkpIHsKICAgICAgICAgICAgJGNhbmRpZGF0ZSA9IFtTeXN0ZW0uTmV0LldlYlV0aWxpdHldOjpIdG1sRGVjb2RlKCRjYW5kaWRhdGUpLlRyaW0oKQogICAgICAgICAgICBpZiAoJGNhbmRpZGF0ZSAtbmUgJFRleHQuVHJpbSgpIC1hbmQKICAgICAgICAgICAgICAgICgoJHRhcmdldCAtZXEgImFyIiAtYW5kIChIYXMtQXJhYmljICRjYW5kaWRhdGUpKSAtb3IKICAgICAgICAgICAgICAgICAoJHRhcmdldCAtZXEgImVuIiAtYW5kIFtyZWdleF06OklzTWF0Y2goJGNhbmRpZGF0ZSwnW0EtWmEtel0nKSkpKSB7CiAgICAgICAgICAgICAgICByZXR1cm4gJGNhbmRpZGF0ZQogICAgICAgICAgICB9CiAgICAgICAgfQogICAgICAgICRlcnJvcnMgKz0gIk15TWVtb3J5IHJldHVybmVkIG5vIHVzYWJsZSB0cmFuc2xhdGlvbi4iCiAgICB9IGNhdGNoIHsKICAgICAgICAkZXJyb3JzICs9ICJNeU1lbW9yeTogIiArICRfLkV4Y2VwdGlvbi5NZXNzYWdlCiAgICB9CgogICAgdGhyb3cgKCJUcmFuc2xhdGlvbiBzZXJ2aWNlcyBhcmUgdW5hdmFpbGFibGUgcmlnaHQgbm93LiAiICsgKCRlcnJvcnMgLWpvaW4gIiB8ICIpKQp9CgpmdW5jdGlvbiBSZXBsYWNlLVdvcmQoW3N0cmluZ10kVGV4dCxbc3RyaW5nXSRCYWQsW3N0cmluZ10kR29vZCxbYm9vbF0kSWdub3JlQ2FzZT0kZmFsc2UpIHsKICAgICRwYXR0ZXJuID0gJyg/PCFbXHB7TH1ccHtNfV0pJyArIFtyZWdleF06OkVzY2FwZSgkQmFkKSArICcoPyFbXHB7TH1ccHtNfV0pJwogICAgJG9wdGlvbnMgPSBpZiAoJElnbm9yZUNhc2UpIHsgW1N5c3RlbS5UZXh0LlJlZ3VsYXJFeHByZXNzaW9ucy5SZWdleE9wdGlvbnNdOjpJZ25vcmVDYXNlIH0gZWxzZSB7IFtTeXN0ZW0uVGV4dC5SZWd1bGFyRXhwcmVzc2lvbnMuUmVnZXhPcHRpb25zXTo6Tm9uZSB9CiAgICByZXR1cm4gW3JlZ2V4XTo6UmVwbGFjZSgkVGV4dCwkcGF0dGVybixbU3lzdGVtLlRleHQuUmVndWxhckV4cHJlc3Npb25zLk1hdGNoRXZhbHVhdG9yXXsgcGFyYW0oJG0pICRHb29kIH0sJG9wdGlvbnMpCn0KCmZ1bmN0aW9uIEdldC1MZXZlbnNodGVpbihbc3RyaW5nXSRBLFtzdHJpbmddJEIpIHsKICAgIGlmICgkQSAtZXEgJEIpIHsgcmV0dXJuIDAgfQogICAgaWYgKCRBLkxlbmd0aCAtZXEgMCkgeyByZXR1cm4gJEIuTGVuZ3RoIH0KICAgIGlmICgkQi5MZW5ndGggLWVxIDApIHsgcmV0dXJuICRBLkxlbmd0aCB9CgogICAgJHByZXYgPSBOZXctT2JqZWN0ICdpbnRbXScgKCRCLkxlbmd0aCArIDEpCiAgICAkY3VyciA9IE5ldy1PYmplY3QgJ2ludFtdJyAoJEIuTGVuZ3RoICsgMSkKICAgIGZvciAoJGo9MDsgJGogLWxlICRCLkxlbmd0aDsgJGorKykgeyAkcHJldlskal0gPSAkaiB9CgogICAgZm9yICgkaT0xOyAkaSAtbGUgJEEuTGVuZ3RoOyAkaSsrKSB7CiAgICAgICAgJGN1cnJbMF0gPSAkaQogICAgICAgIGZvciAoJGo9MTsgJGogLWxlICRCLkxlbmd0aDsgJGorKykgewogICAgICAgICAgICAkY29zdCA9IGlmICgkQVskaS0xXSAtZXEgJEJbJGotMV0pIHsgMCB9IGVsc2UgeyAxIH0KICAgICAgICAgICAgJGN1cnJbJGpdID0gW01hdGhdOjpNaW4oW01hdGhdOjpNaW4oJGN1cnJbJGotMV0gKyAxLCRwcmV2WyRqXSArIDEpLCRwcmV2WyRqLTFdICsgJGNvc3QpCiAgICAgICAgfQogICAgICAgICR0bXA9JHByZXY7ICRwcmV2PSRjdXJyOyAkY3Vycj0kdG1wCiAgICB9CiAgICByZXR1cm4gJHByZXZbJEIuTGVuZ3RoXQp9CgpmdW5jdGlvbiBJbnZva2UtV2luZG93c1NwZWxsRml4KFtzdHJpbmddJFRleHQsW3N0cmluZ10kTGFuZ3VhZ2VUYWcpIHsKICAgIHRyeSB7CiAgICAgICAgQWRkLVR5cGUgLUFzc2VtYmx5TmFtZSBQcmVzZW50YXRpb25GcmFtZXdvcmsgLUVycm9yQWN0aW9uIFN0b3AKICAgICAgICAkdGIgPSBOZXctT2JqZWN0IFN5c3RlbS5XaW5kb3dzLkNvbnRyb2xzLlRleHRCb3gKICAgICAgICAkdGIuTGFuZ3VhZ2UgPSBbU3lzdGVtLldpbmRvd3MuTWFya3VwLlhtbExhbmd1YWdlXTo6R2V0TGFuZ3VhZ2UoJExhbmd1YWdlVGFnKQogICAgICAgIFtTeXN0ZW0uV2luZG93cy5Db250cm9scy5TcGVsbENoZWNrXTo6U2V0SXNFbmFibGVkKCR0YiwkdHJ1ZSkKICAgICAgICAkdGIuVGV4dCA9ICRUZXh0CiAgICAgICAgJHRiLlVwZGF0ZUxheW91dCgpCgogICAgICAgICRyZXBhaXJzID0gQCgpCiAgICAgICAgJGlkeCA9IDAKICAgICAgICB3aGlsZSAoJGlkeCAtbHQgJHRiLlRleHQuTGVuZ3RoKSB7CiAgICAgICAgICAgICRlcnJJbmRleCA9ICR0Yi5HZXROZXh0U3BlbGxpbmdFcnJvckNoYXJhY3RlckluZGV4KCRpZHgsW1N5c3RlbS5XaW5kb3dzLkRvY3VtZW50cy5Mb2dpY2FsRGlyZWN0aW9uXTo6Rm9yd2FyZCkKICAgICAgICAgICAgaWYgKCRlcnJJbmRleCAtbHQgMCkgeyBicmVhayB9CgogICAgICAgICAgICAkbGVuID0gJHRiLkdldFNwZWxsaW5nRXJyb3JMZW5ndGgoJGVyckluZGV4KQogICAgICAgICAgICBpZiAoJGxlbiAtbGUgMCkgeyAkaWR4ID0gJGVyckluZGV4ICsgMTsgY29udGludWUgfQoKICAgICAgICAgICAgJGVycm9yID0gJHRiLkdldFNwZWxsaW5nRXJyb3IoJGVyckluZGV4KQogICAgICAgICAgICAkc3VnZ2VzdGlvbnMgPSBAKCRlcnJvci5TdWdnZXN0aW9ucykKICAgICAgICAgICAgaWYgKCRzdWdnZXN0aW9ucy5Db3VudCAtZ3QgMCkgewogICAgICAgICAgICAgICAgJG9yaWdpbmFsID0gJHRiLlRleHQuU3Vic3RyaW5nKCRlcnJJbmRleCwkbGVuKQogICAgICAgICAgICAgICAgJHN1Z2dlc3Rpb24gPSBbc3RyaW5nXSRzdWdnZXN0aW9uc1swXQogICAgICAgICAgICAgICAgJGRpc3RhbmNlID0gR2V0LUxldmVuc2h0ZWluICRvcmlnaW5hbC5Ub0xvd2VySW52YXJpYW50KCkgJHN1Z2dlc3Rpb24uVG9Mb3dlckludmFyaWFudCgpCiAgICAgICAgICAgICAgICAkbGltaXQgPSBpZiAoJG9yaWdpbmFsLkxlbmd0aCAtbGUgNCkgeyAxIH0gZWxzZWlmICgkb3JpZ2luYWwuTGVuZ3RoIC1sZSA4KSB7IDIgfSBlbHNlIHsgMyB9CgogICAgICAgICAgICAgICAgaWYgKCRkaXN0YW5jZSAtbGUgJGxpbWl0IC1hbmQgJHN1Z2dlc3Rpb24uTGVuZ3RoIC1ndCAwKSB7CiAgICAgICAgICAgICAgICAgICAgJHJlcGFpcnMgKz0gW3BzY3VzdG9tb2JqZWN0XUB7IFN0YXJ0PSRlcnJJbmRleDsgTGVuZ3RoPSRsZW47IFRleHQ9JHN1Z2dlc3Rpb24gfQogICAgICAgICAgICAgICAgfQogICAgICAgICAgICB9CiAgICAgICAgICAgICRpZHggPSAkZXJySW5kZXggKyBbTWF0aF06Ok1heCgkbGVuLDEpCiAgICAgICAgfQoKICAgICAgICAkZml4ZWQgPSAkVGV4dAogICAgICAgIGZvcmVhY2ggKCRyIGluICgkcmVwYWlycyB8IFNvcnQtT2JqZWN0IFN0YXJ0IC1EZXNjZW5kaW5nKSkgewogICAgICAgICAgICAkZml4ZWQgPSAkZml4ZWQuUmVtb3ZlKFtpbnRdJHIuU3RhcnQsW2ludF0kci5MZW5ndGgpLkluc2VydChbaW50XSRyLlN0YXJ0LFtzdHJpbmddJHIuVGV4dCkKICAgICAgICB9CiAgICAgICAgcmV0dXJuICRmaXhlZAogICAgfSBjYXRjaCB7CiAgICAgICAgcmV0dXJuICRUZXh0CiAgICB9Cn0KCmZ1bmN0aW9uIEludm9rZS1GaXgoW3N0cmluZ10kVGV4dCkgewogICAgJGZpeGVkID0gJFRleHQKCiAgICBpZiAoSGFzLUFyYWJpYyAkZml4ZWQpIHsKICAgICAgICAkYXJhYmljID0gW29yZGVyZWRdQHsKICAgICAgICAgICAgItmH2KfYsNinIj0i2YfYsNinIjsgItmH2KfYsNmHIj0i2YfYsNmHIjsgItmE2KfZg9mGIj0i2YTZg9mGIjsgItin2YTZhNiw2YoiPSLYp9mE2LDZiiI7ICLYp9mE2YTYqtmKIj0i2KfZhNiq2YoiOwogICAgICAgICAgICAi2K7Yt9ihIj0i2K7Yt9ijIjsgItin2K7Yt9in2KEiPSLYo9iu2LfYp9ihIjsgItin2YTZiSI9Itil2YTZiSI7ICLYp9mE2KfZhiI9Itin2YTYotmGIjsgItin2YrYttinIj0i2KPZiti22YvYpyI7CiAgICAgICAgICAgICLZhdiz2KfZhNmHIj0i2YXYs9ij2YTYqSI7ICLZhdiz2KbZhNmHIj0i2YXYs9ij2YTYqSI7ICLZhdiz2YjZiNmEIj0i2YXYs9ik2YjZhCI7ICLZhNi62YciPSLZhNi62KkiOyAi2YPZhNmF2YciPSLZg9mE2YXYqSI7CiAgICAgICAgICAgICLZh9mG2KfYp9mDIj0i2YfZhtin2YMiOyAi2YfZhtin2KciPSLZh9mG2KciOyAi2YXYtNmD2YTZhyI9ItmF2LTZg9mE2KkiOyAi2LfYsdmK2YLZhyI9Iti32LHZitmC2KkiOyAi2KrYsdis2YXZhyI9Itiq2LHYrNmF2KkiOwogICAgICAgICAgICAi2KfZhti02KfYodin2YTZhNmHIj0i2KXZhiDYtNin2KEg2KfZhNmE2YciOyAi2LTYp9ih2KfZhNmE2YciPSLYtNin2KEg2KfZhNmE2YciCiAgICAgICAgfQogICAgICAgIGZvcmVhY2ggKCRrIGluICRhcmFiaWMuS2V5cykgeyAkZml4ZWQgPSBSZXBsYWNlLVdvcmQgJGZpeGVkICRrICRhcmFiaWNbJGtdICRmYWxzZSB9CgogICAgICAgICRiZWZvcmUgPSAkZml4ZWQKICAgICAgICAkZml4ZWQgPSBJbnZva2UtV2luZG93c1NwZWxsRml4ICRmaXhlZCAiYXItSVEiCiAgICAgICAgaWYgKCRmaXhlZCAtZXEgJGJlZm9yZSkgeyAkZml4ZWQgPSBJbnZva2UtV2luZG93c1NwZWxsRml4ICRmaXhlZCAiYXItU0EiIH0KICAgIH0gZWxzZSB7CiAgICAgICAgJGVuZ2xpc2ggPSBbb3JkZXJlZF1AewogICAgICAgICAgICAidGVoIj0idGhlIjsgImZyZW5kIj0iZnJpZW5kIjsgImZyZWluZCI9ImZyaWVuZCI7ICJyZWNpZXZlIj0icmVjZWl2ZSI7ICJhZHJlc3MiPSJhZGRyZXNzIjsKICAgICAgICAgICAgImJlY3Vhc2UiPSJiZWNhdXNlIjsgImxhbmdhdWdlIj0ibGFuZ3VhZ2UiOyAiZW5nbGloIj0iZW5nbGlzaCI7ICJ0cmFuc2FsdGUiPSJ0cmFuc2xhdGUiOwogICAgICAgICAgICAidHJhbnNsdGUiPSJ0cmFuc2xhdGUiOyAidGhpZXIiPSJ0aGVpciI7ICJ3aWVyZCI9IndlaXJkIjsgInNlcGVyYXRlIj0ic2VwYXJhdGUiOwogICAgICAgICAgICAiZGVmaW5hdGVseSI9ImRlZmluaXRlbHkiOyAib2NjdXJlZCI9Im9jY3VycmVkIjsgInVudGlsbCI9InVudGlsIjsgIndpY2giPSJ3aGljaCIKICAgICAgICB9CiAgICAgICAgZm9yZWFjaCAoJGsgaW4gJGVuZ2xpc2guS2V5cykgeyAkZml4ZWQgPSBSZXBsYWNlLVdvcmQgJGZpeGVkICRrICRlbmdsaXNoWyRrXSAkdHJ1ZSB9CgogICAgICAgICRmaXhlZCA9IEludm9rZS1XaW5kb3dzU3BlbGxGaXggJGZpeGVkICJlbi1VUyIKICAgICAgICAkZml4ZWQgPSBbcmVnZXhdOjpSZXBsYWNlKCRmaXhlZCwnKD9pKVxiSVxzK2hhc1xiJywnSSBoYXZlJykKICAgICAgICAkZml4ZWQgPSBbcmVnZXhdOjpSZXBsYWNlKCRmaXhlZCwnKD9pKVxieW91XHMraXNcYicsJ3lvdSBhcmUnKQogICAgICAgICRmaXhlZCA9IFtyZWdleF06OlJlcGxhY2UoJGZpeGVkLCcoP2kpXGJ0aGV5XHMraXNcYicsJ3RoZXkgYXJlJykKICAgICAgICAkZml4ZWQgPSBbcmVnZXhdOjpSZXBsYWNlKCRmaXhlZCwnKD9pKVxiaGVccytoYXZlXGInLCdoZSBoYXMnKQogICAgICAgICRmaXhlZCA9IFtyZWdleF06OlJlcGxhY2UoJGZpeGVkLCcoP2kpXGJzaGVccytoYXZlXGInLCdzaGUgaGFzJykKICAgIH0KCiAgICAkZml4ZWQgPSBbcmVnZXhdOjpSZXBsYWNlKCRmaXhlZCwnWyBcdF0rJywnICcpCiAgICAkZml4ZWQgPSBbcmVnZXhdOjpSZXBsYWNlKCRmaXhlZCwnXHMrKFssLjs6IT/YjNibXSknLCckMScpCiAgICAkZml4ZWQgPSBbcmVnZXhdOjpSZXBsYWNlKCRmaXhlZCwnKFssLjs6IT/YjNibXSkoW15cc1xyXG5dKScsJyQxICQyJykKICAgICRmaXhlZCA9IFtyZWdleF06OlJlcGxhY2UoJGZpeGVkLCcoXHI/XG4pezMsfScsKFtFbnZpcm9ubWVudF06Ok5ld0xpbmUgKyBbRW52aXJvbm1lbnRdOjpOZXdMaW5lKSkKICAgIHJldHVybiAkZml4ZWQuVHJpbSgpCn0KCnRyeSB7CiAgICBpZiAoLW5vdCAoVGVzdC1QYXRoIC1MaXRlcmFsUGF0aCAkSW5wdXRGaWxlKSkgeyB0aHJvdyAiSW5wdXQgZmlsZSB3YXMgbm90IGZvdW5kLiIgfQogICAgJHRleHQgPSBbU3lzdGVtLklPLkZpbGVdOjpSZWFkQWxsVGV4dCgkSW5wdXRGaWxlLFtTeXN0ZW0uVGV4dC5FbmNvZGluZ106OlVURjgpCgogICAgaWYgKFtzdHJpbmddOjpJc051bGxPcldoaXRlU3BhY2UoJHRleHQpKSB7CiAgICAgICAgV3JpdGUtUmVzdWx0ICIiCiAgICAgICAgZXhpdCAwCiAgICB9CgogICAgaWYgKCRNb2RlIC1lcSAidHJhbnNsYXRlIikgeyBXcml0ZS1SZXN1bHQgKEludm9rZS1UcmFuc2xhdGlvbiAkdGV4dCkgfQogICAgZWxzZSB7IFdyaXRlLVJlc3VsdCAoSW52b2tlLUZpeCAkdGV4dCkgfQogICAgZXhpdCAwCn0KY2F0Y2ggewogICAgV3JpdGUtUmVzdWx0ICgiX19FUlJPUl9fOiIgKyAkXy5FeGNlcHRpb24uTWVzc2FnZSkKICAgIGV4aXQgMQp9Cg=="

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

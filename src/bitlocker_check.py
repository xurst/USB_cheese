import time
import ctypes
from ctypes import wintypes
import sys


STD_OUTPUT_HANDLE = -11
FOREGROUND_RED = 0x0004
FOREGROUND_GREEN = 0x0002
FOREGROUND_YELLOW = FOREGROUND_RED | FOREGROUND_GREEN
FOREGROUND_CYAN = 0x0003
FOREGROUND_GRAY = 0x0007


std_out_handle = ctypes.windll.kernel32.GetStdHandle(STD_OUTPUT_HANDLE)

def set_console_color(color):
    ctypes.windll.kernel32.SetConsoleTextAttribute(std_out_handle, color)

def clear_screen():
    
    ctypes.windll.kernel32.SetConsoleTextAttribute(std_out_handle, FOREGROUND_GRAY)
    import os
    os.system('cls')

def write_host(text, color=None, end='\n'):
    if color is not None:
        set_console_color(color)
    sys.stdout.write(text)
    sys.stdout.write(end)
    sys.stdout.flush()
    if color is not None:
        set_console_color(FOREGROUND_GRAY)

def get_bitlocker_status(drive_letter):
    
    
    try:
        import pythoncom
        import win32com.client
    except ImportError:
        return None, "pywin32 required for COM access"

    try:
        shell = win32com.client.Dispatch("Shell.Application")
        folder = shell.NameSpace(drive_letter)
        if folder is None:
            return None, "query error"
        val = folder.Self.ExtendedProperty('System.Volume.BitLockerProtection')
        return val, None
    except Exception as e:
        return None, "query error"

def get_filesystem_drives():
    
    drives = []
    bitmask = ctypes.windll.kernel32.GetLogicalDrives()
    for i in range(26):
        if bitmask & (1 << i):
            drive_letter = chr(65 + i) + ':\\'
            
            drive_type = ctypes.windll.kernel32.GetDriveTypeW(wintypes.LPCWSTR(drive_letter))
            
            if drive_type in (2, 3, 4, 5):
                drives.append(drive_letter)
    return drives

def get_instant_bitlocker_status():
    clear_screen()

    write_host("=== bitlocker checker ===", FOREGROUND_CYAN)
    write_host("scanning...", FOREGROUND_YELLOW)
    write_host("")

    letters = get_filesystem_drives()

    encrypted_count = 0
    unprotected_count = 0

    for root in letters:
        drive = root.rstrip('\\')
        val, error = get_bitlocker_status(root)
        if error:
            write_host(f"{drive}", None, end='')
            write_host(" query error", FOREGROUND_RED)
            continue

        if val in (1, 3, 5):
            write_host(f"{drive} : ", None, end='')
            write_host("ENCRYPTED", FOREGROUND_RED)
            encrypted_count += 1
        elif val is None:
            write_host(f"{drive} : ", None, end='')
            write_host("NO DATA", FOREGROUND_YELLOW)
        elif val == 2:
            write_host(f"{drive} : ", None, end='')
            write_host("UNPROTECTED", FOREGROUND_GREEN)
            unprotected_count += 1
        else:
            write_host(f"{drive} : ", None, end='')
            write_host("UNKNOWN", FOREGROUND_YELLOW)

    write_host("")
    write_host("=== summary ===", FOREGROUND_CYAN)
    write_host(f"encrypted: {encrypted_count}", FOREGROUND_RED)
    if unprotected_count > 0:
        write_host(f"unprotected: {unprotected_count}", FOREGROUND_GREEN)
    else:
        write_host(f"unprotected: {unprotected_count}", FOREGROUND_RED)

    write_host("")
    write_host("closing in 4 seconds...", FOREGROUND_GRAY)

get_instant_bitlocker_status()
time.sleep(4)
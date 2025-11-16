import time, sys, os, ctypes, subprocess
from ctypes import wintypes


GRAY, RED, GREEN, YELLOW, CYAN = 0x7, 0x4, 0x2, 0x6, 0x3
std = ctypes.windll.kernel32.GetStdHandle(-11)

def c(col): ctypes.windll.kernel32.SetConsoleTextAttribute(std, col)
def out(txt, col=GRAY, end="\n"):
    c(col); sys.stdout.write(txt + end); c(GRAY)


def ps(cmd):
    r = subprocess.run(
        ["powershell", "-NoProfile", "-Command", cmd],
        capture_output=True, text=True, timeout=5
    )
    return r.stdout.strip() if r.returncode == 0 else None

def bl_status(d):
    script = f"(New-Object -Com Shell.Application).NameSpace('{d}').Self.ExtendedProperty('System.Volume.BitLockerProtection')"
    try:
        val = ps(script)
        return int(val) if val and val.isdigit() else None
    except: return None

def drives():
    out = []
    mask = ctypes.windll.kernel32.GetLogicalDrives()
    for i in range(26):
        if mask & (1 << i):
            d = f"{chr(65+i)}:\\"
            t = ctypes.windll.kernel32.GetDriveTypeW(wintypes.LPCWSTR(d))
            if t in (2,3,4,5): out.append(d)
    return out


def scan():
    os.system("cls")
    out("=== bitlocker checker ===", CYAN)
    out("scanning...", YELLOW); out("")

    enc = unp = 0
    for d in drives():
        val = bl_status(d)
        if val in (1,3,5):
            out(f"{d[:-1]} : PROTECTED", RED); enc += 1
        elif val == 2:
            out(f"{d[:-1]} : UNPROTECTED", GREEN); unp += 1
        else:
            out(f"{d[:-1]} : NO DATA", YELLOW)

    out(""); out("=== summary ===", CYAN)
    out(f"protected: {enc}", RED)
    out(f"unprotected: {unp}", GREEN if unp else RED)
    out(""); out("closing in 4 seconds...")

if __name__ == "__main__":
    scan()
    time.sleep(4)

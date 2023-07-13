@echo off
net user forensicAdmin forensicAdmin /add
net localgroup administrators forensicAdmin /add
net localgroup administrator forensicAdmin /add
net localgroup administradores forensicAdmin /add
net localgroup administrador forensicAdmin /add
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d forensicAdmin /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d forensicAdmin /f
shutdown /r /c "This system will be rebooted in 60 seconds to create a new administrator with the name and pwd forensicAdmin."

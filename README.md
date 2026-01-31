# BackupTars

Script for copying tar arhive from linux to Windows.

This script used for making backup from linux (samba) to windows server.

Before use BackupFileSystem.ps1 you need use backup.sh in crontab linux for pack directory to tar arhive

Settings for credentials file .xml

```

$credentials = Get-Credential | Export-Clixml -Path 'C:\example\path\pass.xml'

```

And don't forget to change the directory paths in the script.
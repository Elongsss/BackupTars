# BackupTars

Script for copying tar arhive from linux to Windows.

Before use BackupFileSystem.ps1 you need use backup.sh in crontab linux

Settings for credentials file .xml

```

$credentials = Get-Credential | Export-Clixml -Path 'C:\example\path\pass.xml'

```

And don't forget to change the directory paths in the script.
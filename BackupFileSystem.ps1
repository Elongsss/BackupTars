#region Variables
$localcatalogy = "C:\example\" # Локальный каталог
$credfile = 'C:\example\example\pass.xml' # Файл с учетными данными
$sources = '\\network\share\' # Каталог smb где лежат бэкапы
$year = (Get-Date).Year  # Тsекущий год
$retentionDate = (Get-Date).AddDays(-14) # -14 дней для удаления файлов
$yesterdayDay = (Get-Date).AddDays(-1) # -1 день для бэкапов
$yesterdayPattern = $yesterdayDay.ToString("dd.MM.yyyy") 
$LocalArhYear = Join-Path -Path $localcatalogy -ChildPath $year
$DiskName = "PublicD" # Название временного сетевого диска
$result = New-Object System.Collections.ArrayList # Массив для ошибок
$errmessage = New-Object System.Collections.ArrayList # Массив для ошибочных файлов
$VerbosePreference = "Continue" 
# Формат SMTP сообщений
$messageParam = @{
    SmtpServer = "mail.local"
    From       = "$ENV:COMPUTERNAME@gmail"
    To         = 'ex.ample@gmail'
    Encoding   = "UTF8"
    Subject    = "Backup Email $(get-date -format dd.MM.yyyy)"
    Body       = "Скрипт: $PSCommandPath"
}
#Endregion
#region Checks
if (!(Test-Path -Path $LocalArhYear)) {
    try {
        New-Item -ItemType Directory -Path $LocalArhYear -ErrorAction Stop | Out-Null
    }
    catch {
        $messageParam.Body += "`nОшибка при создании каталога '$LocalArhYear'`nТекст ошибки: $($_.Exception.Message)"
        Send-MailMessage @messageParam
        throw "Ошибка: $($_.Exception.Message)"
    }
}
#Endregion
#region Prepare
Write-Verbose "Выполняется подключение временного сетевого диска"
try {
    New-PSDrive -Name "$DiskName" -PSProvider 'FileSystem' -Root "$sources" -ErrorAction Stop -Credential (Import-Clixml -Path $credfile) 
}
catch {
    $messageParam.Body += "`nОшибка подключения диска`nТекст ошибки: $($_.Exception.Message)"
    Send-MailMessage @messageParam
    throw "Ошибка: $($_.Exception.Message)"
} 
Write-Verbose "Диск успешно подключен - $DiskName"
#Endregion
#region Main
$backupTar = Get-ChildItem -Path $sources -Filter "*.tar" | Where-Object {
    $_.Name -match $yesterdayPattern
}
if ($backupTar) {
    Write-Verbose "Найдена резеврная копия за вчерашний день: $($backupTar.Name). Начинается перенос."
    try {
        $backCopy = Copy-Item -Path $backupTar.FullName -Destination $LocalArhYear -ErrorAction Stop -PassThru
        Write-Verbose "Перенос выполнен успешно"
    }
    catch {
        Write-Verbose "Перенос завершился с ошибкой"
        $messageParam.Body += "`nОшибка при переносе файла. '$backupTar'`nТекст ошибки: $($_.Exception.Message)"
        Send-MailMessage @messageParam
        Remove-PSDrive -Name "$DiskName" 
        throw "Ошибка: $($_.Exception.Message)"
    }
}
else {
    $messageParam.Body += "`nНе найден архив за вчерашний день"
    Send-MailMessage @messageParam
    Remove-PSDrive -Name "$DiskName" 
    throw
}
if ($backCopy) {
    Write-Verbose "Начинается парсинг дат из имен файлов."
    foreach ($oldfile in (Get-ChildItem -Path $LocalArhYear -Recurse -Filter "*.tar" | Where-Object {
                $_.Name -match "\d{2}\.\d{2}\.\d{4}" })) {
         $archiveDate = [datetime]::ParseExact($oldfile.Name.Substring(16, 10), "dd.MM.yyyy", $null)
        Write-Verbose "Даты извлечены ($archivedate)"
        
        if ($archiveDate -lt $retentionDate -and $archiveDate.Day -ne 1) {
            try {
                Remove-Item $oldfile.FullName -Force -ErrorAction Stop
                Write-Verbose "Удаление архива - $oldfile"
            }
            catch {
                [void]$result.Add($oldfile.Name)  
                [void]$errmessage.Add($_.Exception.Message) 
            }
        }
    }
}

if ($result) {
    $arraylist = $result -join ",`n"
    $messageParam.Body += "`nОшибка при ротации файлов. `nFiles: $arraylist`nТекст ошибки: $errmessage"
    Send-MailMessage @messageParam
}
Write-Verbose "Удаление сетевого диска $DiskName"
Remove-PSDrive -Name "$DiskName"
#Endregion

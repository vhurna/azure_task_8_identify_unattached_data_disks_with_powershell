<#
.SYNOPSIS

.DESCRIPTION
    Скрипт отримує всі керовані диски в Resource Group,
    фільтрує ті, в яких властивість ManagedBy пуста або DiskState = 'Unattached',
    і зберігає результат у файлі result.json.

.PARAMETER ResourceGroupName
    Ім’я Resource Group (за замовчуванням mate-azure-task-5).

.PARAMETER OutputFile
    Шлях до вихідного JSON-файлу (за замовчуванням result.json).
#>

param(
    [string]$ResourceGroupName = 'mate-azure-task-5',
    [string]$OutputFile       = (Join-Path -Path $PSScriptRoot -ChildPath 'result.json')
)

# Зупиняємо виконання при будь-якій помилці
$ErrorActionPreference = 'Stop'

# Імпортуємо модулі та авторизуємося
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Compute  -ErrorAction Stop
if (-not (Get-AzContext)) {
    Write-Host "Підключаюся до Azure..."
    Connect-AzAccount -ErrorAction Stop
}

Write-Host "Resource group: $ResourceGroupName"
Write-Host "Result file: $OutputFile"

# Перевіряємо наявність RG
if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    throw "Resource group '$ResourceGroupName' не знайдено."
}

# Отримуємо всі диски
$allDisks = Get-AzDisk -ResourceGroupName $ResourceGroupName

# Фільтруємо лише від’єднані
$unattachedDisks = $allDisks | Where-Object {
    ($_.DiskState -eq 'Unattached') -or ([string]::IsNullOrEmpty($_.ManagedBy))
}

Write-Host "Знайдено від’єднаних дисків: $($unattachedDisks.Count)"

# Експортуємо повні об’єкти в JSON (глибина 10)
$unattachedDisks |
    ConvertTo-Json -Depth 10 |
    Out-File -FilePath $OutputFile -Encoding UTF8 -Force

Write-Host "Експорт завершено в $OutputFile."

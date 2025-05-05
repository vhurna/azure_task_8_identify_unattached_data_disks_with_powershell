<#
.SYNOPSIS
    Знаходить всі від’єднані диски в заданій RG і експортує їх у JSON.

.DESCRIPTION
    Скрипт отримує всі керовані диски в Resource Group,
    фільтрує ті, в яких властивість ManagedBy пуста або DiskState = 'Unattached',
    і зберігає результат у файлі result.json. 
    Якщо тільки один диск знайдено, він виводиться як обʼєкт JSON, інакше — як масив.
#>

param(
    [string]$ResourceGroupName = 'mate-azure-task-5',
    [string]$OutputFile       = (Join-Path -Path $PSScriptRoot -ChildPath 'result.json')
)

$ErrorActionPreference = 'Stop'

Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Compute  -ErrorAction Stop
if (-not (Get-AzContext)) {
    Write-Host "Підключаюся до Azure..."
    Connect-AzAccount -ErrorAction Stop
}

Write-Host "Resource group: $ResourceGroupName"
Write-Host "Result file: $OutputFile"

if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    throw "Resource group '$ResourceGroupName' не знайдено."
}

$allDisks = Get-AzDisk -ResourceGroupName $ResourceGroupName

$unattachedDisks = $allDisks | Where-Object {
    ($_.DiskState -eq 'Unattached') -or ([string]::IsNullOrEmpty($_.ManagedBy))
}

Write-Host "Знайдено від’єднаних дисків: $($unattachedDisks.Count)"

if ($unattachedDisks.Count -eq 1) {
    # Один диск — експорт як об'єкт
    $unattachedDisks[0] |
        ConvertTo-Json -Depth 10 |
        Out-File -FilePath $OutputFile -Encoding UTF8 -Force
}
else {
    # Більше одного — експорт масиву
    $unattachedDisks |
        ConvertTo-Json -Depth 10 |
        Out-File -FilePath $OutputFile -Encoding UTF8 -Force
}

Write-Host "Експорт завершено в $OutputFile."

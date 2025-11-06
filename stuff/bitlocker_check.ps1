

Set-ExecutionPolicy Bypass -Scope Process -Force 2>&1 | Out-Null

function Get-InstantBitLockerStatus {
    Clear-Host
    
    Write-Host "=== bitlocker checker ===" -ForegroundColor Cyan
    Write-Host "scanning..." -ForegroundColor Yellow
    Write-Host ""
    
    $letters = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' } | Select-Object -ExpandProperty Root
    
    $encryptedCount = 0
    $unprotectedCount = 0
    
    foreach ($root in $letters) {
        $drive = $root.TrimEnd('\')
        $val = $null
        
        try {
            $val = (New-Object -ComObject Shell.Application).NameSpace($drive).Self.ExtendedProperty('System.Volume.BitLockerProtection')
        } catch {
            Write-Host "$drive" -NoNewline
            Write-Host "query error" -ForegroundColor Red
            continue
        }
        
        switch ($val) {
            {$_ -in 1,3,5} { 
                Write-Host "$drive : " -NoNewline
                Write-Host "ENCRYPTED" -ForegroundColor Red
                $encryptedCount++
                break 
            }
            {$_ -eq $null} { 
                Write-Host "$drive : " -NoNewline
                Write-Host "NO DATA" -ForegroundColor Yellow
                break 
            }
            2 { 
                Write-Host "$drive : " -NoNewline
                Write-Host "UNPROTECTED" -ForegroundColor Green
                $unprotectedCount++
                break 
            }
            default { 
                Write-Host "$drive : " -NoNewline
                Write-Host "UNKNOWN" -ForegroundColor Yellow
                break 
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== summary ===" -ForegroundColor Cyan
    Write-Host "encrypted: $encryptedCount" -ForegroundColor Red
    Write-Host "unprotected: $unprotectedCount" -ForegroundColor $(if ($unprotectedCount -gt 0) { "Green" } else { "Red" })
    
    Write-Host ""
    Write-Host "closing in 4 seconds..." -ForegroundColor Gray
}

Get-InstantBitLockerStatus

Start-Sleep -Seconds 4
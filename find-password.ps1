Get-ChildItem C:\STEP\BwanaAD\ -Recurse -File -Include *.xml,*.json,*.txt,*.psd1 2>$null | ForEach-Object {
    $c = Get-Content $_ -Raw -ErrorAction SilentlyContinue
    if ($c -match 'password|credential|secret') {
        Write-Host $_
        $c -split "`r?`n" | Select-String 'password|credential|secret' | Select-Object -First 3
    }
}
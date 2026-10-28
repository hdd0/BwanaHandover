$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
Get-Command bun -All | Format-Table CommandType, Source -AutoSize
& bun --version

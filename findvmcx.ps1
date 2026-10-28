Get-ChildItem -Path C:\ -Recurse -Filter "*.vmcx" -ErrorAction SilentlyContinue 2>$null | Select FullName

# env:Path += ";C:\Users\hamel\AppData\Local\Programs\oh-my-posh\bin"
# C:\Users\hamel\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\kushal.omp.json" | Invoke-Expression
Import-Module -Name Terminal-Icons

$Godot = ".\tools\Godot_v3.4.4-stable_win64.exe"
Start-Process -FilePath "$Godot" -ArgumentList "--no-window --listen"
#Start-Process -FilePath "$Godot" -ArgumentList "--connect"
& $Godot --connect

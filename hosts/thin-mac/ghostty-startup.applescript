property startupCommands : {"hu", "hmini", "herdr"}

on run arguments
  if (count of arguments) > 0 and item 1 of arguments is "--dry-run" then
    return "hu" & linefeed & "hmini" & linefeed & "herdr"
  end if

  set homeDirectory to system attribute "HOME"

  tell application "Ghostty"
    if (count of windows) is 0 then error "Ghostty startup window is unavailable."

    set startupWindow to front window
    set firstStartupTab to missing value

    repeat with startupCommand in my startupCommands
      set startupConfiguration to new surface configuration from {initial working directory:homeDirectory, initial input:((contents of startupCommand) & linefeed)}
      set createdTab to new tab in startupWindow with configuration startupConfiguration
      if firstStartupTab is missing value then set firstStartupTab to createdTab
      select tab createdTab
    end repeat

    select tab firstStartupTab
  end tell
end run

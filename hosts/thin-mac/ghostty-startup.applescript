property startupCommands : {"hu", "hmini", "herdr"}

on run arguments
  if (count of arguments) > 0 and item 1 of arguments is "--dry-run" then
    return "hu" & linefeed & "hmini" & linefeed & "herdr"
  end if

  set homeDirectory to system attribute "HOME"

  tell application "Ghostty"
    if (count of windows) is 0 then error "Ghostty startup window is unavailable."

    set startupWindow to front window
    set startupTabs to {}

    repeat with commandIndex from 1 to count of my startupCommands
      set startupConfiguration to new surface configuration from {initial working directory:homeDirectory}
      set createdTab to new tab in startupWindow with configuration startupConfiguration
      set end of startupTabs to createdTab
      select tab createdTab
    end repeat

    repeat with commandIndex from 1 to count of my startupCommands
      set createdTab to item commandIndex of startupTabs
      set startupCommand to item commandIndex of my startupCommands
      select tab createdTab
      set createdTerminal to focused terminal of createdTab
      input text startupCommand to createdTerminal
      send key "enter" to createdTerminal
    end repeat

    set firstStartupTab to item 1 of startupTabs
    select tab firstStartupTab
    focus (focused terminal of firstStartupTab)
  end tell
end run

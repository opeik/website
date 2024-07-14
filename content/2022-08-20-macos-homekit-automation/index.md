+++
title = "macOS HomeKit automation"

[taxonomies]
tags = ["macos", "homekit", "automation", "hammerspoon"]
+++

## The problem

My Mac mini is hooked up to a pair of Yamaha HS8s via a TASCAM 208i. The manual instructs you to
turn the speakers off when not in use to prevent wear. Fishing for the power switch behind each
speaker got annoying quickly, so I decided to automate the process.

<!-- more -->

## The solution

Since I can't control the speakers remotely, I opted to leave them on and control the
power socket instead. I bought a [Wemo HomeKit smart plug][smart-plug], connected the
speakers to it, and then added it to the Home app. Sure enough, when I toggle the smart plug,
everything springs to life.

{{ figure(src="/macos-homekit-automation/homekit.png", caption="Speakers in the Home app") }}

Next, I created a pair of shortcuts via the Shortcuts app to power the speakers on and off.

{{ figure(src="/macos-homekit-automation/shortcut.png", caption="Controlling the speakers via the Shortcuts app") }}

Since macOS ships a Shortcuts command line utility, we can now control the speakers like so:

```sh
shortcuts run 'Turn speakers on'
shortcuts run 'Turn speakers off'
```

The last puzzle piece is running the appropriate shortcut upon sleeping and waking.
I opted to use [Hammerspoon][hammerspoon] since it lets us conveniently hook into macOS
events via Lua scripts.

The [`caffeinate.watcher`][caffeinate-watcher] module contains the functionality we're after. After
creating and starting a caffeinate watcher, it'll run your callback function in response to power events.
Since I'm only interested in sleep and wake events, I filtered the rest out.

Here's an example `~/.hammerspoon/init.lua`:

```lua
local watcher = hs.caffeinate.watcher

local function power_callback(event)
    if event == watcher.systemDidWake then
        os.execute("shortcuts run 'Turn speakers on'")
    elseif event == watcher.systemWillSleep then
        os.execute("shortcuts run 'Turn speakers off'")
    end
end

watcher.new(power_callback):start()
```

Finally, reload the Hammerspoon config and attempt to justify how much time you spent automating a
ten-second task.

[smart-plug]: https://www.apple.com/au/shop/product/HQ0S2X/A/belkin-wemo-smart-plug-with-thread
[hammerspoon]: https://www.hammerspoon.org
[caffeinate-watcher]: https://www.hammerspoon.org/docs/hs.caffeinate.watcher.html

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local sharetags = require("sharetags")
local myprompt = require("myprompt")
local vicious = require("vicious")

local myLayouts = require("myLayouts")

local pomodoro = require("pomodoro")
pomodoro.init()
if isNuanceLaptop then
    pomodoro.show()
end

local hnHandle = io.popen("hostname")
-- See http://rosettacode.org/wiki/Strip_whitespace_from_a_string/Top_and_tail#Lua
local hostname=hnHandle:read("*a"):match("^%s*(.-)%s*$")
local isNuanceLaptop = (hostname == "arch-ac-nb-vilar")
hnHandle:close()

local home = os.getenv("HOME")
local iconDir = home.."/.icons"

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
--beautiful.init("/usr/share/awesome/themes/default/theme.lua")
--beautiful.init("/usr/share/awesome/themes/zenburn/theme.lua")
beautiful.init(home.."/.config/awesome/zenburnMod.lua")
local APW=require("apw/widget")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.tile.left,
    awful.layout.suit.tile,
    awful.layout.suit.max,
    myLayouts.twoPane,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.fair,
    --awful.layout.suit.tile.top,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    --awful.layout.suit.floating,
    --awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags

local sharetags_taglist = require("sharetags.taglist")

if not sharetags.restore_taglist(home.."/.awesome_taglist.txt") then
    sharetags.add_tag("general", awful.layout.suit.tile)
    sharetags.add_tag("web", awful.layout.suit.max)
    if not isNuanceLaptop then
        sharetags.add_tag("laptop", awful.layout.suit.max)
    end
    sharetags.add_tag("IM", awful.layout.suit.tile)
end

awesome.connect_signal("exit",
    function(restart)
        if restart then
            sharetags.write_taglist(home.."/.awesome_taglist.txt", {["Beamer"]=true})
        end
    end)


if not isNuanceLaptop then
    local hnMonitorHandle = io.popen(home.."/bin/getMonitors.sh")
    while true do
        local line=hnMonitorHandle:read("*line")
        if line == nil then break end
        local output = string.gsub(line, " .*$", "")
        local monitorName = string.gsub(line, "^[^ ]* ", "")
        if monitorName == "BenQ GW2765" then
            benqMonitor = output
        elseif monitorName == "SyncMaster" then
            samsungMonitor = output
        elseif monitorName == "EPSON PJ" then
            beamerMonitor = output
        end
    end
    
    for s=1,screen.count() do
        for name,_ in pairs(screen[s].outputs) do
            if name == benqMonitor then
                sharetags.select_tag(sharetags.tags["web"], screen[s].index)
            elseif name == samsungMonitor then
                sharetags.select_tag(sharetags.tags["general"], screen[s].index)
            elseif name == beamerMonitor then
                sharetags.add_tag("Beamer", awful.layout.suit.max)
                sharetags.select_tag(sharetags.tags["Beamer"], screen[s].index)
            end
        end
    end
end

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

myquitmenu = {
    { "Suspend", function () os.execute("sudo systemctl suspend") end, iconDir.."/suspend.png"},
    { "Shutdown", function () os.execute("sudo systemctl poweroff") end, iconDir.."/poweroff.png" },
    { "Reboot", function () os.execute("sudo systemctl reboot") end, iconDir.."/restart.svg" },
}

if not isNuanceLaptop then
    videomenu = {
        { "Netflix", "netflixBeamer", "/home/david/.icons/netflix.ico"  },
        { "Kodi", "kodiBeamer", iconDir.."/kodi.png" },
        { "Netflix (all screens)", "netflixBeamerAllScreens", "/home/david/.icons/netflix.ico"  },
        { "Kodi (all screens)", "kodiBeamerAllScreens", iconDir.."/kodi.png" }
    }

    xrandrmenu = {
        { "Dual", "/home/david/bin/setupMonitors.sh Dual" },
        { "Big",  "/home/david/bin/setupMonitors.sh Big" },
        { "Beamer",  "/home/david/bin/setupMonitors.sh Beamer" }
    }

    mymainmenu = awful.menu({ items = {
        { "Qutebrowser", "qutebrowser", "/usr/share/icons/hicolor/32x32/apps/qutebrowser.png" },
        { "Firefox", "firefox", "/usr/share/icons/hicolor/32x32/apps/firefox.png" },
        { "Pidgin", "pidgin", "/usr/share/icons/hicolor/32x32/apps/pidgin.png" },
        { "Netflix", "netflixBeamer", "/home/david/.icons/netflix.ico" },
        { "Skype", "skype", "/usr/share/icons/hicolor/32x32/apps/skype.png" },
        { "Steam", home.."/bin/steam", "/usr/share/icons/hicolor/32x32/apps/steam.png" },
        { "Kodi", "kodiBeamer", iconDir.."/kodi.png" },
        { "Video", videomenu, iconDir.."/video.png" },
        { "XRandR", xrandrmenu, iconDir.."/xrandr.png" },
        { "Nuance laptop", "rdesk-nuanceLaptop.sh", iconDir.."/nuance.png" },
        { "Nuance VPN", "nuanceVpnToggle", iconDir.."/nuance.png" },
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "open terminal", terminal, iconDir.."/tuxterminal.png" },
        { "Quit", myquitmenu, iconDir.."/power.png" }
      }, 
      theme = { height = 20, width = 200 }
    })
else
    mymainmenu = awful.menu({ items = {
        { "Qutebrowser", "qutebrowser", "/usr/share/icons/hicolor/32x32/apps/qutebrowser.png" },
        { "Firefox", "firefox", "/usr/share/icons/hicolor/32x32/apps/firefox.png" },
        { "Pidgin", "pidgin", "/usr/share/icons/hicolor/32x32/apps/pidgin.png" },
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "open terminal", terminal, iconDir.."/tuxterminal.png" }
      }, 
      theme = { height = 20, width = 200 }
    })
end

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Nuance VPN
if not isNuanceLaptop then
    alienLedSetTo="none"
    nuanceVpnWidget = awful.widget.launcher({ image = iconDir.."/nuanceBW.png",
                                              command = "nuanceVpnToggle" })
    nuanceVpnUpdate = function()
            local setLedTo="none" -- We set the led indirectly so that the user can change it if desired
            if os.execute("pgrep openconnect > /dev/null") then
                nuanceVpnWidget:set_image(iconDir.."/nuance.png")
                setLedTo="green"
                pomodoro.show()
            else
                nuanceVpnWidget:set_image(iconDir.."/nuanceBW.png")
                setLedTo="purple"
                pomodoro.hide()
            end
            if alienLedSetTo ~= setLedTo then
                os.execute(home .. "/bin/alienLed " .. setLedTo)
                alienLedSetTo=setLedTo
            end
        end
    nuanceVpnUpdate()
    nuanceVpnTimer = timer({ timeout = 30 })
    nuanceVpnTimer:connect_signal("timeout", nuanceVpnUpdate)
    nuanceVpnTimer:start()
end
-- }}}

--- {{{ MPD
if not isNuanceLaptop then
    mpdwidget = wibox.widget.textbox()
    -- Register widget
    vicious.register(mpdwidget, vicious.widgets.mpd,
        function (mpdwidget, args)
            if args["{state}"] == "Stop" then 
                --return " MPD "
                return ""
            else 
                return " "..args["{Artist}"]..' - '.. args["{Title}"].." "
            end
        end, 11)
end
--- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    --awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({}, 1, function() sharetags.menu[mouse.screen]:toggle() end),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              --if c == client.focus then
                                              --    c.minimized = true
                                              --else
                                              if c ~= client.focus then
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    --mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
    mytaglist[s] = awful.widget.taglist(s, function(t, args) return t.selected end, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", height = 14, screen = s })

    -- Widgets that are aligned to the left
    sharetags.create_tag_menu(s)
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    -- right_layout:add(pomodoro.icon_widget)
    right_layout:add(pomodoro.widget)
    if not isNuanceLaptop then  right_layout:add(mpdwidget) end
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    if not isNuanceLaptop then right_layout:add(nuanceVpnWidget) end
    right_layout:add(mylayoutbox[s])
    if not isNuanceLaptop then right_layout:add(APW) end
    right_layout:add(mytextclock)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 2, function () mymainmenu:toggle() end),
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    --awful.key({ modkey,           }, "F1", function () awful.layout.set(layouts[1])   end),
    awful.key({ modkey,           }, "F1", function ()
            curLayout = awful.layout.get(mouse.screen)
            curLayoutName = awful.layout.getname(curLayout)
            if curLayoutName == "tileleft" then
                awful.layout.set(layouts[2])
            elseif curLayoutName == "tile" then
                awful.layout.set(layouts[1])
            else
                if not isNuanceLaptop then
                    for name,_ in pairs(screen[mouse.screen].outputs) do
                        if name == benqMonitor then
                            awful.layout.set(layouts[1])
                        else
                            awful.layout.set(layouts[2])
                        end
                    end
                else
                    awful.layout.set(layouts[1])
                end
            end
        end),
    awful.key({ modkey,           }, "F2", function () awful.layout.set(layouts[3])   end),
    awful.key({ modkey,           }, "F3", function () awful.layout.set(layouts[4])   end),
    awful.key({ modkey,           }, "F4", function () awful.layout.set(layouts[5])   end),
    awful.key({ modkey,           }, "F5", function () awful.layout.set(layouts[6])   end),

    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey,           }, "i", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey,           }, "u", function () awful.screen.focus_relative(-1) end),
    --awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
                local clientGeometry = client.focus:geometry()
                local mouseCoords = {}
                mouseCoords.x = clientGeometry.x + clientGeometry.width - 20;
                mouseCoords.y = clientGeometry.y + clientGeometry.height - 20;
                mouse.coords(mouseCoords)
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "x", function () awful.util.spawn(terminal) end),
    awful.key({ modkey,           }, "n", function () awful.util.spawn(home.."/work/nuanceUrxvt.sh") end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Control" }, "q", awesome.quit),
    awful.key({ modkey, "Control" }, "Escape", function () os.execute("sudo systemctl suspend") end),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    --awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    --awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),
    awful.key({ modkey,           }, "space", function () awful.menu.clients({ theme = { height=25, width = 500 } }) end),
    --awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mymainmenu:toggle() end),
    awful.key({ modkey, "Shift" },   "r",     function () mypromptbox[mouse.screen]:run() end),
    awful.key({ }, "F13",
              function ()
                  local completeFunc = function(cmd, cur_pos, ncomp) return awful.completion.generic(cmd, cur_pos, ncomp, sharetags.tagnames) end
                  local keyPressFunc = function(mod, key, command)
                      compCommand, cur_pos, matches = completeFunc(command .. key, #command + 1, 1)
                      if matches and #matches == 1 then
                          return true, compCommand
                      else
                          return false
                      end
                  end
                  myprompt.run({ prompt = "Show label: ", autoexec=true },
                      mypromptbox[mouse.screen].widget,
                      function(name) 
                          sharetags.select_tag(sharetags.tags[name], mouse.screen)
                      end,
                      completeFunc,
                      nil, nil, nil, nil,
                      keyPressFunc)
              end),
    awful.key({ modkey }, "slash", function() 
            if awful.tag.selected(mouse.screen).name == "IM" then
                awful.tag.history.restore()
            else
                sharetags.select_tag(sharetags.tags["IM"], mouse.screen)
            end
        end),
    awful.key({ "Control" }, "F13", awful.tag.history.restore),
    awful.key({ "Shift" }, "F13",
              function ()
                  awful.prompt.run({ prompt = "Move to label: ", autoexec=true },
                      mypromptbox[mouse.screen].widget,
                      function(name) 
                          if client.focus then
                              awful.client.movetotag(sharetags.tags[name])
                          end
                      end,
                      function(cmd, cur_pos, ncomp)
                          return awful.completion.generic(cmd, cur_pos, ncomp, sharetags.tagnames)
                      end)
              end),
    awful.key({ modkey }, "F13",
              function ()
                  awful.prompt.run({ prompt = "Create label: "},
                      mypromptbox[mouse.screen].widget,
                      function(name) 
                          sharetags.add_tag(name, awful.layout.suit.tile)
                          sharetags.select_tag(sharetags.tags[name], mouse.screen)
                      end)
              end),

    awful.key({ modkey, "Control" }, "Return",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    --awful.key({ modkey }, "p", function() menubar.show() end)

    -- MPD control
    awful.key({ modkey }, "F9",  function() os.execute("mpc toggle") end),
    awful.key({ modkey }, "F10", function() os.execute("mpc stop") end),
    awful.key({ modkey }, "F11", function() os.execute("mpc prev") end),
    awful.key({ modkey }, "F12", function() os.execute("mpc next") end),

    -- Eject CD
    awful.key({}, "Multi_key", function() os.execute("eject") end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,           }, "q",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey,           }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey, "Shift"   }, "o",      awful.client.movetoscreen                        ),
    --awful.key({ modkey, "Shift"   }, "o",      function (c)
    --        local curidx = awful.tag.getidx()
    --        awful.client.movetoscreen(c)
    --        awful.client.movetotag(sharetags.tags[client.focus.screen][curidx], c)
    --    end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    --awful.key({ modkey,           }, "n",
    --    function (c)
    --        -- The client currently has the input focus, so it cannot be
    --        -- minimized, since minimized clients can't have the focus.
    --        c.minimized = true
    --    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Swapping screens, the monitor names change depending if we are on the laptop or not
if isNuanceLaptop then
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey,           }, "o",      function() sharetags.swap_screen(screen["VGA-0"].index, screen["VGA-1"].index) end)
    )
else
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey,           }, "o",      function() sharetags.swap_screen(screen[benqMonitor].index, screen[samsungMonitor].index) end)
    )
end

-- Jump to a specific window with the number keys
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
-- (taken from the default rc.lua)
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i+9,
            function()
                local clients = awful.client.tiled(mouse.screen)
                if clients[i] then
                    client.focus = clients[i]
                    clients[i]:raise()
                end
            end
    )
    )
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     maximized_vertical   = false,
                     maximized_horizontal = false,
                     buttons = clientbuttons,
                     size_hints_honor = false } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "XEyes" },
      properties = { floating = true, sticky = true,
                     skip_taskbar = true, border_width = 0,
                     focusable = false } },
    { rule = { name = "rdesktop - 10.0.0.5" },
      properties = { border_width = 0 } },
    { rule = { instance = "plugin-container" },
      properties = { floating = true } }
}

if sharetags.tags["Beamer"] then
    local beamerRules = {
        { rule = { class = "Google-chrome-stable" },
          properties = { tag = sharetags.tags["Beamer"] }
        },
        { rule = { class = "Kodi" },
          properties = { tag = sharetags.tags["Beamer"] }
        }
    }
    awful.rules.rules = awful.util.table.join(awful.rules.rules, beamerRules)
end
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

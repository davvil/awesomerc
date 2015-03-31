-- functions to share tags on multiple screens

--{{{ Grab environment we need
local capi = { screen = screen,
               client = client
               }

local pairs = pairs
local ipairs = ipairs
local tag = require("awful.tag")
local awful = require("awful")

local table = require("table")
local io = require("io")
local os = require("os")

--local naughty = require("naughty")
--local inspect = require("inspect")
--}}}

module("sharetags")

tags = {}
tagnames = {}
ntags = 0
menu = {} -- indexed by screen numbers


--[[
function dump(data)
    naughty.notify({ text = inspect(data) })
end
]]


--{{{ Private structures

--}}}

--{{{ Functions

--{{{ create_tags: create a table of tags and bind them to screens
-- @param names : list to label the tags
-- @param layouts : list of layouts for the tags
-- @return table of tag objects
function create_tags(names, layouts)
    local tags = {}
    local count = #names
    if capi.screen.count() >= #names then
        count = capi.screen.count() + 1
    end

    for tagnumber = 1, count do
        tags[tagnumber] = tag.add(names[tagnumber], {})
        tag.setproperty(tags[tagnumber], "number", tagnumber)
        -- Add tags to screen one by one
        tag.setscreen(tags[tagnumber], 1)

        awful.layout.set(layouts[tagnumber], tags[tagnumber])
    end
    return tags
end
--}}}

function add_tag(name, layout)
    local new_tag = tag.add(name, {})
    ntags = ntags + 1
    tag.setproperty(new_tag, "number", ntags)
    tag.setscreen(new_tag, 1)
    awful.layout.set(layout, new_tag)
    tags[name] = new_tag
    table.insert(tagnames, name)
    recreate_menus()
end

function recreate_menus()
    for s,_ in pairs(menu) do
        local menuitems = {}
        for n,t in pairs(tags) do
            table.insert(menuitems, {n, function() select_tag(t, s) end})
        end
        menu[s] = awful.menu({items = menuitems})
    end
end

function create_tag_menu(screen)
    menu[screen] = false
    recreate_menus()
end


--{{{ tag_move: move a tag to a screen
-- @param t : the tag object to move
-- @param screen_target : the screen object to move to
function tag_move(t, screen_target)

    local ts = t or tag.selected()

    if not screen_target then return end

    local current_screen = tag.getscreen(ts)

    if current_screen and screen_target ~= current_screen then
        -- switch for tag
        local mynumber = tag.getproperty(ts, "number")

        -- sort tags
        local index = #tag.gettags(screen_target)+1
        for i, screen_tag in pairs(tag.gettags(screen_target)) do
            local number = tag.getproperty(screen_tag, "number")
            if (mynumber < number) then
                index = i
                break
            end
        end

        -- save curren_screen tags
        local selected_tags = tag.selectedlist(current_screen)

        tag.setscreen(ts, screen_target)
        tag.move(index, ts)

        -- restore curren_screen tag
        tag.viewmore(selected_tags, current_screen)


        -- switch for all clients on tag
        if #ts:clients() > 0 then
            for _ , c in ipairs(ts:clients()) do
                if not c.sticky then
                    c.screen = screen_target
                    c:tags( {ts} )
                else
                    awful.client.toggletag(ts,c)
                end
            end
        end
    end
end
--}}}


-- Open tag on screen
function select_tag(t, target_screen)

    local tag_screen = tag.getscreen(t)

    if t.selected and target_screen ~= tag_screen and #tag.selectedlist(tag_screen) == 1 then
        swap_screen(tag_screen, target_screen)
    else
        tag_move(t, target_screen)
        tag.viewonly(t)
    end


    if #t:clients() > 0 then
        local c = t:clients()[1]
        capi.client.focus = c
    end

end

-- Toggle tag on screen
function toggle_tag(t, screen)
    if (tag.getscreen(t) ~= screen) then
        tag_move(t, screen)
        if not t.selected then
            tag.viewtoggle(t)
        end
    else
        tag.viewtoggle(t)
    end
end


-- Swap all tags between two screens
function swap_screen(screen1, screen2)

    local tags1 = tag.selectedlist(screen1)
    local tags2 = tag.selectedlist(screen2)

    tag. viewnone(screen1);
    tag. viewnone(screen2);

    for i, t in ipairs(tags1) do
        toggle_tag(t, screen2)
    end
    for i, t in ipairs(tags2) do
        toggle_tag(t, screen1)
    end
end

-- Write list of tags to file
function write_taglist(fname, skip)
    skip = skip or {}
    local fp = io.open(fname, "w")
    for _,t in pairs(tagnames) do
        if not skip[t] then
            fp:write(t, "\n")
        end
    end
    fp:close()
end

-- Restore list of tags from file
function restore_taglist(fname, removeFile)
    if removeFile == nil then
        removeFile = true
    end
    local fp = io.open(fname, "r")
    if not fp then return false end
    while true do
        local line = fp:read()
        if line == nil then break end
        add_tag(line, awful.layout.suit.tile)
    end
    if removeFile then
        os.remove(fname)
    end
    return true
end

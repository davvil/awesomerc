local twoPane = {}

twoPane.name = "twoPane"
function twoPane.arrange(p)
    local midX = p.workarea.width / 2
    local height = p.workarea.height
    local yIni = p.workarea.y
    local xIni = p.workarea.x

    for k, c in pairs(p.clients) do
        local geometry = {}
        geometry.width = midX - 2*c.border_width
        geometry.height = height - 2*c.border_width
        geometry.y = yIni
        if k == 1 then
            geometry.x = xIni + midX
        else
            geometry.x = xIni
        end
        c:geometry(geometry)
    end
end

return twoPane


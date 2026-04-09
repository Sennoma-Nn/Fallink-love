local config = require("src.config")
local locales = require("src.locales")
local uiButton = require("src.ui.button")

local TOP_BAR_HEIGHT = 92
local TOP_BAR_COLOR = { 39 / 255, 39 / 255, 39 / 255, 1 }
local TEXT_COLOR = { 1, 1, 1, 1 }
local BUTTON_COLOR = { 1, 1, 1, 0.2 }

local mapButton = {
    id = "map",
    size = 60,
    icon = "map",
    color = BUTTON_COLOR,
    name = "地图",
    description = "游戏关卡",
}

function load()
end

function update(dt)
end

function draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    love.graphics.clear(table.unpack(config.colors.background))
    love.graphics.setColor(table.unpack(TOP_BAR_COLOR))
    love.graphics.rectangle("fill", 0, 0, screenWidth, TOP_BAR_HEIGHT)
    
    drawMapButton(screenWidth, screenHeight)
end

function drawMapButton(screenWidth, screenHeight)
    uiButton.drawMapButton(mapButton, screenWidth, screenHeight, TOP_BAR_HEIGHT)
end

function keypressed(key)
    if key == "escape" then
        local main = require("main")
        main.switchState("home")
    end
end

function mousepressed(x, y, button)
    if button == 1 then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local buttonX, buttonY = uiButton.calcRightPosition(mapButton, screenWidth, TOP_BAR_HEIGHT)

        if uiButton.isClicked(mapButton, x, y, buttonX, buttonY) then
            local main = require("main")
            main.switchState("home")
            return
        end
    end
end

function mousemoved(x, y, dx, dy)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local buttonX, buttonY = uiButton.calcRightPosition(mapButton, screenWidth, TOP_BAR_HEIGHT)

    if uiButton.isHovered(mapButton, x, y, buttonX, buttonY) then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        love.mouse.setCursor()
    end
end

function mousereleased(x, y, button)
end

function wheelmoved(x, y)
end

return {
    load = load,
    update = update,
    draw = draw,
    keypressed = keypressed,
    mousepressed = mousepressed,
    mousemoved = mousemoved,
    mousereleased = mousereleased,
    wheelmoved = wheelmoved
}
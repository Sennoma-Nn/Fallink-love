local titleImage, promptFont
local blinkTimer = 0
local config = require("src.config")
local locales = require("src.locales")

function load()
    titleImage = love.graphics.newImage("src/img/title/title.png")
    promptFont = love.graphics.newFont(locales.getFontPath(), config.fonts.sizes.small)
end

function update(dt)
    blinkTimer = blinkTimer + dt
    if blinkTimer >= 3.2 then
        blinkTimer = blinkTimer - 3.2
    end
end

function draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local originalWidth = titleImage:getWidth()
    local targetWidth = w * 0.5
    local scale = targetWidth / originalWidth
    local phase = (blinkTimer / 3.2) * 2 * math.pi
    local alpha = (math.sin(phase - math.pi/2) + 1) / 2
    local promptColor = {table.unpack(config.colors.prompt)}; promptColor[4] = alpha
    local promptText = locales.get("title", "prompt")
    local promptWidth = promptFont:getWidth(promptText)

    love.graphics.clear(table.unpack(config.colors.background))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(titleImage, (w - targetWidth) / 2, h * 0.2, 0, scale, scale)
    love.graphics.setFont(promptFont)
    love.graphics.setColor(promptColor)
    love.graphics.print(promptText, (w - promptWidth) / 2, h * 0.7)
end

function keypressed(key)
    if key == "space" then
        local main = require("main")
        main.switchState("home")
    end
end

function mousepressed(x, y, button)
    local main = require("main")
    main.switchState("home")
end

return {
    load = load,
    update = update,
    draw = draw,
    keypressed = keypressed,
    mousepressed = mousepressed
}

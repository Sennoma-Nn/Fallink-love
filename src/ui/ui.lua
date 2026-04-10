local button = {}
local config = require("src.config")

local tooltipFont = nil
local panelTitleFont = nil
local panelDescFont = nil
local languageFont = nil
local arrowFont = nil
local promptFont = nil

function button.preloadIcon(btn)
    if btn.icon and not btn.iconImage then
        local iconPath = "src/img/icon/" .. btn.icon .. ".png"
        btn.iconImage = love.graphics.newImage(iconPath)
    end
end

function button.draw(btn, x, y)
    local halfSize = btn.size / 2
    local radius = 4
    
    love.graphics.setColor(table.unpack(btn.color))
    love.graphics.rectangle("fill", x - halfSize, y - halfSize, btn.size, btn.size, radius)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", x - halfSize, y - halfSize, btn.size, btn.size, radius)
    
    if btn.icon and btn.iconImage then
        local iconSize = btn.size
        local scale = iconSize / math.max(btn.iconImage:getWidth(), btn.iconImage:getHeight())

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            btn.iconImage,
            x, y, 0,
            scale, scale,
            btn.iconImage:getWidth() / 2,
            btn.iconImage:getHeight() / 2
        )
    end
    
    return x, y
end

function button.calcRightPosition(btn, screenWidth, topBarHeight)
    local halfSize = btn.size / 2
    local buttonX = screenWidth - halfSize - 16
    local buttonY = topBarHeight / 2
    return buttonX, buttonY
end

function button.isClicked(btn, x, y, buttonX, buttonY)
    local halfSize = btn.size / 2
    return x >= buttonX - halfSize and x <= buttonX + halfSize and
           y >= buttonY - halfSize and y <= buttonY + halfSize
end

function button.isHovered(btn, x, y, buttonX, buttonY)
    return button.isClicked(btn, x, y, buttonX, buttonY)
end


function button.initTooltipFont(fontPath, fontSize)
    if not tooltipFont then
        tooltipFont = love.graphics.newFont(fontPath, fontSize)
    end
end

function button.drawTooltip(btn, mouseX, mouseY)
    if not tooltipFont then
        return
    end
    
    local padding = 8
    local text = btn.tip or btn.name or ""
    local textWidth = tooltipFont:getWidth(text)
    local textHeight = tooltipFont:getHeight()
    local bubbleWidth = textWidth + padding * 2
    local bubbleHeight = textHeight + padding * 2
    local bubbleX = mouseX + 20
    local bubbleY = mouseY + 20
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    if bubbleX + bubbleWidth > screenWidth then
        bubbleX = mouseX - bubbleWidth - 20
    end
    if bubbleY + bubbleHeight > screenHeight then
        bubbleY = mouseY - bubbleHeight - 20
    end

    love.graphics.setColor(table.unpack(config.colors.tooltip_bg))
    love.graphics.rectangle("fill", bubbleX, bubbleY, bubbleWidth, bubbleHeight, 4)
    love.graphics.setColor(table.unpack(config.colors.tooltip_border))
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", bubbleX, bubbleY, bubbleWidth, bubbleHeight, 4)
    love.graphics.setColor(table.unpack(config.colors.tooltip_text))
    love.graphics.setFont(tooltipFont)
    love.graphics.print(text, bubbleX + padding, bubbleY + padding)
end

function button.reloadFonts()
    local locales = require("src.locales")
    local config = require("src.config")
    local fontPath = locales.getFontPath()
    
    -- print("reloadFonts")
    tooltipFont = love.graphics.newFont(fontPath, config.fonts.sizes.small)
end

function button.getFont(sizeName)
    local locales = require("src.locales")
    local config = require("src.config")
    local fontPath = locales.getFontPath()
    
    local size = config.fonts.sizes[sizeName]
    return love.graphics.newFont(fontPath, size)
end

function button.getTooltipFont()
    return tooltipFont
end

return button

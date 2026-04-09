local button = {}

local BUTTON_COLOR = { 1, 1, 1, 0.2 }

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

function button.drawSettingsButton(btn, screenWidth, screenHeight, topBarHeight)
    local buttonX, buttonY = button.calcRightPosition(btn, screenWidth, topBarHeight)
    return button.draw(btn, buttonX, buttonY)
end

function button.drawMapButton(btn, screenWidth, screenHeight, topBarHeight)
    local buttonX, buttonY = button.calcRightPosition(btn, screenWidth, topBarHeight)
    return button.draw(btn, buttonX, buttonY)
end

return button
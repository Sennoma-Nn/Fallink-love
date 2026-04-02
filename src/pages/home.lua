local config = require("src.config")
local cameraX = 0
local cameraY = 0
local zoom = 1.0
local displayZoom = 1.0
local isDragging = false
local hoveredButton = nil
local tooltipFont = nil

local buttons = {
    {
        id = 1,
        x = 0,
        y = 0,
        size = 80,
        name = "Test Level - 1",
        description = "Test",
        icon = nil,
        color = { 1, 1, 1, 0.2 },
        link = {
            right = 2
        }
    },
    {
        id = 2,
        x = 360,
        y = 0,
        size = 80,
        name = "Test Level - 2",
        description = "Test",
        icon = nil,
        color = { 1, 1, 1, 0.2 },
        link = {
            left = 1,
            top = 3,
            bottom = 4
        }
    },
    {
        id = 3,
        x = 360 * 2,
        y = -180,
        size = 80,
        name = "Test Level - 3",
        description = "Test",
        icon = nil,
        color = { 1, 1, 1, 0.2 },
        link = {
            left = 2,
            right = 3.1
        }
    },
    {
        id = 3.1,
        x = 360 * 3,
        y = -180,
        size = 80,
        name = "Test Level - 3.1",
        description = "Test",
        icon = nil,
        color = { 1, 1, 1, 0.2 },
        link = {
            left = 3
        }
    },
    {
        id = 4,
        x = 360 * 2,
        y = 180,
        size = 80,
        name = "Test Level - 4",
        description = "Test",
        icon = nil,
        color = { 1, 1, 1, 0.2 },
        link = {
            left = 2,
            right = 4.1
        }
    },
    {
        id = 4.1,
        x = 360 * 3,
        y = 180,
        size = 80,
        name = "Test Level - 4.1",
        description = "Test",
        icon = nil,
        color = { 1, 1, 1, 0.2 },
        link = {
            left = 4,
            right = 5
        }
    },
    {
        id = 5,
        x = 360 * 4,
        y = 0,
        size = 80,
        name = "Test Level - 5",
        description = "Test",
        icon = nil,
        color = { 1, 1, 1, 0.2 },
        link = {
            bottom = 4.1
        }
    }
}

local dragStartX = 0
local dragStartY = 0
local dragThreshold = 12

function load()
    cameraX = 0
    cameraY = 0
    zoom = 1.0
    isDragging = false
end

function update(dt)
    local diff = zoom - displayZoom
    if math.abs(diff) < 0.01 then
        displayZoom = zoom
    else
        displayZoom = displayZoom + diff / 10
    end
end

function worldToScreen(worldX, worldY)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local screenX = (worldX - cameraX) * zoom + screenWidth / 2
    local screenY = (worldY - cameraY) * zoom + screenHeight / 2
    return screenX, screenY
end

function screenToWorld(screenX, screenY)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local worldX = (screenX - screenWidth / 2) / zoom + cameraX
    local worldY = (screenY - screenHeight / 2) / zoom + cameraY
    return worldX, worldY
end

function draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    love.graphics.clear(table.unpack(config.colors.background))
    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 2)
    love.graphics.scale(displayZoom, displayZoom)
    love.graphics.translate(-cameraX, -cameraY)

    drawAllArrows()
    for _, button in ipairs(buttons) do
        drawButton(button)
    end

    love.graphics.pop()

    if hoveredButton then
        local mouseX, mouseY = love.mouse.getPosition()
        drawTooltip(hoveredButton, mouseX, mouseY)
    end
end

function drawButton(button)
    local halfSize = button.size / 2

    love.graphics.setColor(table.unpack(button.color))
    love.graphics.rectangle("fill", button.x - halfSize, button.y - halfSize, button.size, button.size)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x - halfSize, button.y - halfSize, button.size, button.size)
end

function keypressed(key)
    if key == "escape" then
        local main = require("main")
        main.switchState("title")
    end
end

function mousepressed(x, y, button)
    if button == 1 then
        dragStartX = x
        dragStartY = y
        isDragging = true
    end
end

function mousemoved(x, y, dx, dy)
    if isDragging then
        local worldDx = dx / displayZoom
        cameraX = cameraX - worldDx
    else
        local worldX, worldY = screenToWorld(x, y)
        hoveredButton = nil

        for _, button in ipairs(buttons) do
            local halfSize = button.size / 2

            if worldX >= button.x - halfSize and worldX <= button.x + halfSize and
                worldY >= button.y - halfSize and worldY <= button.y + halfSize then
                hoveredButton = button
                break
            end
        end
    end
end

function mousereleased(x, y, button)
    if button == 1 then
        isDragging = false

        local moveX = math.abs(x - dragStartX)
        local moveY = math.abs(y - dragStartY)
        local totalMove = math.sqrt(moveX * moveX + moveY * moveY)

        if totalMove < dragThreshold then
            local worldX, worldY = screenToWorld(x, y)
            checkButtonClick(worldX, worldY)
        end
    end
end

function wheelmoved(x, y)
    local zoomStep = 0.4
    local minZoom = 0.2
    local maxZoom = 5.0

    if y > 0 then
        zoom = math.min(maxZoom, zoom + zoomStep)
    elseif y < 0 then
        zoom = math.max(minZoom, zoom - zoomStep)
    end
end

function checkButtonClick(worldX, worldY)
    for _, button in ipairs(buttons) do
        local halfSize = button.size / 2

        if worldX >= button.x - halfSize and worldX <= button.x + halfSize and
            worldY >= button.y - halfSize and worldY <= button.y + halfSize then
            print("点击按钮: " .. button.name)
            return true
        end
    end
    return false
end

function getButtonById(id)
    for _, button in ipairs(buttons) do
        if button.id == id then
            return button
        end
    end
    return nil
end

function drawArrowWithStartDirection(fromButton, toButton, startDirection)
    local fromX, fromY = fromButton.x, fromButton.y
    local toX, toY = toButton.x, toButton.y

    local dx = toX - fromX
    local dy = toY - fromY

    local halfSize = fromButton.size / 2
    local gap = 12
    local startX, startY

    if startDirection == "right" then
        startX = fromX + halfSize + gap
        startY = fromY
    elseif startDirection == "left" then
        startX = fromX - halfSize - gap
        startY = fromY
    elseif startDirection == "top" then
        startX = fromX
        startY = fromY - halfSize - gap
    elseif startDirection == "bottom" then
        startX = fromX
        startY = fromY + halfSize + gap
    end

    local endDirection

    if startDirection == "right" then
        if dy < 0 then
            endDirection = "bottom"
        else
            endDirection = "left"
        end
    elseif startDirection == "left" then
        if dy < 0 then
            endDirection = "bottom"
        else
            endDirection = "right"
        end
    elseif startDirection == "top" then
        if dx > 0 then
            endDirection = "left"
        else
            endDirection = "bottom"
        end
    elseif startDirection == "bottom" then
        if dx > 0 then
            endDirection = "left"
        else
            endDirection = "top"
        end
    end

    local endX, endY

    if endDirection == "right" then
        endX = toX + halfSize + gap
        endY = toY
    elseif endDirection == "left" then
        endX = toX - halfSize - gap
        endY = toY
    elseif endDirection == "top" then
        endX = toX
        endY = toY - halfSize - gap
    elseif endDirection == "bottom" then
        endX = toX
        endY = toY + halfSize + gap
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(4)

    if startX ~= endX and startY ~= endY then
        local midX, midY

        if startDirection == "top" or startDirection == "bottom" then
            midX = startX
            midY = endY
        else
            midX = endX
            midY = startY
        end

        love.graphics.line(startX, startY, midX, midY)
        love.graphics.line(midX, midY, endX, endY)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", midX - halfSquare, midY - halfSquare, squareSize, squareSize)
        local squareSize = 4
        local halfSquare = squareSize / 2
    else
        love.graphics.line(startX, startY, endX, endY)
    end
end

function drawAllArrows()
    local drawnConnections = {}

    for _, fromButton in ipairs(buttons) do
        if fromButton.link then
            for startDirection, toId in pairs(fromButton.link) do
                local toButton = getButtonById(toId)
                if toButton then
                    local connectionId1 = fromButton.id .. "-" .. toButton.id
                    local connectionId2 = toButton.id .. "-" .. fromButton.id
                    if not drawnConnections[connectionId1] and not drawnConnections[connectionId2] then
                        drawArrowWithStartDirection(fromButton, toButton, startDirection)
                        drawnConnections[connectionId1] = true
                    end
                end
            end
        end
    end
end

function drawTooltip(button, mouseX, mouseY)
    local padding = 8
    local backgroundColor = { 0.1, 0.1, 0.1, 0.95 }
    local textColor = { 1, 1, 1, 1 }
    local borderColor = { 0.3, 0.3, 0.3, 1 }

    if not tooltipFont then
        local config = require("src.config")
        local fontPath = config.fonts.path
        local fontSize = config.fonts.sizes.small
        tooltipFont = love.graphics.newFont(fontPath, fontSize)
    end

    local text = button.name
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

    love.graphics.setColor(table.unpack(backgroundColor))
    love.graphics.rectangle("fill", bubbleX, bubbleY, bubbleWidth, bubbleHeight, 4)
    love.graphics.setColor(table.unpack(borderColor))
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", bubbleX, bubbleY, bubbleWidth, bubbleHeight, 4)
    love.graphics.setColor(table.unpack(textColor))
    love.graphics.setFont(tooltipFont)
    love.graphics.print(text, bubbleX + padding, bubbleY + padding)
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

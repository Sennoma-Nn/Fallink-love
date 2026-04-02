local config = require("src.config")
local cameraX = 0
local cameraY = 0
local zoom = 1.0
local displayZoom = 1.0
local isDragging = false
local hoveredButton = nil
local tooltipFont = nil
local selectedButton = nil
local overlayAlpha = 0
local panelY = 0
local animationTime = 0
local isPanelVisible = false
local isAnimationComplete = false
local isClosing = false
local closeAnimationTime = 0

local PANEL_BG_COLOR = { 0.1, 0.1, 0.1, 0.95 }
local PANEL_BORDER_COLOR = { 0.3, 0.3, 0.3, 0.95 }
local TOOLTIP_BG_COLOR = { 0.1, 0.1, 0.1, 0.95 }
local TOOLTIP_BORDER_COLOR = { 0.3, 0.3, 0.3, 1 }
local TOOLTIP_TEXT_COLOR = { 1, 1, 1, 1 }
local PANEL_TITLE_COLOR = { 0.9, 0.9, 0.9, 1 }
local PANEL_DESC_COLOR = { 0.8, 0.8, 0.8, 1 }

local buttons = {
    {
        id = 1,
        x = 0,
        y = 0,
        size = 80,
        name = "Test Level - 1",
        description = "Test",
        icon = "test_icon",
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
        icon = "test_icon",
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
        icon = "test_icon",
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
        icon = "test_icon",
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
        icon = "test_icon",
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
        icon = "test_icon",
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
        icon = "test_icon",
        color = { 1, 1, 1, 0.2 },
        link = {
            bottom = 4.1
        }
    }
}

local dragStartX = 0
local dragStartY = 0
local dragThreshold = 12

local function easeOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

local ANIMATION_DURATION = 0.3
local OVERLAY_MAX_ALPHA = 0.4
local PANEL_TARGET_Y_RATIO = 0.2

local function updatePanelAnimation(dt)
    if isClosing then
        closeAnimationTime = closeAnimationTime + dt
        local closeProgress = math.min(closeAnimationTime / ANIMATION_DURATION, 1)

        if closeProgress < 1 then
            local easedCloseProgress = easeOutQuad(closeProgress)
            local screenHeight = love.graphics.getHeight()
            local startY = screenHeight * PANEL_TARGET_Y_RATIO
            panelY = startY + (screenHeight - startY) * easedCloseProgress
            overlayAlpha = OVERLAY_MAX_ALPHA * (1 - easedCloseProgress)
        else
            isPanelVisible = false
            isClosing = false
            selectedButton = nil
            isAnimationComplete = false
            overlayAlpha = 0
        end
    else
        animationTime = animationTime + dt
        local progress = math.min(animationTime / ANIMATION_DURATION, 1)
        if progress < 1 then
            local easedProgress = easeOutQuad(progress)
            local screenHeight = love.graphics.getHeight()
            local targetY = screenHeight * PANEL_TARGET_Y_RATIO
            overlayAlpha = OVERLAY_MAX_ALPHA * easedProgress
            panelY = screenHeight - (screenHeight - targetY) * easedProgress
            isAnimationComplete = false
        else
            local screenHeight = love.graphics.getHeight()
            overlayAlpha = OVERLAY_MAX_ALPHA
            panelY = screenHeight * PANEL_TARGET_Y_RATIO
            isAnimationComplete = true
        end
    end
end

function load()
    cameraX = 0
    cameraY = 0
    zoom = 1.0
    isDragging = false
end

function update(dt)
    local diff = zoom - displayZoom
    displayZoom = displayZoom + diff / 10

    if isPanelVisible then
        updatePanelAnimation(dt)
    else
        isAnimationComplete = false
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

    if isPanelVisible and selectedButton then
        drawPanel()
    end
end

function drawButton(button)
    local halfSize = button.size / 2
    local radius = 4

    love.graphics.setColor(table.unpack(button.color))
    love.graphics.rectangle("fill", button.x - halfSize, button.y - halfSize, button.size, button.size, radius)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", button.x - halfSize, button.y - halfSize, button.size, button.size, radius)

    if button.icon then
        if not button.iconImage then
            local iconPath = "src/img/icon/" .. button.icon .. ".png"
            button.iconImage = love.graphics.newImage(iconPath)
        end

        if button.iconImage then
            local iconSize = button.size
            local scale = iconSize / math.max(button.iconImage:getWidth(), button.iconImage:getHeight())

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                button.iconImage,
                button.x, button.y, 0,
                scale, scale,
                button.iconImage:getWidth() / 2,
                button.iconImage:getHeight() / 2
            )
        end
    end
end

function keypressed(key)
    if key == "escape" then
        local main = require("main")
        main.switchState("title")
    end
end

function mousepressed(x, y, button)
    if button == 1 then
        if isPanelVisible and (not isAnimationComplete or isClosing) then
            return
        end

        if isPanelVisible and selectedButton and isAnimationComplete then
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            local panelWidth = screenWidth * 0.8
            local panelHeight = screenHeight * 0.9
            local panelX = (screenWidth - panelWidth) / 2
            local isClickOnPanel = x >= panelX and x <= panelX + panelWidth and y >= panelY and y <= panelY + panelHeight

            if isClickOnPanel then
                return
            else
                isClosing = true
                closeAnimationTime = 0
                return
            end
        end

        dragStartX = x
        dragStartY = y
        isDragging = true
    end
end

function mousemoved(x, y, dx, dy)
    if isPanelVisible and not isAnimationComplete then
        hoveredButton = nil
        return
    end

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
        if isPanelVisible and not isAnimationComplete then
            isDragging = false
            return
        end

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
    if isPanelVisible and not isAnimationComplete then
        return
    end

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
            -- print("点击按钮: " .. button.name)

            local screenHeight = love.graphics.getHeight()

            selectedButton = button
            isPanelVisible = true
            animationTime = 0
            overlayAlpha = 0
            panelY = screenHeight

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

        local squareSize = 4
        local halfSquare = squareSize / 2

        love.graphics.line(startX, startY, midX, midY)
        love.graphics.line(midX, midY, endX, endY)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", midX - halfSquare, midY - halfSquare, squareSize, squareSize)
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

function drawPanel()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local panelWidth = screenWidth * 0.8
    local panelHeight = screenHeight * 0.9
    local panelX = (screenWidth - panelWidth) / 2

    love.graphics.setColor(0, 0, 0, overlayAlpha)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setColor(table.unpack(PANEL_BG_COLOR))
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 12)
    love.graphics.setColor(table.unpack(PANEL_BORDER_COLOR))
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 12)

    drawPanelContent(selectedButton, panelX, panelY, panelWidth, panelHeight)
end

function drawTooltip(button, mouseX, mouseY)
    local padding = 8
    local backgroundColor = TOOLTIP_BG_COLOR
    local textColor = TOOLTIP_TEXT_COLOR
    local borderColor = TOOLTIP_BORDER_COLOR

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

function drawPanelContent(button, panelX, panelY, panelWidth, panelHeight)
    local padding = 40
    local contentX = panelX + padding
    local contentY = panelY + padding
    local contentWidth = panelWidth - padding * 2
    local config = require("src.config")
    local fontPath = config.fonts.path
    local titleFont = love.graphics.newFont(fontPath, 36)
    local descFont = love.graphics.newFont(fontPath, 24)
    local titleHeight = titleFont:getHeight()
    local currentY = contentY + titleHeight + 30

    love.graphics.setColor(table.unpack(PANEL_TITLE_COLOR))
    love.graphics.setFont(titleFont)
    love.graphics.print(button.name, contentX, contentY)
    love.graphics.setColor(table.unpack(PANEL_DESC_COLOR))
    love.graphics.setFont(descFont)
    love.graphics.printf(button.description, contentX, currentY, contentWidth, "left")
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

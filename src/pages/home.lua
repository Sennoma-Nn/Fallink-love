local config = require("src.config")
local locales = require("src.locales")
local uiButton = require("src.ui")
local utils = require("src.utils")

local switchStateCallback = nil
local cameraX = 0
local cameraY = 0
local zoom = 1.0
local displayZoom = 1.0
local isDragging = false
local hoveredButton = nil
local panelTitleFont = nil
local panelDescFont = nil
local closeIcon = nil
local selectedButton = nil
local overlayAlpha = 0
local panelY = 0
local animationTime = 0
local isPanelVisible = false
local isAnimationComplete = false
local isClosing = false
local closeAnimationTime = 0

local TOP_BAR_HEIGHT = 92
local LEVEL_BUTTON_SIZE = 80;

local buttons = {
    {
        id = 1,
        x = 0,
        y = 0,
        size = LEVEL_BUTTON_SIZE,
        name = function() return locales.get("levels", "test_level").name end,
        description = function() return locales.get("levels", "test_level").description end,
        icon = "test_icon",
        color = config.colors.button,
        link = {
            right = 2
        }
    },
    {
        id = 2,
        x = 360,
        y = 0,
        size = LEVEL_BUTTON_SIZE,
        name = "Test Level - 2",
        description = "Test",
        icon = "test_icon",
        color = config.colors.button,
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
        size = LEVEL_BUTTON_SIZE,
        name = "Test Level - 3",
        description = "Test",
        icon = "test_icon",
        color = config.colors.button,
        link = {
            left = 2,
            right = 3.1
        }
    },
    {
        id = 3.1,
        x = 360 * 3,
        y = -180,
        size = LEVEL_BUTTON_SIZE,
        name = "Test Level - 3.1",
        description = "Test",
        icon = "test_icon",
        color = config.colors.button,
        link = {
            left = 3
        }
    },
    {
        id = 4,
        x = 360 * 2,
        y = 180,
        size = LEVEL_BUTTON_SIZE,
        name = "Test Level - 4",
        description = "Test",
        icon = "test_icon",
        color = config.colors.button,
        link = {
            left = 2,
            right = 4.1
        }
    },
    {
        id = 4.1,
        x = 360 * 3,
        y = 180,
        size = LEVEL_BUTTON_SIZE,
        name = "Test Level - 4.1",
        description = "Test",
        icon = "test_icon",
        color = config.colors.button,
        link = {
            left = 4,
            right = 5
        }
    },
    {
        id = 5,
        x = 360 * 4,
        y = 0,
        size = LEVEL_BUTTON_SIZE,
        name = "Test Level - 5",
        description = "Test",
        icon = "test_icon",
        color = config.colors.button,
        link = {
            bottom = 4.1
        }
    }
}

local settingsButton = {
    id = "settings",
    size = 60,
    icon = "settings",
    color = config.colors.button,
    tip = function() return locales.get("tips", "settings") end,
}

local dragStartX = 0
local dragStartY = 0
local dragThreshold = 12

local ANIMATION_DURATION = 0.3
local OVERLAY_MAX_ALPHA = 0.4

local function updatePanelAnimation(dt)
    if isClosing then
        closeAnimationTime = closeAnimationTime + dt
        local closeProgress = math.min(closeAnimationTime / ANIMATION_DURATION, 1)

        if closeProgress < 1 then
            local easedCloseProgress = utils.easeOutQuad(closeProgress)
            local screenHeight = love.graphics.getHeight()
            local startY = TOP_BAR_HEIGHT + 16
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
            local easedProgress = utils.easeOutQuad(progress)
            local screenHeight = love.graphics.getHeight()
            local targetY = TOP_BAR_HEIGHT + 16
            overlayAlpha = OVERLAY_MAX_ALPHA * easedProgress
            panelY = screenHeight - (screenHeight - targetY) * easedProgress
            isAnimationComplete = false
        else
            local screenHeight = love.graphics.getHeight()
            overlayAlpha = OVERLAY_MAX_ALPHA
            panelY = TOP_BAR_HEIGHT + 16
            isAnimationComplete = true
        end
    end
end

local languageChangeCallback = nil

local function reloadFonts()
    -- print("111 reloadFonts")
    panelTitleFont = uiButton.getFont("large")
    panelDescFont = uiButton.getFont("small")
end

function load(switchState)
    switchStateCallback = switchState
    cameraX = 0
    cameraY = 0
    zoom = 1.0
    isDragging = false

    uiButton.preloadIcon(settingsButton)

    for _, button in ipairs(buttons) do
        if button.icon and not button.iconImage then
            local iconPath = "src/img/icon/" .. button.icon .. ".png"
            button.iconImage = love.graphics.newImage(iconPath)
        end
    end

    local closeIconPath = "src/img/icon/X.png"
    local file = love.filesystem.getInfo(closeIconPath)
    if file then
        closeIcon = love.graphics.newImage(closeIconPath)
    end

    if languageChangeCallback then
        locales.removeLanguageChangeCallback(languageChangeCallback)
    end

    languageChangeCallback = function(langCode)
        -- print("222 " .. langCode)
        reloadFonts()
    end

    reloadFonts()
    locales.addLanguageChangeCallback(languageChangeCallback)
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
    local screenY = (worldY - cameraY) * zoom + screenHeight / 2 + TOP_BAR_HEIGHT / 2
    return screenX, screenY
end

function screenToWorld(screenX, screenY)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local worldX = (screenX - screenWidth / 2) / zoom + cameraX
    local worldY = (screenY - screenHeight / 2 - TOP_BAR_HEIGHT / 2) / zoom + cameraY
    return worldX, worldY
end

function draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    love.graphics.clear(table.unpack(config.colors.background))

    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 2 + TOP_BAR_HEIGHT / 2)
    love.graphics.scale(displayZoom, displayZoom)
    love.graphics.translate(-cameraX, -cameraY)

    drawAllArrows()
    for _, button in ipairs(buttons) do
        drawButton(button)
    end

    love.graphics.pop()

    drawTopBar(screenWidth, screenHeight)

    local buttonX, buttonY = uiButton.calcRightPosition(settingsButton, screenWidth, TOP_BAR_HEIGHT)
    uiButton.draw(settingsButton, buttonX, buttonY)

    if isPanelVisible and selectedButton then
        drawPanel()
    end

    if hoveredButton then
        local mouseX, mouseY = love.mouse.getPosition()
        drawTooltip(hoveredButton, mouseX, mouseY)
    end
end

function drawButton(button)
    uiButton.draw(button, button.x, button.y)
end

function keypressed(key)
end

function mousepressed(x, y, button)
    if button == 1 then
        if isPanelVisible and (not isAnimationComplete or isClosing) then
            return
        end

        if isPanelVisible and selectedButton and isAnimationComplete then
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            local panelWidth = screenWidth - 32
            local panelHeight = screenHeight
            local panelX = (screenWidth - panelWidth) / 2
            local buttonSize = 32
            local closeButtonX = panelX + panelWidth - 16 - buttonSize
            local closeButtonY = panelY + 16

            if x >= closeButtonX and x <= closeButtonX + buttonSize and
                y >= closeButtonY and y <= closeButtonY + buttonSize then
                isClosing = true
                closeAnimationTime = 0
                return
            end

            local isClickOnPanel = x >= panelX and x <= panelX + panelWidth and y >= panelY and y <= panelY + panelHeight

            if isClickOnPanel then
                return
            else
                isClosing = true
                closeAnimationTime = 0
                return
            end
        end

        local button = settingsButton
        local buttonX, buttonY = uiButton.calcRightPosition(button, love.graphics.getWidth(), TOP_BAR_HEIGHT)

        if uiButton.isClicked(button, x, y, buttonX, buttonY) then
            dragStartX = x
            dragStartY = y
            isDragging = false
            hoveredButton = nil
            return
        end

        if y < TOP_BAR_HEIGHT then
            return
        end

        dragStartX = x
        dragStartY = y
        isDragging = true
        hoveredButton = nil
    end
end

function mousemoved(x, y, dx, dy)
    if isPanelVisible then
        if selectedButton and isAnimationComplete then
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            local panelWidth = screenWidth - 32
            local panelHeight = screenHeight
            local panelX = (screenWidth - panelWidth) / 2
            local buttonSize = 32
            local closeButtonX = panelX + panelWidth - 16 - buttonSize
            local closeButtonY = panelY + 16

            if x >= closeButtonX and x <= closeButtonX + buttonSize and
                y >= closeButtonY and y <= closeButtonY + buttonSize then
                love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            else
                love.mouse.setCursor()
            end
        else
            love.mouse.setCursor()
        end
        hoveredButton = nil
        return
    end

    if isDragging then
        local worldDx = dx / displayZoom
        cameraX = cameraX - worldDx
        love.mouse.setCursor()
    else
        local button = settingsButton
        local buttonX, buttonY = uiButton.calcRightPosition(button, love.graphics.getWidth(), TOP_BAR_HEIGHT)

        if uiButton.isHovered(button, x, y, buttonX, buttonY) then
            hoveredButton = button
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
        elseif y >= TOP_BAR_HEIGHT then
            local worldX, worldY = screenToWorld(x, y)
            hoveredButton = nil

            for _, button in ipairs(buttons) do
                local halfSize = button.size / 2

                if worldX >= button.x - halfSize and worldX <= button.x + halfSize and
                    worldY >= button.y - halfSize and worldY <= button.y + halfSize then
                    hoveredButton = button
                    love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
                    break
                end
            end

            if not hoveredButton then
                love.mouse.setCursor()
            end
        else
            hoveredButton = nil
            love.mouse.setCursor()
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
            local button = settingsButton
            local buttonX, buttonY = uiButton.calcRightPosition(button, love.graphics.getWidth(), TOP_BAR_HEIGHT)

            if uiButton.isClicked(button, x, y, buttonX, buttonY) then
                if switchStateCallback then
                    switchStateCallback("settings")
                end
                return
            end

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
    if isPanelVisible or isClosing then
        return false
    end

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
    local panelWidth = screenWidth - 32
    local panelHeight = screenHeight
    local panelX = (screenWidth - panelWidth) / 2

    love.graphics.setColor(0, 0, 0, overlayAlpha)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setColor(table.unpack(config.colors.panel_bg))
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 12)
    love.graphics.setColor(table.unpack(config.colors.panel_border))
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 12)

    drawPanelContent(selectedButton, panelX, panelY, panelWidth, panelHeight)
    drawCloseButton(panelX, panelY, panelWidth)
end

function drawTooltip(button, mouseX, mouseY)
    uiButton.drawTooltip(button, mouseX, mouseY)
end

function drawPanelContent(button, panelX, panelY, panelWidth, panelHeight)
    local padding = 40
    local contentX = panelX + padding
    local contentY = panelY + padding
    local contentWidth = panelWidth - padding * 2
    local titleHeight = panelTitleFont:getHeight()
    local currentY = contentY + titleHeight + 30
    local buttonName = utils.getValue(button.name)
    local buttonDescription = utils.getValue(button.description)

    love.graphics.setColor(table.unpack(config.colors.panel_title))
    love.graphics.setFont(panelTitleFont)
    love.graphics.print(buttonName, contentX, contentY)
    love.graphics.setColor(table.unpack(config.colors.panel_desc))
    love.graphics.setFont(panelDescFont)
    love.graphics.printf(buttonDescription, contentX, currentY, contentWidth, "left")
end

function drawTopBar(screenWidth, screenHeight)
    love.graphics.setColor(table.unpack(config.colors.top_bar))
    love.graphics.rectangle("fill", 0, 0, screenWidth, TOP_BAR_HEIGHT)
end

function drawCloseButton(panelX, panelY, panelWidth)
    local buttonSize = 32
    local buttonX = panelX + panelWidth - 16 - buttonSize
    local buttonY = panelY + 16

    if closeIcon then
        local scale = buttonSize / math.max(closeIcon:getWidth(), closeIcon:getHeight())
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            closeIcon,
            buttonX + buttonSize / 2, buttonY + buttonSize / 2, 0,
            scale, scale,
            closeIcon:getWidth() / 2,
            closeIcon:getHeight() / 2
        )
    end
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

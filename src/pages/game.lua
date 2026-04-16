local well = {}

local GHOST_MOVE_SPEED = 4

math.randomseed(os.time())

function getRandomBlock()
    return math.random(2) == 1 and "V" or "H"
end

function getRandomBlockGroup()
    local group = {}
    local isValid = false

    while not isValid do
        for i = 1, 2 do
            group[i] = {}
            for j = 1, 2 do
                group[i][j] = getRandomBlock()
            end
        end

        local isPattern1 = group[1][1] == "V" and group[1][2] == "H" and group[2][1] == "H" and group[2][2] == "V"
        local isPattern2 = group[1][1] == "H" and group[1][2] == "V" and group[2][1] == "V" and group[2][2] == "H"
        isValid = not (isPattern1 or isPattern2)
    end

    local currentGroup = group
    for _ = 1, 4 do
        if currentGroup[1][1] == "H" and currentGroup[1][2] == "H" then
            return currentGroup
        end
        currentGroup = rotateBlockGroup(currentGroup, "R")
    end

    return group
end

function rotateBlockGroup(group, direction)
    local newGroup = { {}, {} }

    if direction == "0" then
        newGroup[1][1] = group[1][1]
        newGroup[1][2] = group[1][2]
        newGroup[2][1] = group[2][1]
        newGroup[2][2] = group[2][2]
    elseif direction == "R" then
        newGroup[1][2] = invertBlock(group[1][1])
        newGroup[2][2] = invertBlock(group[1][2])
        newGroup[2][1] = invertBlock(group[2][2])
        newGroup[1][1] = invertBlock(group[2][1])
    elseif direction == "2" then
        newGroup[2][2] = group[1][1]
        newGroup[2][1] = group[1][2]
        newGroup[1][1] = group[2][2]
        newGroup[1][2] = group[2][1]
    elseif direction == "L" then
        newGroup[2][1] = invertBlock(group[1][1])
        newGroup[1][1] = invertBlock(group[1][2])
        newGroup[1][2] = invertBlock(group[2][2])
        newGroup[2][2] = invertBlock(group[2][1])
    end

    return newGroup
end

function invertBlock(block)
    if block == "H" then
        return "V"
    elseif block == "V" then
        return "H"
    else
        return block
    end
end

local nextAndOperating = {}

local GhostGroupInfo = {
    x = nil,
    rotate = 0,
    currentX = nil,
    currentY = nil,
    angle = 0,
    targetY = nil,
    alpha = 1.0,
}

for i = 1, 8 do
    well[i] = {}
    for j = 1, 8 do
        well[i][j] = 0
    end
end

local hImages = {}
local vImages = {}
local hgImage = nil
local vgImage = nil
local nextSpliterImage = nil
local nextOperatingSpliterImage = nil
local upArrowImage = nil
local BLOCK_SIZE = nil
local BLOCK_WH = nil
local switchStateCallback = nil

local function drawBlock(value, x, y, imageIndex)
    love.graphics.setColor(1, 1, 1)

    if value == "V" then
        love.graphics.draw(vImages[imageIndex or 1], x, y, 0, BLOCK_WH, BLOCK_WH)
    elseif value == "H" then
        love.graphics.draw(hImages[imageIndex or 1], x, y, 0, BLOCK_WH, BLOCK_WH)
    end
end

local function drawGhostBlock(value, x, y)
    if value == "V" then
        love.graphics.draw(vgImage, x, y, 0, BLOCK_WH, BLOCK_WH)
    elseif value == "H" then
        love.graphics.draw(hgImage, x, y, 0, BLOCK_WH, BLOCK_WH)
    end
end

local function drawAreaBackground(startX, startY, width, height)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", startX, startY, width, height)
    love.graphics.setColor(r, g, b, a)
end

local function drawBorder(startX, startY, width, height, borderWidth, color, hasTop, hasLeft, hasRight, hasBottom)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(color)

    if hasTop then
        love.graphics.rectangle("fill", startX - borderWidth, startY - borderWidth, width + 2 * borderWidth, borderWidth)
    end

    if hasLeft then
        love.graphics.rectangle("fill", startX - borderWidth, startY, borderWidth, height)
    end

    if hasRight then
        love.graphics.rectangle("fill", startX + width, startY, borderWidth, height)
    end

    if hasBottom then
        love.graphics.rectangle("fill", startX - borderWidth, startY + height, width + 2 * borderWidth, borderWidth)
    end

    love.graphics.setColor(r, g, b, a)
end

local function calculateGhostPosition(ghostX)
    if ghostX == nil or ghostX < 1 or ghostX > 7 then
        return nil
    end

    local highestRow = 9
    for col = ghostX, ghostX + 1 do
        for row = 1, 8 do
            if well[row][col] ~= 0 then
                if row < highestRow then
                    highestRow = row
                end
                break
            end
        end
    end

    local ghostY = highestRow - 2

    if ghostY < 1 then
        return nil
    end

    return ghostY
end

function load(switchState)
    switchStateCallback = switchState

    for i = 1, 4 do
        hImages[i] = love.graphics.newImage("src/img/blocks/normal/h" .. i .. ".png")
        vImages[i] = love.graphics.newImage("src/img/blocks/normal/v" .. i .. ".png")
    end

    hgImage = love.graphics.newImage("src/img/blocks/normal/hg.png")
    vgImage = love.graphics.newImage("src/img/blocks/normal/vg.png")
    nextSpliterImage = love.graphics.newImage("src/img/game/nextSpliter.png")
    nextOperatingSpliterImage = love.graphics.newImage("src/img/game/nextOperatingSpliter.png")
    upArrowImage = love.graphics.newImage("src/img/blocks/normal/upArrow.png")

    well[8][4] = getRandomBlock()
    well[8][5] = getRandomBlock()
    well[7][5] = getRandomBlock()

    GhostGroupInfo.x = 4
    GhostGroupInfo.rotate = "0"
    GhostGroupInfo.currentX = 4
    GhostGroupInfo.currentY = nil
    GhostGroupInfo.angle = 0
    GhostGroupInfo.targetY = calculateGhostPosition(4)

    for _ = 1, 3 do
        local newBlockGroup = getRandomBlockGroup()
        table.insert(nextAndOperating, newBlockGroup)
    end
end

function update(dt)
    local diffX = GhostGroupInfo.x - GhostGroupInfo.currentX
    GhostGroupInfo.currentX = GhostGroupInfo.currentX + diffX / GHOST_MOVE_SPEED

    if GhostGroupInfo.currentY ~= nil then
        if GhostGroupInfo.targetY ~= nil then
            local diffY = GhostGroupInfo.targetY - GhostGroupInfo.currentY
            GhostGroupInfo.currentY = GhostGroupInfo.currentY + diffY / GHOST_MOVE_SPEED
            GhostGroupInfo.alpha = math.min(1.0, GhostGroupInfo.alpha + dt * 16)
        else
            GhostGroupInfo.alpha = math.max(0.0, GhostGroupInfo.alpha - dt * 16)
            if GhostGroupInfo.alpha <= 0 then
                GhostGroupInfo.currentY = nil
            end
        end
    else
        GhostGroupInfo.currentY = GhostGroupInfo.targetY
        GhostGroupInfo.alpha = 0
    end

    GhostGroupInfo.angle = GhostGroupInfo.angle - GhostGroupInfo.angle / GHOST_MOVE_SPEED
end

local function drawGhostGroup(wellStartX, wellStartY)
    if GhostGroupInfo.currentX == nil or GhostGroupInfo.currentY == nil then
        return
    end

    if GhostGroupInfo.alpha <= 0 then
        return
    end

    local currentGroup = nextAndOperating[1]
    local rotatedGroup = rotateBlockGroup(currentGroup, GhostGroupInfo.rotate)
    local centerX = wellStartX + (GhostGroupInfo.currentX - 0.5) * BLOCK_SIZE
    local centerY = wellStartY + (GhostGroupInfo.currentY - 0.5) * BLOCK_SIZE
    local angleRad = math.rad(GhostGroupInfo.angle)

    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = rotatedGroup[i][j]
            if blockValue then
                local relX = (j - 1.5) * BLOCK_SIZE
                local relY = (i - 1.5) * BLOCK_SIZE
                local rotatedX = relX * math.cos(angleRad) - relY * math.sin(angleRad)
                local rotatedY = relX * math.sin(angleRad) + relY * math.cos(angleRad)
                local blockX = centerX + rotatedX
                local blockY = centerY + rotatedY

                love.graphics.push()

                local blockCenterX = blockX + BLOCK_SIZE / 2
                local blockCenterY = blockY + BLOCK_SIZE / 2

                love.graphics.translate(blockCenterX, blockCenterY)
                love.graphics.rotate(angleRad)
                love.graphics.translate(-BLOCK_SIZE / 2, -BLOCK_SIZE / 2)

                love.graphics.setColor(1, 1, 1, GhostGroupInfo.alpha)
                drawGhostBlock(blockValue, 0, 0)

                love.graphics.pop()
            end
        end
    end
end

local function drawWell(startX, startY, totalWidth, totalHeight, borderWidth)
    local r, g, b, a = love.graphics.getColor()

    drawAreaBackground(startX, startY, totalWidth, totalHeight)
    drawBorder(startX, startY, totalWidth, totalHeight, borderWidth, { 1, 1, 1, 1 }, true, true, true, true)

    love.graphics.setColor(r, g, b, a)
end

local function drawWellBlocks(startX, startY)
    local r, g, b, a = love.graphics.getColor()

    for i = 1, 8 do
        for j = 1, 8 do
            local value = well[i][j]
            if value ~= 0 then
                local x = startX + (j - 1) * BLOCK_SIZE
                local y = startY + (i - 1) * BLOCK_SIZE
                drawBlock(value, x, y)
            end
        end
    end

    love.graphics.setColor(r, g, b, a)
end

local function drawOperatingArea(operatingStartX, operatingStartY, operatingWidth, operatingHeight, borderWidth)
    local r, g, b, a = love.graphics.getColor()

    drawAreaBackground(operatingStartX, operatingStartY, operatingWidth, operatingHeight)
    drawBorder(operatingStartX, operatingStartY, operatingWidth, operatingHeight, borderWidth, { 1, 0.8, 0.4, 1 },
        true,
        true, true, false)

    local operatingGroup = nextAndOperating[1]
    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = operatingGroup[i][j]
            local blockX = operatingStartX + (j - 1) * BLOCK_SIZE
            local blockY = operatingStartY + (i - 1) * BLOCK_SIZE

            local imageIndex = 1
            if i == 1 then
                imageIndex = 2
            elseif i == 2 then
                local otherJ = (j == 1) and 2 or 1
                if blockValue == "H" and operatingGroup[2][otherJ] == "H" then
                    imageIndex = 2
                else
                    imageIndex = 1
                end
            end

            drawBlock(blockValue, blockX, blockY, imageIndex)
        end
    end

    love.graphics.setColor(r, g, b, a)
end

local function drawNextArea(nextStartX, nextStartY, nextWidth, nextHeight, borderWidth)
    local r, g, b, a = love.graphics.getColor()

    local boxHeight = 2 * BLOCK_SIZE
    local gapHeight = BLOCK_SIZE

    local topBoxStartY = nextStartY
    local topBoxWidth = nextWidth
    local topBoxHeight = boxHeight

    drawAreaBackground(nextStartX, topBoxStartY, topBoxWidth, topBoxHeight)
    drawBorder(nextStartX, topBoxStartY, topBoxWidth, topBoxHeight, borderWidth, { 1, 1, 1, 1 }, false, true, true, false)

    local nextGroup1 = nextAndOperating[2]
    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = nextGroup1[i][j]
            local blockX = nextStartX + (j - 1) * BLOCK_SIZE
            local blockY = topBoxStartY + (i - 1) * BLOCK_SIZE

            local imageIndex = 1
            if i == 1 then
                imageIndex = 2
            elseif i == 2 then
                local otherJ = (j == 1) and 2 or 1
                if blockValue == "H" and nextGroup1[2][otherJ] == "H" then
                    imageIndex = 2
                else
                    imageIndex = 1
                end
            end

            drawBlock(blockValue, blockX, blockY, imageIndex)
        end
    end

    local bottomBoxStartY = nextStartY + boxHeight + gapHeight
    local bottomBoxWidth = nextWidth
    local bottomBoxHeight = boxHeight

    drawAreaBackground(nextStartX, bottomBoxStartY, bottomBoxWidth, bottomBoxHeight)
    drawBorder(nextStartX, bottomBoxStartY, bottomBoxWidth, bottomBoxHeight, borderWidth, { 1, 1, 1, 1 }, false, true,
        true, true)

    local nextGroup2 = nextAndOperating[3]
    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = nextGroup2[i][j]
            local blockX = nextStartX + (j - 1) * BLOCK_SIZE
            local blockY = bottomBoxStartY + (i - 1) * BLOCK_SIZE

            local imageIndex = 1
            if i == 1 then
                imageIndex = 2
            elseif i == 2 then
                local otherJ = (j == 1) and 2 or 1
                if blockValue == "H" and nextGroup2[2][otherJ] == "H" then
                    imageIndex = 2
                else
                    imageIndex = 1
                end
            end

            drawBlock(blockValue, blockX, blockY, imageIndex)
        end
    end

    love.graphics.setColor(r, g, b, a)
end

function drawSpliter(operatingStartX, operatingStartY, operatingHeight, borderWidth, nextStartX, nextStartY)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(1, 1, 1, 1)

    local nextOperatingSpliterY = operatingStartY + operatingHeight
    local nextOperatingSpliterWidth = 2 * BLOCK_SIZE + 2 * borderWidth
    local nextOperatingSpliterHeight = BLOCK_SIZE
    local nextOperatingSpliterScaleX = nextOperatingSpliterWidth / nextOperatingSpliterImage:getWidth()
    local nextOperatingSpliterScaleY = nextOperatingSpliterHeight / nextOperatingSpliterImage:getHeight()
    local nextOperatingSpliterX = operatingStartX - borderWidth

    love.graphics.draw(nextOperatingSpliterImage, nextOperatingSpliterX, nextOperatingSpliterY, 0,
        nextOperatingSpliterScaleX, nextOperatingSpliterScaleY)

    local nextSpliterY = nextStartY + 2 * BLOCK_SIZE
    local nextSpliterWidth = 2 * BLOCK_SIZE + 2 * borderWidth
    local nextSpliterHeight = BLOCK_SIZE
    local nextSpliterScaleX = nextSpliterWidth / nextSpliterImage:getWidth()
    local nextSpliterScaleY = nextSpliterHeight / nextSpliterImage:getHeight()
    local nextSpliterX = nextStartX - borderWidth

    love.graphics.draw(nextSpliterImage, nextSpliterX, nextSpliterY, 0, nextSpliterScaleX, nextSpliterScaleY)

    love.graphics.setColor(r, g, b, a)
end

local function drawUpArrow(wellStartX, wellStartY, wellHeight)
    local arrowX = wellStartX + (GhostGroupInfo.currentX - 1) * BLOCK_SIZE
    local arrowY = wellStartY + wellHeight
    local arrowWidth = 2 * BLOCK_SIZE
    local arrowHeight = BLOCK_SIZE
    local arrowScaleX = arrowWidth / upArrowImage:getWidth()
    local arrowScaleY = arrowHeight / upArrowImage:getHeight()
    local arrowAlpha = GhostGroupInfo.alpha / 2 + 0.5

    love.graphics.setColor(1, 1, 1, arrowAlpha)
    love.graphics.draw(upArrowImage, arrowX, arrowY, 0, arrowScaleX, arrowScaleY)
end

function draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    BLOCK_SIZE = screenHeight / 14
    BLOCK_WH = BLOCK_SIZE / hImages[1]:getWidth()

    local borderWidth = BLOCK_SIZE / 6
    local totalCombinedWidth = 11 * BLOCK_SIZE
    local combinedStartX = (screenWidth - totalCombinedWidth) / 2
    local startY = (screenHeight - 8 * BLOCK_SIZE) / 2
    local wellStartX = combinedStartX
    local wellWidth = 8 * BLOCK_SIZE
    local wellHeight = 8 * BLOCK_SIZE
    local operatingStartX = combinedStartX + wellWidth + BLOCK_SIZE
    local operatingStartY = startY
    local operatingWidth = 2 * BLOCK_SIZE
    local operatingHeight = 2 * BLOCK_SIZE
    local nextStartX = operatingStartX
    local nextStartY = operatingStartY + operatingHeight + BLOCK_SIZE
    local nextWidth = 2 * BLOCK_SIZE
    local nextHeight = 5 * BLOCK_SIZE

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    drawWell(wellStartX, startY, wellWidth, wellHeight, borderWidth)
    drawGhostGroup(wellStartX, startY)
    drawWellBlocks(wellStartX, startY)
    drawUpArrow(wellStartX, startY, wellHeight)
    drawOperatingArea(operatingStartX, operatingStartY, operatingWidth, operatingHeight, borderWidth)
    drawSpliter(operatingStartX, operatingStartY, operatingHeight, borderWidth, nextStartX, nextStartY)
    drawNextArea(nextStartX, nextStartY, nextWidth, nextHeight, borderWidth)
end

function toCW()
    if GhostGroupInfo.rotate == "0" then
        GhostGroupInfo.rotate = "R"
    elseif GhostGroupInfo.rotate == "R" then
        GhostGroupInfo.rotate = "2"
    elseif GhostGroupInfo.rotate == "2" then
        GhostGroupInfo.rotate = "L"
    elseif GhostGroupInfo.rotate == "L" then
        GhostGroupInfo.rotate = "0"
    end
end

function toCCW()
    if GhostGroupInfo.rotate == "0" then
        GhostGroupInfo.rotate = "L"
    elseif GhostGroupInfo.rotate == "L" then
        GhostGroupInfo.rotate = "2"
    elseif GhostGroupInfo.rotate == "2" then
        GhostGroupInfo.rotate = "R"
    elseif GhostGroupInfo.rotate == "R" then
        GhostGroupInfo.rotate = "0"
    end
end

function keypressed(key)
    if key == "left" then
        if GhostGroupInfo.x ~= nil and GhostGroupInfo.x > 1 then
            GhostGroupInfo.x = GhostGroupInfo.x - 1
            GhostGroupInfo.targetY = calculateGhostPosition(GhostGroupInfo.x)
        end
    elseif key == "right" then
        if GhostGroupInfo.x ~= nil and GhostGroupInfo.x < 7 then
            GhostGroupInfo.x = GhostGroupInfo.x + 1
            GhostGroupInfo.targetY = calculateGhostPosition(GhostGroupInfo.x)
        end
    elseif key == "up" or key == "x" then
        toCW()
        GhostGroupInfo.angle = 11.25
    elseif key == "z" then
        toCCW()
    elseif key == "down" then
        placeBlocks()
    end
end

function getNewBlockGroupAndReset()
    nextAndOperating[1] = nextAndOperating[2]
    nextAndOperating[2] = nextAndOperating[3]
    nextAndOperating[3] = getRandomBlockGroup()

    GhostGroupInfo.x = 4
    GhostGroupInfo.rotate = "0"
    GhostGroupInfo.angle = 0
    GhostGroupInfo.targetY = calculateGhostPosition(4)
    GhostGroupInfo.currentX = 4
    GhostGroupInfo.currentY = GhostGroupInfo.targetY
    GhostGroupInfo.alpha = 0
end

function placeBlocks()
    if GhostGroupInfo.targetY == nil then
        return
    end

    local currentGroup = nextAndOperating[1]
    if not currentGroup then
        return
    end

    local rotatedGroup = rotateBlockGroup(currentGroup, GhostGroupInfo.rotate)

    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = rotatedGroup[i][j]
            if blockValue and blockValue ~= 0 then
                local wellRow = GhostGroupInfo.targetY + (i - 1)
                local wellCol = GhostGroupInfo.x + (j - 1)

                if wellRow >= 1 and wellRow <= 8 and wellCol >= 1 and wellCol <= 8 then
                    well[wellRow][wellCol] = blockValue
                end
            end
        end
    end

    getNewBlockGroupAndReset()
end

function mousepressed(x, y, button)
end

function mousemoved(x, y, dx, dy)
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
    wheelmoved = wheelmoved,
    getRandomBlock = getRandomBlock,
    getRandomBlockGroup = getRandomBlockGroup
}

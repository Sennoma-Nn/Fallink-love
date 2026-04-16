local config = require("src.game_config")
local uiButton = require("src.ui")

local well = {}

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
        return group
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

function resetGhostState()
    GhostGroupInfo.x = 4
    GhostGroupInfo.rotate = "0"
    GhostGroupInfo.angle = 0
    GhostGroupInfo.targetY = calculateGhostPosition(4)
    GhostGroupInfo.currentX = 4
    GhostGroupInfo.currentY = GhostGroupInfo.targetY
    GhostGroupInfo.alpha = 1.0
end

function getNewBlockGroupAndReset()
    addNewBlockGroup()
    resetGhostState()
end

local GHOST_MOVE_SPEED = 4

local fallingBlocks = {}
local isFalling = false
local FALL_SPEED = 4

local score = 0
local clearCount = 0
local settledClearCount = 0
local chainTotal = 0
local renCount = 0
local isClearing = false
local clearPause = 0
local isInChain = false

for i = 1, 8 do
    well[i] = {}
    for j = 1, 8 do
        well[i][j] = 0
    end
end

local skin = "normal"

local spr = {
    h = {},
    v = {},
    hg = nil,
    vg = nil,
    nextSpliter = nil,
    nextOperatingSpliter = nil,
    upArrow = nil,
}

local BLOCK_SIZE = nil
local BLOCK_WH = nil
local switchStateCallback = nil
local uiFont = nil

local function drawBlock(value, x, y, imageIndex)
    love.graphics.setColor(1, 1, 1)

    if value == "V" then
        love.graphics.draw(spr.v[imageIndex or 1], x, y, 0, BLOCK_WH, BLOCK_WH)
    elseif value == "H" then
        love.graphics.draw(spr.h[imageIndex or 1], x, y, 0, BLOCK_WH, BLOCK_WH)
    end
end

local function drawGhostBlock(value, x, y)
    if value == "V" then
        love.graphics.draw(spr.vg, x, y, 0, BLOCK_WH, BLOCK_WH)
    elseif value == "H" then
        love.graphics.draw(spr.hg, x, y, 0, BLOCK_WH, BLOCK_WH)
    end
end

local function draw2x2BlockGroup(group, startX, startY)
    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = group[i][j]
            local blockX = startX + (j - 1) * BLOCK_SIZE
            local blockY = startY + (i - 1) * BLOCK_SIZE

            local imageIndex = 1
            if i == 1 then
                imageIndex = 2
            elseif i == 2 then
                local otherJ = (j == 1) and 2 or 1
                if blockValue == "H" and group[2][otherJ] == "H" then
                    imageIndex = 2
                else
                    imageIndex = 1
                end
            end

            drawBlock(blockValue, blockX, blockY, imageIndex)
        end
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

function calculateGhostPosition(ghostX)
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

local function getConnectedCount(row, col)
    local value = well[row][col]
    local count = 1

    if value == "H" then
        local c = col - 1
        while c >= 1 and well[row][c] == "H" do
            count = count + 1
            c = c - 1
        end
        c = col + 1
        while c <= 8 and well[row][c] == "H" do
            count = count + 1
            c = c + 1
        end
    else
        local r = row - 1
        while r >= 1 and well[r][col] == "V" do
            count = count + 1
            r = r - 1
        end
        r = row + 1
        while r <= 8 and well[r][col] == "V" do
            count = count + 1
            r = r + 1
        end
    end

    return math.min(count, 4)
end

local function finalizeChain()
    if chainTotal > 0 then
        score = score + (chainTotal * chainTotal)
        settledClearCount = clearCount
        chainTotal = 0
        renCount = 0
    end
    isInChain = false
end

local function clearMatches()
    local clearedAny = false
    local totalCleared = 0

    for row = 1, 8 do
        local col = 1
        while col <= 8 do
            if well[row][col] == "H" then
                local start = col
                while col <= 8 and well[row][col] == "H" do
                    col = col + 1
                end
                local len = col - start

                if len >= 4 then
                    for i = start, col - 1 do
                        well[row][i] = 0
                    end
                    clearCount = clearCount + 1
                    totalCleared = totalCleared + len
                    clearedAny = true
                end
            else
                col = col + 1
            end
        end
    end

    for col = 1, 8 do
        local row = 1
        while row <= 8 do
            if well[row][col] == "V" then
                local start = row
                while row <= 8 and well[row][col] == "V" do
                    row = row + 1
                end
                local len = row - start

                if len >= 4 then
                    for i = start, row - 1 do
                        well[i][col] = 0
                    end
                    clearCount = clearCount + 1
                    totalCleared = totalCleared + len
                    clearedAny = true
                end
            else
                row = row + 1
            end
        end
    end

    if clearedAny then
        chainTotal = chainTotal + totalCleared

        if renCount == 0 then
            renCount = 1
        else
            renCount = renCount + 1
        end

        clearPause = 32
    end

    return clearedAny, totalCleared
end

local function checkFallingBlocks()
    fallingBlocks = {}

    for col = 1, 8 do
        local emptySpaces = 0

        for row = 8, 1, -1 do
            if well[row][col] == 0 then
                emptySpaces = emptySpaces + 1
            else
                if emptySpaces > 0 then
                    local connectedCount = getConnectedCount(row, col)
                    table.insert(fallingBlocks, {
                        row = row,
                        col = col,
                        value = well[row][col],
                        targetRow = row + emptySpaces,
                        progress = 0,
                        connectedCount = connectedCount,
                    })
                end
            end
        end
    end

    if #fallingBlocks > 0 then
        isFalling = true
        return true
    end

    return false
end

local function completeFalling()
    for _, block in ipairs(fallingBlocks) do
        well[block.row][block.col] = 0
    end

    for _, block in ipairs(fallingBlocks) do
        well[block.targetRow][block.col] = block.value
    end

    fallingBlocks = {}
    isFalling = false

    local cleared = clearMatches()

    if cleared then
        isInChain = true
    else
        local needsFall = checkFallingBlocks()
        if not needsFall then
            finalizeChain()
            resetGhostState()
        end
    end
end

local function updateFallingAnimation(dt)
    local allFinished = true

    for i, block in ipairs(fallingBlocks) do
        local fallDistance = block.targetRow - block.row
        block.progress = block.progress + (1 / FALL_SPEED) / fallDistance

        if block.progress >= 1.0 then
            block.progress = 1.0
        else
            allFinished = false
        end
    end

    if allFinished then
        completeFalling()
    end
end

function load(switchState)
    switchStateCallback = switchState

    for i = 1, 4 do
        spr.h[i] = love.graphics.newImage("src/img/skin/" .. skin .. "/h" .. i .. ".png")
        spr.v[i] = love.graphics.newImage("src/img/skin/" .. skin .. "/v" .. i .. ".png")
    end

    spr.hg = love.graphics.newImage("src/img/skin/" .. skin .. "/hg.png")
    spr.vg = love.graphics.newImage("src/img/skin/" .. skin .. "/vg.png")
    spr.nextSpliter = love.graphics.newImage("src/img/game/nextSpliter.png")
    spr.nextOperatingSpliter = love.graphics.newImage("src/img/game/nextOperatingSpliter.png")
    spr.upArrow = love.graphics.newImage("src/img/skin/" .. skin .. "/upArrow.png")
    uiFont = uiButton.getFont("small")

    resetGhostState()

    for _ = 1, 3 do
        local newBlockGroup = getRandomBlockGroup()
        table.insert(nextAndOperating, newBlockGroup)
    end
end

function update(dt)
    if clearPause > 0 then
        clearPause = clearPause - 1
        if clearPause <= 0 then
            if not checkFallingBlocks() then
                local clearedAny, _ = clearMatches()
                if not clearedAny then
                    finalizeChain()
                    resetGhostState()
                else
                    isInChain = true
                    return
                end
            end
        end
        return
    end

    if isFalling then
        updateFallingAnimation(dt)
    else
        if not isInChain and clearPause == 0 then
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
    end
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

    local fallingPositions = {}
    for _, block in ipairs(fallingBlocks) do
        fallingPositions[block.row * 10 + block.col] = true
    end

    for i = 1, 8 do
        for j = 1, 8 do
            local value = well[i][j]
            if value ~= 0 then
                if not fallingPositions[i * 10 + j] then
                    local x = startX + (j - 1) * BLOCK_SIZE
                    local y = startY + (i - 1) * BLOCK_SIZE
                    local connectedCount = getConnectedCount(i, j)
                    drawBlock(value, x, y, connectedCount)
                end
            end
        end
    end

    for _, block in ipairs(fallingBlocks) do
        local currentRow = block.row + (block.targetRow - block.row) * block.progress
        local x = startX + (block.col - 1) * BLOCK_SIZE
        local y = startY + (currentRow - 1) * BLOCK_SIZE
        drawBlock(block.value, x, y, block.connectedCount)
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

    draw2x2BlockGroup(operatingGroup, operatingStartX, operatingStartY)

    love.graphics.setColor(r, g, b, a)
end

local function drawNextArea(nextStartX, nextStartY, nextWidth, borderWidth)
    local r, g, b, a = love.graphics.getColor()

    local boxHeight = 2 * BLOCK_SIZE
    local gapHeight = BLOCK_SIZE

    local topBoxStartY = nextStartY
    local topBoxWidth = nextWidth
    local topBoxHeight = boxHeight

    drawAreaBackground(nextStartX, topBoxStartY, topBoxWidth, topBoxHeight)
    drawBorder(nextStartX, topBoxStartY, topBoxWidth, topBoxHeight, borderWidth, { 1, 1, 1, 1 }, false, true, true, false)

    local nextGroup1 = nextAndOperating[2]

    draw2x2BlockGroup(nextGroup1, nextStartX, topBoxStartY)

    local bottomBoxStartY = nextStartY + boxHeight + gapHeight
    local bottomBoxWidth = nextWidth
    local bottomBoxHeight = boxHeight

    drawAreaBackground(nextStartX, bottomBoxStartY, bottomBoxWidth, bottomBoxHeight)
    drawBorder(nextStartX, bottomBoxStartY, bottomBoxWidth, bottomBoxHeight, borderWidth, { 1, 1, 1, 1 }, false, true,
        true, true)

    local nextGroup2 = nextAndOperating[3]

    draw2x2BlockGroup(nextGroup2, nextStartX, bottomBoxStartY)

    love.graphics.setColor(r, g, b, a)
end

function drawSpliter(operatingStartX, operatingStartY, operatingHeight, borderWidth, nextStartX, nextStartY)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(1, 1, 1, 1)

    local nextOperatingSpliterY = operatingStartY + operatingHeight
    local nextOperatingSpliterWidth = 2 * BLOCK_SIZE + 2 * borderWidth
    local nextOperatingSpliterHeight = BLOCK_SIZE
    local nextOperatingSpliterScaleX = nextOperatingSpliterWidth / spr.nextOperatingSpliter:getWidth()
    local nextOperatingSpliterScaleY = nextOperatingSpliterHeight / spr.nextOperatingSpliter:getHeight()
    local nextOperatingSpliterX = operatingStartX - borderWidth

    love.graphics.draw(spr.nextOperatingSpliter, nextOperatingSpliterX, nextOperatingSpliterY, 0,
        nextOperatingSpliterScaleX, nextOperatingSpliterScaleY)

    local nextSpliterY = nextStartY + 2 * BLOCK_SIZE
    local nextSpliterWidth = 2 * BLOCK_SIZE + 2 * borderWidth
    local nextSpliterHeight = BLOCK_SIZE
    local nextSpliterScaleX = nextSpliterWidth / spr.nextSpliter:getWidth()
    local nextSpliterScaleY = nextSpliterHeight / spr.nextSpliter:getHeight()
    local nextSpliterX = nextStartX - borderWidth

    love.graphics.draw(spr.nextSpliter, nextSpliterX, nextSpliterY, 0, nextSpliterScaleX, nextSpliterScaleY)

    love.graphics.setColor(r, g, b, a)
end

local function drawUpArrow(wellStartX, wellStartY, wellHeight)
    local arrowX = wellStartX + (GhostGroupInfo.currentX - 1) * BLOCK_SIZE
    local arrowY = wellStartY + wellHeight
    local arrowWidth = 2 * BLOCK_SIZE
    local arrowHeight = BLOCK_SIZE
    local arrowScaleX = arrowWidth / spr.upArrow:getWidth()
    local arrowScaleY = arrowHeight / spr.upArrow:getHeight()
    local arrowAlpha = GhostGroupInfo.alpha / 2 + 0.5

    love.graphics.setColor(1, 1, 1, arrowAlpha)
    love.graphics.draw(spr.upArrow, arrowX, arrowY, 0, arrowScaleX, arrowScaleY)
end

function draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    BLOCK_SIZE = screenHeight / 14
    BLOCK_WH = BLOCK_SIZE / spr.h[1]:getWidth()

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

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    drawWell(wellStartX, startY, wellWidth, wellHeight, borderWidth)
    drawGhostGroup(wellStartX, startY)
    drawWellBlocks(wellStartX, startY)
    drawUpArrow(wellStartX, startY, wellHeight)
    drawOperatingArea(operatingStartX, operatingStartY, operatingWidth, operatingHeight, borderWidth)
    drawSpliter(operatingStartX, operatingStartY, operatingHeight, borderWidth, nextStartX, nextStartY)
    drawNextArea(nextStartX, nextStartY, nextWidth, borderWidth)

    if uiFont then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(uiFont)

        local scoreX = nextStartX + nextWidth + BLOCK_SIZE
        local nextTotalHeight = 5 * BLOCK_SIZE
        local nextBottomY = nextStartY + nextTotalHeight
        local lineHeight = uiFont:getHeight() + 5
        local totalTextHeight = lineHeight * 3
        local scoreY = nextBottomY - totalTextHeight

        local avgClearScore = 0
        if settledClearCount > 0 then
            avgClearScore = score / settledClearCount
        end

        love.graphics.print("SCORE: " .. score, scoreX, scoreY)
        love.graphics.print("CLEAR: " .. clearCount, scoreX, scoreY + lineHeight)
        love.graphics.print("AVGCS: " .. string.format("%.2f", avgClearScore), scoreX, scoreY + lineHeight * 2)
    end
end

local function toCW()
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

local function toCCW()
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
    if isFalling or clearPause > 0 or isInChain then
        return
    end

    if key == "left" then
        if GhostGroupInfo.x > 1 then
            GhostGroupInfo.x = GhostGroupInfo.x - 1
            GhostGroupInfo.targetY = calculateGhostPosition(GhostGroupInfo.x)
        end
    elseif key == "right" then
        if GhostGroupInfo.x < 7 then
            GhostGroupInfo.x = GhostGroupInfo.x + 1
            GhostGroupInfo.targetY = calculateGhostPosition(GhostGroupInfo.x)
        end
    elseif key == "up" or key == "x" then
        toCW()
        GhostGroupInfo.angle = 11.25
    elseif key == "z" then
        toCCW()
        GhostGroupInfo.angle = -11.25
    elseif key == "down" then
        placeBlocks()
    end
end

function addNewBlockGroup()
    nextAndOperating[1] = nextAndOperating[2]
    nextAndOperating[2] = nextAndOperating[3]
    nextAndOperating[3] = getRandomBlockGroup()
end

function placeBlocks()
    if GhostGroupInfo.targetY == nil then
        return
    end

    local currentGroup = nextAndOperating[1]
    local rotatedGroup = rotateBlockGroup(currentGroup, GhostGroupInfo.rotate)

    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = rotatedGroup[i][j]
            local wellRow = GhostGroupInfo.targetY + (i - 1)
            local wellCol = GhostGroupInfo.x + (j - 1)

            if wellRow >= 1 and wellRow <= 8 and wellCol >= 1 and wellCol <= 8 then
                well[wellRow][wellCol] = blockValue
            end
        end
    end

    addNewBlockGroup()

    GhostGroupInfo.alpha = 0
    GhostGroupInfo.currentY = nil

    local cleared, clearedCount = clearMatches()

    if cleared then
        isInChain = true
    else
        local needsFall = checkFallingBlocks()
        if not needsFall then
            if isInChain then
                finalizeChain()
            end
            resetGhostState()
        else
            isInChain = true
        end
    end
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

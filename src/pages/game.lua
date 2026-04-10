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
    rotate = 0 -- 0, R, 2, L
}

for i = 1, 8 do
    well[i] = {}
    for j = 1, 8 do
        well[i][j] = 0
    end
end

for _ = 1, 3 do
    local newBlockGroup = getRandomBlockGroup()
    table.insert(nextAndOperating, newBlockGroup)
end

local hImages = {}
local vImages = {}
local hgImage = nil
local vgImage = nil
local waveImage = nil
local BLOCK_SIZE = nil
local BLOCK_WH = nil
local switchStateCallback = nil

local function drawBlock(value, x, y)
    love.graphics.setColor(1, 1, 1)

    if value == "V" then
        love.graphics.draw(vImages[1], x, y, 0, BLOCK_WH, BLOCK_WH)
    elseif value == "H" then
        love.graphics.draw(hImages[1], x, y, 0, BLOCK_WH, BLOCK_WH)
    end
end

local function drawGhostBlock(value, x, y)
    love.graphics.setColor(1, 1, 1)

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

function load(switchState)
    switchStateCallback = switchState

    for i = 1, 4 do
        hImages[i] = love.graphics.newImage("src/img/blocks/normal/h" .. i .. ".png")
        vImages[i] = love.graphics.newImage("src/img/blocks/normal/v" .. i .. ".png")
    end

    hgImage = love.graphics.newImage("src/img/blocks/normal/hg.png")
    vgImage = love.graphics.newImage("src/img/blocks/normal/vg.png")
    waveImage = love.graphics.newImage("src/img/game/wave.png")

    GhostGroupInfo.x = 4
    GhostGroupInfo.rotate = "0"

    -- well[8][4] = getRandomBlock()
    -- well[8][5] = getRandomBlock()
    -- well[7][5] = getRandomBlock()
end

function update(dt)
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

local function drawGhostGroup(wellStartX, wellStartY)
    if GhostGroupInfo.x == nil then
        return
    end

    local ghostY = calculateGhostPosition(GhostGroupInfo.x)
    if ghostY == nil then
        return
    end

    local currentGroup = nextAndOperating[1]
    local rotatedGroup = rotateBlockGroup(currentGroup, GhostGroupInfo.rotate)

    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = rotatedGroup[i][j]
            if blockValue then
                local blockX = wellStartX + (GhostGroupInfo.x + j - 2) * BLOCK_SIZE
                local blockY = wellStartY + (ghostY + i - 2) * BLOCK_SIZE
                drawGhostBlock(blockValue, blockX, blockY)
            end
        end
    end
end

local function drawWell(startX, startY, totalWidth, totalHeight, borderWidth)
    local r, g, b, a = love.graphics.getColor()

    drawAreaBackground(startX, startY, totalWidth, totalHeight)

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

    drawBorder(startX, startY, totalWidth, totalHeight, borderWidth, { 1, 1, 1, 1 }, true, true, true, true)

    love.graphics.setColor(r, g, b, a)
end

local function drawOperatingArea(operatingStartX, operatingStartY, operatingWidth, operatingHeight, borderWidth)
    local r, g, b, a = love.graphics.getColor()

    drawAreaBackground(operatingStartX, operatingStartY, operatingWidth, operatingHeight)
    drawBorder(operatingStartX, operatingStartY, operatingWidth, operatingHeight, borderWidth, { 1.0, 0.8039, 0.4588, 1 },
    true,
        true, true, true)

    local operatingGroup = nextAndOperating[1]
    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = operatingGroup[i][j]
            local blockX = operatingStartX + (j - 1) * BLOCK_SIZE
            local blockY = operatingStartY + (i - 1) * BLOCK_SIZE
            drawBlock(blockValue, blockX, blockY)
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
    drawBorder(nextStartX, topBoxStartY, topBoxWidth, topBoxHeight, borderWidth, { 1, 1, 1, 1 }, true, true, true, false)

    local nextGroup1 = nextAndOperating[2]
    for i = 1, 2 do
        for j = 1, 2 do
            local blockValue = nextGroup1[i][j]
            local blockX = nextStartX + (j - 1) * BLOCK_SIZE
            local blockY = topBoxStartY + (i - 1) * BLOCK_SIZE
            drawBlock(blockValue, blockX, blockY)
        end
    end

    local waveY = nextStartY + boxHeight
    local waveWidth = 2 * BLOCK_SIZE + 2 * borderWidth
    local waveHeight = BLOCK_SIZE
    local waveScaleX = waveWidth / waveImage:getWidth()
    local waveScaleY = waveHeight / waveImage:getHeight()

    local waveX = nextStartX - borderWidth
    love.graphics.draw(waveImage, waveX, waveY, 0, waveScaleX, waveScaleY)

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
            drawBlock(blockValue, blockX, blockY)
        end
    end

    love.graphics.setColor(r, g, b, a)
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
    drawOperatingArea(operatingStartX, operatingStartY, operatingWidth, operatingHeight, borderWidth)
    drawNextArea(nextStartX, nextStartY, nextWidth, nextHeight, borderWidth)
end

function keypressed(key)
    if key == "left" then
        if GhostGroupInfo.x ~= nil and GhostGroupInfo.x > 1 then
            GhostGroupInfo.x = GhostGroupInfo.x - 1
        end
    elseif key == "right" then
        if GhostGroupInfo.x ~= nil and GhostGroupInfo.x < 7 then
            GhostGroupInfo.x = GhostGroupInfo.x + 1
        end
    elseif key == "up" then
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

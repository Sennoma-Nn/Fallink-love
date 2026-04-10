local utils = {}

function utils.isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.width and
           y >= rect.y and y <= rect.y + rect.height
end

function utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function utils.clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

function utils.lerp(a, b, t)
    return a + (b - a) * t
end

function utils.easeOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

function utils.easeInQuad(t)
    return t * t
end

function utils.easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - math.pow(-2 * t + 2, 2) / 2
    end
end

function utils.createColor(r, g, b, a)
    a = a or 1
    return {r, g, b, a}
end

function utils.shallowCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

function utils.isEmpty(table)
    if not table then return true end
    for i in pairs(table) do
        return false
    end
    return true
end

function utils.mergeTables(t1, t2)
    local result = utils.shallowCopy(t1)
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

return utils
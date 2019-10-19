rolls = {}
function onObjectRandomize(object, player_color)
    local steam_name = Player[player_color].steam_name
    if rolls[steam_name] == nil then
        broadcastToAll(steam_name .. " has started rolling", {0,255,0})
        rolls[steam_name] = newPlayerRoll(steam_name)
        rolls[steam_name].start_roll(object)
    else
        rolls[steam_name].add(object)
    end
end

local function group_dice(dice)
    counts = {}
    counts[20] = {}
    total = 0
    for k, v in pairs(dice) do
        diceType = #v.getRotationValues()
        value = v.getValue() or 0
        counts[diceType] = counts[diceType] or {}
        table.insert(counts[diceType], value)
        if diceType != 20 then
            total = total + value
        end
    end
    return counts, total
end

local function finishMessage(steam_name, dice)
    counts, total = group_dice(dice)
    message = steam_name .. " has rolled "
    if #counts[20] > 0 then
        message = message .. #counts[20] .. "d20 (" .. table.concat(counts[20], ",") .. ") "
        if total > 0 then
            message = message .. "and "
        end
    end
    for k, v in pairs(counts) do
        if k != 20 and k != 0 then
            message = message .. #v .. "d" .. k .. "+"
        end
    end
    if total > 0 then
        message = message:sub( 1, string.len(message) - 1) .. "=" .. total
    end
    return message
end

function newPlayerRoll(steam_name)
    local self = {
        dice = {},
        steam_name = steam_name,
        wait_id = nil
    }

    local function wait_function()
        for k, v in pairs(self.dice) do
            if not v.resting then
                return false
            end
        end
        return true
    end

    local function finish()
        message = finishMessage(self.steam_name, self.dice)
        broadcastToAll(message, {0,255,0})
        self.dice = {}
        Wait.stop(self.wait_id)
        self.wait_id = nil
    end

    local function start_wait()
        self.wait_id = Wait.condition(finish, wait_function)
    end

    local function add(object)
        self.dice[object.getGUID()] = object
        if not self.wait_id then
            start_wait()
        end
    end

    local function stop()
        if self.wait_id then
            Wait.stop(self.wait_id)
            return true
        end
        return false
    end

    return {
        add = add,
        start_roll = add,
        stop_roll = stop,
        finish = finish,
    }
end

function finishRoll(steam_name)
    steam_name = steam_name[1]
    rolls[steam_name].finish()
end

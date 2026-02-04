print('hopper started')
pcall(function() writefile('time.txt', tostring(DateTime.now().UnixTimestamp + 25215)) end)
local BACKEND_URL = "https://serverfetcher.onrender.com/"

local WEBHOOKS = {
    -- admin ones
    -- ['https://discord.com/api/webhooks/1442175483994177567/mD0I1NtnsnAy5aocBcaNkQVSREz545SiAlAt8_Tu5yo54Y66wUb4dMZ72HJ8fuWvBOkR'] = {min = 1_000_000, max = 9_999_999},
    ['https://canary.discord.com/api/webhooks/1456734181152391301/QgYBUHPmkxRUnYK_EsAEonBSa_X3aVOKGsGMVgExFDdLez9yRJrWM8KR36tB_fC9wG5h'] = {min = 10_000_000, max = 99_999_999},
    ['https://canary.discord.com/api/webhooks/1456733998561890334/73mO-cG9C_3kgx8AoWc4yCJaV2EBZHTC2V4SWyhYUH3W-OUtzAVyPOAzjfrd5uo9V4bK'] = {min = 100_000_000, max = 999_999_999},
    ['https://canary.discord.com/api/webhooks/1457065693412458498/RGOX3LDw4RPoMuMdGsJYrux-aVXYUdxlhrLM1ONpHiZds888fVUKBijVrZNpGkkH7L6N'] = {min = 1_000_000_000, max = math.huge},
    -- user ones
    -- ['https://discord.com/api/webhooks/1442633779033411596/XnH3-3rlrj6NiNR7GVk6FhFszxkOmxZgzlg9ZoS8HAO17k1nte9TaoZr85uJHi9fPq7m'] = {min = 3_000_000, max = 9_999_999},
    ['https://canary.discord.com/api/webhooks/1456734885317447690/JJJ-J-cBb_JYDd1QrM37Mrfm0bXnyuGDicKqKgDqyYGlLdcN3qG3bYrKKGYIgC7ACgnY'] = {min = 100_000_000, max = math.huge, highlight = true, priority = true},
    ['https://canary.discord.com/api/webhooks/1456734760981500106/y2Vmqr5ywAK_WIOdYwXjfYGvQRJ2eUvTeqdgBibsAORPU0QaUHU0naJMqHKCNRnAMivx'] = {min = 100_000_000, max = math.huge, highlight = true}
}

local PRIORITY_ANIMALS = {
    "Strawberry Elephant",
    "Skibidi Toilet",
    "Meowl",
    "Headless Horseman",
    "Dragon Gingerini",
    "Dragon Cannelloni",
    "Ketupat Bros",
    "La Supreme Combinasion",
    "Cerberus",
     "Hydra Dragon Cannelloni",
    "Capitano Moby",
    "Cooki and Milki",
    "Burguro And Fryuro",
     "La Casa Boo",
     "Ginger Gerat",
     "Tralaledon",
     "Festive 67",
     "Reinito Sleighito",
    "Fragrama and Chocrama",
    "Fishino Clownino",
    "Garama and Madundung",
    "Los Spaghettis",
    "Spooky and Pumpky",
    "La Secret Combinasion",
     "Lavadorito Spinito",
    "La Ginger Sekolah",
     "Tictac Sahur",
     "Ketchuru and Musturu",
    "Chillin Chili",
    "Ketupat Kepat",
    "La Taco Combinasion",
    "Tang Tang Keletang",
    "W or L",
    -- "Spaghetti Tualetti",
    "Nuclearo Dinossauro",
    -- "Money Money Puggy"
}

local PRIORITY_INDEX = {}
for i, v in ipairs(PRIORITY_ANIMALS) do
    PRIORITY_INDEX[v] = i
end


-- config stuff
local WEBHOOK_REFRESH = 0.30

local TP_MIN_GAP_S     = 1
local TP_JITTER_MIN_S  = 0.4
local TP_JITTER_MAX_S  = 0.6

-- Services
local HttpService     = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local CoreGui         = game:GetService("CoreGui")
local LocalPlayer     = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ==========================================================
-- Optimazations
-- ==========================================================

task.spawn(function()
    local RunService = game:GetService("RunService")

    while true do
        pcall(function()
            RunService:Set3dRenderingEnabled(false)
        end)
        task.wait(1)
    end
end)

task.spawn(function()
    local workspace = game:GetService("Workspace")

    while true do
        pcall(function()
            workspace.StreamingEnabled = true
            workspace.StreamingMinRadius = 16
            workspace.StreamingTargetRadius = 32

            if workspace.CurrentCamera then
                workspace.CurrentCamera.FieldOfView = 30
            end
        end)
        task.wait(2)
    end
end)


-- ==========================================================
-- Anti AFK
-- ==========================================================
task.spawn(function()
    while not Players.LocalPlayer do
        task.wait()
    end

    local vu = game:GetService("VirtualUser")

    Players.LocalPlayer.Idled:Connect(function()
        pcall(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end)
end)

-- ==========================================================
-- HTTP helper
-- ==========================================================
local request = rawget(_G, "http_request")
    or rawget(_G, "request")
    or (syn and syn.request)
    or (http and http.request)

local function postJSON(path, tbl)
    local url  = BACKEND_URL .. path
    local body = HttpService:JSONEncode(tbl or {})
    if request then
        local ok, resp = pcall(function()
            return request({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body
            })
        end)
        if not ok or not resp or not (resp.Body or resp.body) then return nil end
        local ok2, data = pcall(function()
            return HttpService:JSONDecode(resp.Body or resp.body)
        end)
        if not ok2 then return nil end
        return data
    else
        local ok, raw = pcall(function()
            return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
        end)
        if not ok then return nil end
        local ok2, data = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        if not ok2 then return nil end
        return data
    end
end

local lastServerFetch = 0

-- ==========================================================
-- /next: Fetching next server
-- ==========================================================
local function nextServer()
    lastServerFetch = os.clock()
    local data = postJSON("next", { username = LocalPlayer.Name, vpsName = vpsname or "unknown" })
    if type(data) == "table" and data.ok and data.id then
        return tostring(data.id)
    end

    task.wait(0.2)
    return nil
end
-- ==========================================================
-- Teleporting to servers
-- ==========================================================
local lastAttemptJobId, lastFailAt = nil, 0
local lastTeleportAt = 0

local function jitter()
    local j = math.random(
        math.floor(TP_JITTER_MIN_S * 1000),
        math.floor(TP_JITTER_MAX_S * 1000)
    ) / 1000
    task.wait(j)
end

local ls = LocalPlayer:WaitForChild("leaderstats")
local rebirths = ls:WaitForChild("Rebirths")

function tryTeleportTo(jobId)
    local now = os.clock()
    local gap = now - (lastTeleportAt or 0)
    if gap < TP_MIN_GAP_S then
        task.wait(TP_MIN_GAP_S - gap)
    end

    jitter()

    lastAttemptJobId = tostring(jobId)

    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, lastAttemptJobId, LocalPlayer)
    end)
    lastTeleportAt = os.clock()

    return ok
end

TeleportService.TeleportInitFailed:Connect(function()
    lastFailAt = os.clock()

    task.wait(0.6)

    if rebirths.Value > 0 then
        local nextId = nextServer()
        if nextId then tryTeleportTo(nextId) end
    end
end)
-- ==========================================================
--  Brainrot scanning
-- ==========================================================

local function parseMPS(s)
    if type(s) ~= "string" then return nil end
    local t = s:gsub(",", ""):gsub("%s+", "")
    local n, u = t:match("%$?([%d%.]+)([kKmMbB]?)/[sS]")
    if not n then return nil end
    local v = tonumber(n)
    if not v then return nil end
    local mult = (u == "k" or u == "K") and 1e3
        or (u == "m" or u == "M") and 1e6
        or (u == "b" or u == "B") and 1e9
        or 1
    return v * mult
end

local function shortMoney(v)
    v = tonumber(v) or 0
    if v >= 1e9 then
        local formatted = string.format("%.2f", v / 1e9):gsub("%.?0+$", "")
        return "$" .. formatted .. "B/s"
    elseif v >= 1e6 then
        local formatted = string.format("%.2f", v / 1e6):gsub("%.?0+$", "")
        return "$" .. formatted .. "M/s"
    elseif v >= 1e3 then
        return string.format("$%.0fK/s", v / 1e3)
    else
        return string.format("$%d/s", math.floor(v))
    end
end

local function isBetterCandidate(name, mps, bestName, bestMPS)
    local p1 = name and PRIORITY_INDEX[name]
    local p2 = bestName and PRIORITY_INDEX[bestName]

    if p1 then
        if not p2 then
            return true
        end
        if p1 < p2 then
            return true
        end
        if p1 == p2 and (not bestMPS or mps > bestMPS) then
            return true
        end
        return false
    end

    if p2 then
        return false
    end

    return not bestMPS or mps > bestMPS
end


local function scanModel(m)
    if not m:IsA("Model") then return end

    local animalPodiums = m:FindFirstChild("AnimalPodiums")
    if not animalPodiums then return end

    local plotSign = m:FindFirstChild("PlotSign")
    if not plotSign then return end

    local surface = plotSign:FindFirstChild("SurfaceGui")
    if not surface then return end

    local frame = surface:FindFirstChildOfClass("Frame")
    local label = frame and frame:FindFirstChildOfClass("TextLabel")
    local owner = label and label.Text:match("([^']+)") or "Unknown"

    local all = {}
    local bestMPS = nil
    local bestName = m.Name

    for _, podium in ipairs(animalPodiums:GetChildren()) do
        local base = podium:FindFirstChild("Base")
        if not base then continue end

        local spawn = base:FindFirstChild("Spawn")
        if not spawn then continue end

        local attachment = spawn:FindFirstChild("Attachment")
        if not attachment then continue end

        local gui = attachment:FindFirstChildOfClass("BillboardGui")
        if not gui then continue end

        local gen = gui:FindFirstChild("Generation")
        if not gen then continue end

        local money = parseMPS(gen.Text or "")
        if not money then continue end

        local name = gui:FindFirstChild("DisplayName")
        name = name and name.Text or "?"
        
        if money > 5_000_000 then
            table.insert(all, { name = name, money = money })
        end

        local p1 = PRIORITY_INDEX[name]
        local p2 = bestName and PRIORITY_INDEX[bestName]

        if p1 then
            if not p2 or p1 < p2 or (p1 == p2 and money > bestMPS) then
                bestName = name
                bestMPS = money
            end
        elseif not p2 and (not bestMPS or money > bestMPS) then
            bestName = name
            bestMPS = money
        end
    end

    for _, children in ipairs(m:GetChildren()) do
        if children.Name == 'AnimalPodiums' then continue end
        for _, desc in ipairs(children:GetDescendants()) do
            if desc:IsA("BillboardGui") and desc.Name == 'AnimalOverhead' then
                local gui = desc
                local gen = gui:FindFirstChild("Generation")
                if not gen then continue end

                local money = parseMPS(gen.Text or "")
                if not money then continue end

                local name = gui:FindFirstChild("DisplayName")
                name = name and name.Text or "?"
                
                if money > 5_000_000 then
                    table.insert(all, { name = name, money = money })
                end

                local p1 = PRIORITY_INDEX[name]
                local p2 = bestName and PRIORITY_INDEX[bestName]

                if p1 then
                    if not p2 or p1 < p2 or (p1 == p2 and money > bestMPS) then
                        bestName = name
                        bestMPS = money
                    end
                elseif not p2 and (not bestMPS or money > bestMPS) then
                    bestName = name
                    bestMPS = money
                end
            end
        end
    end

    if #all > 1 then
        table.sort(all, function(a, b) return a.money > b.money end)
    end

    return bestName, bestMPS, owner, all
end

-- =========================
-- Webhooks
-- =========================

-- Надёжная отправка вебхуков (5 попыток)
local function sendWebhookReliable(url, data)
    if url == "" or url == nil then return end
    if not request then return end

    local json = HttpService:JSONEncode(data)

    for attempt = 1, 5 do
        local ok, resp = pcall(function()
            return request({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = json
            })
        end)

        if ok and resp and (resp.StatusCode == 200 or resp.StatusCode == 204) then
            return true
        end

        task.wait(0.35 * attempt)
    end

    warn("[WEBHOOK] Failed after 5 attempts")
    return false
end

function normalizeName(name)
    local lower = string.lower(name)
    local normalized = string.gsub(lower, "%s+", "-")
    return normalized
end

local function sendWebhook(name, mutation, mps, url, fields, color, all, owner)
    if url == "" or not url then return end

    local placeId = game.PlaceId
    local jobId = game.JobId
    local formattedJobId = string.format("%s-%s-%s-%s-%s",
        string.sub(jobId, 1, 8),
        string.sub(jobId, 10, 13),
        string.sub(jobId, 15, 18),
        string.sub(jobId, 20, 23),
        string.sub(jobId, 25, 36)
    )

    local joinScript = 'game:GetService("TeleportService"):TeleportToPlaceInstance('
        .. tostring(placeId) .. ',"' .. tostring(jobId) .. '",game.Players.LocalPlayer)'

    local formattedMps = shortMoney(mps)
    local image = 'https://www.mobynotifier.com/brainrots/'..normalizeName(name)

    local formattedName = name
    if mutation then
        formattedName = string.format("[%s] %s", mutation, name)
    end

    local embedFields = fields or {
        { name = "🏷️ Name", value = "**" .. tostring(formattedName or "Unknown") .. "**", inline = true },
        { name = "💰 Money per sec", value = "**" .. formattedMps .. "**", inline = true },
        { name = "**👥 Players:**", value = "**" .. tostring(math.max(#Players:GetPlayers() - 1, 0))
            .. "**/**" .. tostring(Players.MaxPlayers or 0) .. "**", inline = true },

        { name = "**👑 Owner:**", value = '```' .. tostring(owner or 'Unknown') .. '```', inline = true },

        { name = "**🆔 Job ID: **", value = "```" .. tostring(formattedJobId) .. "```", inline = false },
        { name = "**📜 Join Script**", value = "```" .. joinScript .. "```", inline = false },
    }

    if all and all ~= "" then
        local pos = math.min(5, #embedFields + 1)
        table.insert(embedFields, pos, {
            name = "**🎭 All Brainrots (>5m/s)**",
            value = "```" .. all .. "```",
            inline = false
        })
    end

    local embed = {
        title = "🙉 Brainrot Notify",
        color = color or 16711680,
        fields = embedFields,
        thumbnail = { url = image },
        footer = { text = "Moby Notifier | v1.5"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    sendWebhookReliable(url, { embeds = { embed } })
end


local function formatEntry(entry)
    local str = string.format("%s | %s", entry.name, shortMoney(entry.money))
    if entry.mutation then
        str = string.format("[%s] %s", entry.mutation, str)
    end

    return str
end

local function formatList(list)
    local lines = {}
    for _, entry in ipairs(list) do
        table.insert(lines, formatEntry(entry))
    end
    return table.concat(lines, "\n")
end

local sentKeys = {}

local function useNotify(name, mutation, mps, owner, all)
    local urls = {}

    local key = tostring(game.JobId) .. "|" .. tostring(name) .. "|" .. tostring(math.floor(mps or 0))
    if sentKeys[key] then return end
    sentKeys[key] = true

    if name == "Quesadilla Crocodila" or name == "Los Cucarachas" or name == "Triplito Tralaleritos" or name == "Pot Hotspot" or name == "Santa Hotspot" or name == "To to to Sahur" then
        return
    end

    for url, range in pairs(WEBHOOKS) do
        if range.priority and PRIORITY_INDEX[name] then 
            table.insert(urls, url)
            continue
        end

        if ((mps >= range.min and mps <= range.max) or (range.highlight and PRIORITY_INDEX[name])) and not range.priority then
            table.insert(urls, url)
        end
    end

    local allBrainrots = formatList(all or {})

    local formattedName = name
    if mutation then
        formattedName = string.format("[%s] %s", mutation, name)
    end

    for _, url in ipairs(urls) do
        local highlight = WEBHOOKS[url].highlight
        local fields = highlight and {
            { name = "🏷️ Name", value = "**__" .. tostring(formattedName or "Unknown") .. "__**", inline = true },
            { name = "💰 Money per sec", value = "**__" .. shortMoney(mps) .. "__**", inline = true },
            { name = "**👥 Players:**", value = "**__" .. tostring(math.max(#Players:GetPlayers() - 1, 0))
                .. "__/**__" .. tostring(Players.MaxPlayers or 0) .. "__", inline = true },
        } or nil
        local color = (highlight or mps >= 100_000_000) and 16766720 or nil
        task.spawn(function()
            sendWebhook(name, mutation, mps, url, fields, color, allBrainrots, owner)
        end)
    end
end

-- ==========================================================
-- Handle new brainrots on server
-- ==========================================================
-- local earlyScanned = {}

-- task.spawn(function()
--     task.wait()
--     workspace.DescendantAdded:Connect(function(obj)
--         if earlyScanned[obj] then return end
--         earlyScanned[obj] = true

--         task.wait(0.05)

--         local name, mps, owner, all = scanModel(obj)
--         if not mps then return end

--         if mps > 0 then
--             useNotify(name or obj.Name, mps, owner, all)
--         end
--     end)
-- end)

-- ==========================================================
-- Scanning brainrots on join
-- ==========================================================

local function isPointInsideModel(model, worldPoint)
    local cf, size = model:GetBoundingBox()

    -- convert point to model space
    local localPoint = cf:PointToObjectSpace(worldPoint)

    local half = size * 0.5

    return math.abs(localPoint.X) <= half.X
       and math.abs(localPoint.Y) <= half.Y
       and math.abs(localPoint.Z) <= half.Z
end


local function getBrainrotOwner(m)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return "Unknown" end
    
    local foundPlot = nil
    for _, plot in pairs(plots:GetChildren()) do
        if isPointInsideModel(plot, m.Position) then
            foundPlot = plot
            break
        end
    end
    if not foundPlot then return "Unknown" end
    local plotSign = foundPlot:FindFirstChild("PlotSign")
    if not plotSign then return "Unknown" end

    local surface = plotSign:FindFirstChild("SurfaceGui")
    if not surface then return "Unknown" end

    local frame = surface:FindFirstChildOfClass("Frame")
    local label = frame and frame:FindFirstChildOfClass("TextLabel")
    local owner = label and label.Text:match("([^']+)") or "Unknown"
    return owner
end

local function brainrotGather()
    local bestModel, bestName, bestMPS, bestOwner, bestMut, bestAll = nil, nil, nil, nil, nil, nil
    local plots = workspace:WaitForChild("Plots")
    local allOwners = {}

    for _, v in ipairs(workspace.Debris:GetChildren()) do
        if v.Name ~= "FastOverheadTemplate" then
            continue
        end

        local gui = v:FindFirstChild("AnimalOverhead")
        if not gui then continue end

        local gen = gui:FindFirstChild("Generation")
        if not gen then continue end

        local money = parseMPS(gen.Text or "")
        if not money then continue end

        local name = gui:FindFirstChild("DisplayName")
        name = name and name.Text or "?"

        local mutation = gui:FindFirstChild("Mutation")
        local mut = mutation.Visible and mutation.Text or false

        local owner = getBrainrotOwner(v)
        if not owner then continue end

        if money > 5_000_000 then
            if not allOwners[owner] then
                allOwners[owner] = {}
            end
            table.insert(allOwners[owner], { name = name, mutation = mut, money = money })
        end

        if isBetterCandidate(name, money, bestName, bestMPS) then
            bestName = name
            bestMPS = money
            bestModel = v
            bestOwner = owner
            bestAll = allOwners[owner]
            bestMut = mut
        end
    end

    for _, m in ipairs(plots:GetChildren()) do
        local name, mps, owner, all = scanModel(m)
        if name and mps then
            if isBetterCandidate(name, mps, bestName, bestMPS) then
                bestModel = m
                bestName = name
                bestMPS = mps
                bestOwner = owner
                bestAll = all
            end
        end
    end

    if bestModel and bestMPS and bestMPS > 0 then
        table.sort(bestAll, function(a, b) return a.money > b.money end)
        useNotify(bestName or bestModel.Name, bestMut, bestMPS, bestOwner, bestAll)
    end
end


-- ==========================================================
-- First join hop
-- ==========================================================
local function oneShotHop()
    local jobId

    for attempt = 1, 50 do
        jobId = nextServer()
        if jobId then
            break
        end

        task.wait(0.25 + attempt * 0.07)
    end

    if not jobId then
        warn("[ONE-SHOT] Couldn't get a jobid after 12 attempts.")
        return
    end

    task.wait(math.random(45, 70) / 100)

    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    end)
end

task.spawn(function()
    local lp = Players.LocalPlayer
    while not lp do
        task.wait()
        lp = Players.LocalPlayer
    end

    local character = lp.Character
    if not character then
        character = lp.CharacterAdded:Wait()
    end

    task.wait(1.0)
    pcall(function() brainrotGather() end)
    task.wait(1.0)
    pcall(function() brainrotGather() end)
    task.spawn(function()
        while true do
            pcall(function() brainrotGather() end)
            task.wait(WEBHOOK_REFRESH)
        end
    end)
    task.wait(1.0)
    oneShotHop()
end)

task.spawn(function()
    while true do
        task.wait(math.random(5, 10))
        if os.clock() - lastServerFetch < 10 then continue end
        oneShotHop()
    end
end)

-- torch, chatgpt ethiopia and more

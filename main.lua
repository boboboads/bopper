print('hopper started')
-- pcall(function() writefile('time.txt', tostring(DateTime.now().UnixTimestamp + 25215)) end)
setfpscap(3)
local BACKEND_URL = "https://serverfetcher.onrender.com/"
local hop = 90
local ver = "1.2"


local dc = false
game:GetService('NetworkClient').ChildRemoved:Connect(function(child)
	if child:IsA('ClientReplicator') then
        dc = true
	end
end)

local PRIORITY_ANIMALS = {
    "Headless Horseman",
    "Strawberry Elephant",
    "Meowl",
    "Skibidi Toilet",
    "Signore Carapace",
    "Arcadragon",
    "Griffin",
    "Love Love Bear",
    "Dragon Gingerini",
    "Dragon Cannelloni",
    "La Supreme Combinasion",
    "Antonio",
    "Pancake and Syrup",
    "Tirilikalika Tirilikalako",
    "Globa Steppa",
    "Celestial Pegasus",
    "Rosey and Teddy",
    "Hydra Bunny",
    "Hydra Dragon Cannelloni",
    "Cerberus",
    "Ketupat Bros",
    "La Casa Boo",
    "Ginger Gerat",
    "Capitano Moby",
    "Foxini Lanternini",
    "Bunny and Eggy",
    "Cash or Card",
    "Capitano Moby",
    "Cooki and Milki",
    "Popcuru and Fizzuru",
    "Burguro And Fryuro",
    "Tralaledon",
    "Festive 67",
    "Reinito Sleighito",
    "Boppin Bunny",
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
}

local BEST_ANIMALS = {
    ["Strawberry Elephant"] = true,
    ["Skibidi Toilet"] = true,
    ["Meowl"] = true,
    ["Headless Horseman"] = true,
    ["Dragon Gingerini"] = true,
    ["Dragon Cannelloni"] = true,
    ["Ketupat Bros"] = true,
    ["La Supreme Combinasion"] = true,
    ["Cerberus"] = true,
    ["Hydra Dragon Cannelloni"] = true,
    -- ["Celestial Pegasus"] = true,
}

local PRIORITY_INDEX = {}
for i, v in ipairs(PRIORITY_ANIMALS) do
    PRIORITY_INDEX[v] = i
end

local WEBHOOK_REFRESH = 0.30
local TP_MIN_GAP_S    = 1
local TP_JITTER_MIN_S = 0.4
local TP_JITTER_MAX_S = 0.6

local BLACKLISTED_NAMES = {
    ["Quesadilla Crocodila"] = true,
    ["Los Cucarachas"] = true,
    ["Triplito Tralaleritos"] = true,
    ["Pot Hotspot"] = true,
    ["Santa Hotspot"] = true,
    ["To to to Sahur"] = true,
}

-- Services
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local Players          = game:GetService("Players")
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace        = game:GetService("Workspace")
local LocalPlayer      = Players.LocalPlayer or Players.PlayerAdded:Wait()
local GuiService = game:GetService("GuiService")

pcall(TeleportService.SetTeleportGui, TeleportService, workspace)

-- ==========================================================
-- Synchronizer bypass
-- ==========================================================
do
    local oldInfo
    oldInfo = hookfunction(debug.info, function(...)
        local src = oldInfo(1, "s")
        if src and src:find("Packages.Synchronizer") then
            return nil
        end
        return oldInfo(...)
    end)
end

do
    local Sync = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))

    for name, fn in pairs(Sync) do
        if typeof(fn) ~= "function" then continue end
        if isexecutorclosure(fn) then continue end

        local ok, ups = pcall(debug.getupvalues, fn)
        if not ok then continue end

        for idx, val in pairs(ups) do
            if typeof(val) == "function" and not isexecutorclosure(val) then
                local ok2, innerUps = pcall(debug.getupvalues, val)
                if ok2 then
                    local hasBoolean = false
                    for _, v in pairs(innerUps) do
                        if typeof(v) == "boolean" then
                            hasBoolean = true
                            break
                        end
                    end
                    if hasBoolean then
                        debug.setupvalue(fn, idx, newcclosure(function() end))
                    end
                end
            end
        end
    end
end

-- ==========================================================
-- Load modules
-- ==========================================================
local Synchronizer, AnimalsData, AnimalsShared

local function loadModules()
    local ok = pcall(function()
        local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
        local Datas    = ReplicatedStorage:WaitForChild("Datas", 10)
        local Shared   = ReplicatedStorage:WaitForChild("Shared", 10)
        local Utils    = ReplicatedStorage:WaitForChild("Utils", 10)

        Synchronizer  = require(Packages:WaitForChild("Synchronizer"))
        AnimalsData   = require(Datas:WaitForChild("Animals"))
        AnimalsShared = require(Shared:WaitForChild("Animals"))
    end)
    return ok
end

-- ==========================================================
-- Optimizations
-- ==========================================================
task.spawn(function()
    local RunService = game:GetService("RunService")
    while true do
        pcall(function() RunService:Set3dRenderingEnabled(false) end)
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            Workspace.StreamingEnabled = true
            Workspace.StreamingMinRadius = 16
            Workspace.StreamingTargetRadius = 32
            if Workspace.CurrentCamera then
                Workspace.CurrentCamera.FieldOfView = 30
            end
        end)
        task.wait(2)
    end
end)

-- ==========================================================
-- Anti AFK
-- ==========================================================
task.spawn(function()
    while not Players.LocalPlayer do task.wait() end
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
    if not plots then return "Carpet" end
    
    local foundPlot = nil
    for _, plot in pairs(plots:GetChildren()) do
        if isPointInsideModel(plot, m.Position) then
            foundPlot = plot
            break
        end
    end
    if not foundPlot then return "Carpet" end
    local plotSign = foundPlot:FindFirstChild("PlotSign")
    if not plotSign then return "Carpet" end

    local surface = plotSign:FindFirstChild("SurfaceGui")
    if not surface then return "Carpet" end

    local frame = surface:FindFirstChildOfClass("Frame")
    local label = frame and frame:FindFirstChildOfClass("TextLabel")
    local owner = label and label.Text:match("([^']+)") or "Carpet"
    return owner
end

local function sendWebhookReliable(url, data)
    if url == "" or url == nil then return end
    if not request then return end

    local json = HttpService:JSONEncode(data)

    for attempt = 1, 25 do
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

    warn("[WEBHOOK] Failed after 25 attempts")
    return false
end

local lastServerFetch = 0

-- ==========================================================
-- /next: Fetching next server
-- ==========================================================
local function nextServer()
    lastServerFetch = os.clock()
    print('[FETCHER] Fetching next server...')
    local data = postJSON("next", { username = LocalPlayer.Name, vpsName = vpsname or "unknown" })
    if type(data) == "table" and data.ok and data.id then
        print("[FETCHER] Next server:", data.id)
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

local function tryTeleportTo(jobId)
    local now = os.clock()
    local gap = now - (lastTeleportAt or 0)
    if gap < TP_MIN_GAP_S then
        task.wait(TP_MIN_GAP_S - gap)
    end

    jitter()
    lastAttemptJobId = tostring(jobId)

    local ok = pcall(function()
        pcall(TeleportService.TeleportCancel, TeleportService)
        pcall(TeleportService.SetTeleportGui, TeleportService, nil)
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
-- Utility
-- ==========================================================
local function shortMoney(v)
    v = tonumber(v) or 0
    if v >= 1e9 then
        return "$" .. string.format("%.2f", v / 1e9):gsub("%.?0+$", "") .. "B/s"
    elseif v >= 1e6 then
        return "$" .. string.format("%.2f", v / 1e6):gsub("%.?0+$", "") .. "M/s"
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
        if not p2 then return true end
        if p1 < p2 then return true end
        if p1 == p2 and (not bestMPS or mps > bestMPS) then return true end
        return false
    end
    if p2 then return false end
    return not bestMPS or mps > bestMPS
end

local function normalizeName(name)
    return string.gsub(string.lower(name), "%s+", "-")
end

local function getIsDuels(ownerName)
    if not ownerName then return false end
    local p = Players:FindFirstChild(ownerName)
    if not p then
        -- try by display name
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.DisplayName == ownerName then
                p = pl; break
            end
        end
    end
    if not p then return false end
    return (p:GetAttribute("__duels_block_steal") == true)
        or (p.Character and p.Character:GetAttribute("duels_block_steal") == true)
        or false
end

-- ==========================================================
-- Synchronizer channel cache
-- ==========================================================
local channelCache = {}  -- plotName -> channel

local function getChannel(plotName)
    if channelCache[plotName] then return channelCache[plotName] end
    local ok, ch = pcall(function()
        return Synchronizer:Wait(plotName)
    end)
    if ok and ch then
        channelCache[plotName] = ch
        return ch
    end
    return nil
end

-- Pre-warm channels for all plots in background
local function prewarmChannels()
    local plots = Workspace:WaitForChild("Plots", 10)
    if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") then
            task.spawn(function()
                getChannel(plot.Name)
            end)
        end
    end
end

-- ==========================================================
-- Gen value helper
-- ==========================================================
local function getGenValue(animalIndex, mutation, traits)
    if not AnimalsShared then return 0 end
    local ok, val = pcall(function()
        return AnimalsShared:GetGeneration(animalIndex, mutation, traits, nil)
    end)
    return (ok and val) or 0
end

-- ==========================================================
-- Core scan: read all plots via Synchronizer
-- ==========================================================
local function brainrotGather()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    local bestName, bestMPS, bestOwner, bestMut, bestAll, bestDuels =
        nil, nil, nil, nil, nil, nil

    for _, plot in ipairs(plots:GetChildren()) do
        if not plot:IsA("Model") then continue end

        local ch = getChannel(plot.Name)
        if not ch then continue end

        -- Get owner
        local ok1, owner = pcall(function() return ch:Get("Owner") end)
        if not ok1 or not owner then continue end

        local ownerName = type(owner) == "table" and (owner.Name or owner.name) or tostring(owner)

        -- Skip self
        if ownerName == LocalPlayer.Name then continue end

        -- Skip if player not in server (empty plot)
        if not Players:FindFirstChild(ownerName) then continue end

        local isDuels = getIsDuels(ownerName)

        -- Get animal list
        local ok2, animalList = pcall(function() return ch:Get("AnimalList") end)
        if not ok2 or not animalList then continue end

        local plotAnimals = {}  -- all animals >5m/s on this plot

        for slot, slotData in pairs(animalList) do
            if type(slotData) ~= "table" then continue end
            if not slotData.Index then continue end

            -- Skip animals that are inside active machines
            if slotData.Machine and slotData.Machine.Active then continue end

            local animalInfo = AnimalsData[slotData.Index]
            if not animalInfo then continue end

            local mutation = slotData.Mutation
            -- Normalize Yin Yang mutation (same as original)
            if mutation and string.find(mutation, "Yang") then
                mutation = "Yin Yang"
            end

            local traits = slotData.Traits or {}
            local genValue = getGenValue(slotData.Index, mutation, traits)

            local displayName = animalInfo.DisplayName or slotData.Index

            if genValue > 5_000_000 then
                table.insert(plotAnimals, {
                    name     = displayName,
                    index    = slotData.Index,
                    mutation = mutation or false,
                    money    = genValue,
                    traits   = traits,
                })
            end

            if isBetterCandidate(displayName, genValue, bestName, bestMPS) then
                bestName  = displayName
                bestMPS   = genValue
                bestOwner = ownerName
                bestMut   = mutation or false
                bestDuels = isDuels
                bestAll   = plotAnimals  -- reference, will be sorted later
            end
        end

        -- Update bestAll reference if this plot owns the current best
        if bestOwner == ownerName and #plotAnimals > 0 then
            bestAll = plotAnimals
        end
    end

    if bestName and bestMPS and bestMPS > 0 then
        if bestAll then
            table.sort(bestAll, function(a, b) return a.money > b.money end)
        end
        -- print(string.format("[SCAN] Best: %s | %s/s | Owner: %s | Mutation: %s | Duels: %s",
            -- bestName, shortMoney(bestMPS), bestOwner, bestMut or "None", bestDuels and "Yes" or "No"))
        useNotify(bestName, bestMut, bestMPS, bestOwner, bestAll or {}, bestDuels or false)
    end
end

local function carpetBrainrotGather()
    local bestModel, bestName, bestMPS, bestOwner, bestMut, bestAll, bestDuels = nil, nil, nil, nil, nil, nil, nil
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

        local isDuels = false
        for k, v in pairs(gui:GetChildren()) do
            if v:IsA("TextLabel") and v.Visible and v.Text and string.lower(v.Text) == "in duel" then
                isDuels = true
                break
            end
        end

        if mut and string.find(mut, "Yang") then
            mut = "Yin Yang"
        end

        local owner = getBrainrotOwner(v)
        if not owner then continue end
        if owner ~= "Carpet" then continue end

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
            bestDuels = isDuels
        end
    end

    if bestModel and bestMPS and bestMPS > 0 then
        table.sort(bestAll, function(a, b) return a.money > b.money end)
        useNotify(bestName or bestModel.Name, bestMut, bestMPS, bestOwner, bestAll, bestDuels)
    end
end

-- ==========================================================
-- Notify / Webhook
-- ==========================================================
local function formatEntry(entry)
    local str = string.format("%s | %s", entry.name, shortMoney(entry.money))
    if entry.mutation and entry.mutation ~= false and entry.mutation ~= "" then
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

local function trySendNotify(url, tbl)
    local body = HttpService:JSONEncode(tbl or {})
    if not request then return nil end
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
end

local sentKeys = {}

function useNotify(name, mutation, mps, owner, all, inDuel)
    local key = tostring(game.JobId) .. "|" .. tostring(name) .. "|" .. tostring(math.floor(mps or 0))
    if sentKeys[key] then return end
    sentKeys[key] = true

    if mps < 10_000_000 then return end
    if BLACKLISTED_NAMES[name] then return end

    local allBrainrots = formatList(all or {})
    local formattedMps = shortMoney(mps)

    local jobId = game.JobId
    local formattedJobId = string.format("%s-%s-%s-%s-%s",
        string.sub(jobId, 1, 8),
        string.sub(jobId, 10, 13),
        string.sub(jobId, 15, 18),
        string.sub(jobId, 20, 23),
        string.sub(jobId, 25, 36)
    )

    local sent = false
    local try = 1
    while not sent do
        local status = trySendNotify("https://forwarder-nbp5.onrender.com/test", {
            bubble = "498c4177376594d0ec448eecc953de069b9f220ef524cc351d02caecd7c4f6a4",
            vps = vpsname or "unknown",
            data = {
                name     = name,
                mutation = mutation or false,
                money    = formattedMps,
                owner    = owner,
                all      = allBrainrots,
                jobid    = formattedJobId,
                players  = #Players:GetPlayers() - 1,
                isDuels  = getIsDuels(owner) or inDuel or false,
            }
        })
        if not status then
            task.wait(0.1 * try)
            try = try + 1
        else
            sent = true
        end
    end

    if PRIORITY_INDEX[name] and hop > 0 then
        local retry = 1
        LocalPlayer:Kick("Best log...")
        task.spawn(function()
            while true do
                oneShotHop()
                task.wait(1 * retry)
                retry = retry + 1
            end
        end)
    end
end

-- ==========================================================
-- One-shot hop
-- ==========================================================
function oneShotHop()
    local jobId
    for attempt = 1, 50 do
        jobId = nextServer()
        if jobId then break end
        task.wait(0.25 + attempt * 0.5)
    end

    if not jobId then
        warn("[ONE-SHOT] Couldn't get a jobid after 50 attempts.")
        return
    end

    if jobId == game.JobId then
        warn("same jobid, skipping teleport")
        if dc or (GuiService:GetErrorCode() and GuiService:GetErrorCode().Value and GuiService:GetErrorCode().Value == 267) then
            print("Disconnected, dc: ", dc)
            
            local embed = {
                title = "🙉 I GOT DETECTED",
                color = 16711680,
                footer = { text = ver},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
            task.spawn(function()
             sendWebhookReliable("https://canary.discord.com/api/webhooks/1495421348590125106/3XoDEjz2fLsxVyEG8rQnhTVuwgZgPxnTNzgXN5xtriit5CVW0RPWLu5_ML42Pzd3O82B", { embeds = { embed } })
            end)
            for i = 1, 20 do
                task.wait(0.2 * i)
                pcall(function()
                    pcall(TeleportService.TeleportCancel, TeleportService)
                    pcall(TeleportService.SetTeleportGui, TeleportService, nil)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
                end)
            end
        end

        task.wait(15)
        return
    end

    task.wait(0.1)

    pcall(function()
        pcall(TeleportService.TeleportCancel, TeleportService)
        pcall(TeleportService.SetTeleportGui, TeleportService, nil)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    end)
end

-- ==========================================================
-- Main
-- ==========================================================
task.spawn(function()
    local lp = Players.LocalPlayer
    while not lp do task.wait(); lp = Players.LocalPlayer end

    local character = lp.Character
    if not character then character = lp.CharacterAdded:Wait() end

    -- Wait for game to be ready
    if not game:IsLoaded() then game.Loaded:Wait() end
    repeat task.wait() until Workspace:FindFirstChild("Plots")

    -- Load modules (required before any scanning)
    local loaded = false
    for attempt = 1, 10 do
        loaded = loadModules()
        if loaded then break end
        warn("[Modules] Load attempt " .. attempt .. " failed, retrying...")
        task.wait(0.2)
    end

    if not loaded then
        warn("[Modules] Failed to load required modules. Aborting.")
        return
    end

    print("[Scanner] Modules loaded. Pre-warming channels...")
    prewarmChannels()
    task.wait(0.1) -- let channels settle

    print("[Scanner] Starting scan loop.")

    -- Initial scans
    -- pcall(function() brainrotGather() end)
    -- pcall(function() carpetBrainrotGather() end)
    task.wait(1.0)
    -- pcall(function() brainrotGather() end)
    -- pcall(function() carpetBrainrotGather() end)

    -- Continuous scan loop
    task.spawn(function()
        while true do
            -- pcall(function() brainrotGather() end)
            -- pcall(function() carpetBrainrotGather() end)
            task.wait(WEBHOOK_REFRESH)
        end
    end)

    task.wait(hop)
    oneShotHop()
end)

task.spawn(function()
    while true do
        task.wait(hop + 5)
        if os.clock() - lastServerFetch < 10 then continue end
        oneShotHop()
    end
end)

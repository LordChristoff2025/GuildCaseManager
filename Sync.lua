local GCM = _G["GuildCaseManager"]

-- Sync configuration
GCM.Sync = {
    REQUIRED_RANK = nil, -- Allow all guild members
    SYNC_PREFIX = "GCM_SYNC",
    VERSION = "2.0",
    enabled = true,
    lastSyncTime = 0,
    syncCooldown = 5 -- seconds between syncs
}

-- Initialize sync system
function GCM.Sync.Initialize()
    -- Register addon communication
    C_ChatInfo.RegisterAddonMessagePrefix(GCM.Sync.SYNC_PREFIX)
    
    -- Set up event handlers
    local syncFrame = CreateFrame("Frame")
    syncFrame:RegisterEvent("CHAT_MSG_ADDON")
    syncFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    syncFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    syncFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "CHAT_MSG_ADDON" then
            GCM.Sync.OnAddonMessage(...)
        elseif event == "GUILD_ROSTER_UPDATE" then
            GCM.Sync.OnGuildRosterUpdate()
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Request initial sync after entering world
            C_Timer.After(3, function()
                GCM.Sync.RequestFullSync()
            end)
        end
    end)
    
    print("|cff00ccffGCM Sync:|r Synchronization system initialized for all guild members")
end

-- Check if player has required rank (now allows all guild members)
function GCM.Sync.HasRequiredRank(playerName)
    if not IsInGuild() then return false end
    
    -- If no player name provided, check current player
    if not playerName then
        playerName = UnitName("player")
    end
    
    -- Check if player is in the guild (any rank is allowed)
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local name, rank = GetGuildRosterInfo(i)
        if name and name == playerName then
            return true -- Any guild member can sync
        end
    end
    return false
end

-- Get list of online guild members using the addon
function GCM.Sync.GetOnlineGuildMembers()
    local guildMembers = {}
    if not IsInGuild() then return guildMembers end
    
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local name, rank, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and online then
            table.insert(guildMembers, name)
        end
    end
    return guildMembers
end

-- Send sync data to other guild members
function GCM.Sync.SendData(dataType, data, target)
    if not GCM.Sync.HasRequiredRank() then
        print("|cffff0000GCM Sync:|r You must be in the guild to sync data")
        return false
    end
    
    local currentTime = GetTime()
    if currentTime - GCM.Sync.lastSyncTime < GCM.Sync.syncCooldown then
        -- Too soon since last sync, queue it
        return false
    end
    
    local syncData = {
        version = GCM.Sync.VERSION,
        type = dataType,
        data = data,
        sender = UnitName("player"),
        timestamp = time()
    }
    
    local serializedData = GCM.Sync.SerializeData(syncData)
    if not serializedData then
        print("|cffff0000GCM Sync:|r Failed to serialize data")
        return false
    end
    
    local channel = target and "WHISPER" or "GUILD"
    local success = C_ChatInfo.SendAddonMessage(GCM.Sync.SYNC_PREFIX, serializedData, channel, target)
    
    if success then
        GCM.Sync.lastSyncTime = currentTime
        if target then
            print("|cff00ccffGCM Sync:|r Data sent to " .. target)
        else
            print("|cff00ccffGCM Sync:|r Data broadcasted to guild members")
        end
    else
        print("|cffff0000GCM Sync:|r Failed to send sync data")
    end
    
    return success
end

-- Handle incoming addon messages
function GCM.Sync.OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= GCM.Sync.SYNC_PREFIX then return end
    if sender == UnitName("player") then return end -- Ignore own messages
    
    -- Verify sender has required rank
    if not GCM.Sync.HasRequiredRank(sender) then
        print("|cffff0000GCM Sync:|r Ignoring sync from " .. sender .. " (insufficient rank)")
        return
    end
    
    local syncData = GCM.Sync.DeserializeData(message)
    if not syncData then
        print("|cffff0000GCM Sync:|r Failed to parse sync data from " .. sender)
        return
    end
    
    -- Version check
    if syncData.version ~= GCM.Sync.VERSION then
        print("|cffff0000GCM Sync:|r Version mismatch with " .. sender .. " (their: " .. (syncData.version or "unknown") .. ", ours: " .. GCM.Sync.VERSION .. ")")
        return
    end
    
    GCM.Sync.ProcessSyncData(syncData, sender)
end

-- Process received sync data
function GCM.Sync.ProcessSyncData(syncData, sender)
    if syncData.type == "CASE_UPDATE" then
        GCM.Sync.ProcessCaseUpdate(syncData.data, sender)
    elseif syncData.type == "CASE_DELETE" then
        GCM.Sync.ProcessCaseDelete(syncData.data, sender)
    elseif syncData.type == "PERSON_UPDATE" then
        GCM.Sync.ProcessPersonUpdate(syncData.data, sender)
    elseif syncData.type == "PERSON_DELETE" then
        GCM.Sync.ProcessPersonDelete(syncData.data, sender)
    elseif syncData.type == "FULL_SYNC_REQUEST" then
        GCM.Sync.SendFullSync(sender)
    elseif syncData.type == "FULL_SYNC_DATA" then
        GCM.Sync.ProcessFullSync(syncData.data, sender)
    else
        print("|cffff0000GCM Sync:|r Unknown sync type: " .. (syncData.type or "nil"))
    end
end

-- Process case updates from other detectives
function GCM.Sync.ProcessCaseUpdate(caseData, sender)
    local existingCase = GCM.GetCase(caseData.id)
    local shouldUpdate = false
    
    if not existingCase then
        -- New case
        shouldUpdate = true
        print("|cff00ccffGCM Sync:|r New case received from " .. sender .. ": " .. (caseData.title or "Untitled"))
    else
        -- Check if remote case is newer
        local remoteTime = caseData.lastModified or caseData.createdAt or ""
        local localTime = existingCase.lastModified or existingCase.createdAt or ""
        
        if remoteTime > localTime then
            shouldUpdate = true
            print("|cff00ccffGCM Sync:|r Case updated from " .. sender .. ": " .. (caseData.title or "Untitled"))
        end
    end
    
    if shouldUpdate then
        caseData.syncedFrom = sender
        caseData.lastModified = caseData.lastModified or date("%Y-%m-%d %H:%M")
        
        if existingCase then
            -- Update existing
            for i, case in ipairs(GCM_Database.cases) do
                if case.id == caseData.id then
                    GCM_Database.cases[i] = caseData
                    break
                end
            end
        else
            -- Add new
            table.insert(GCM_Database.cases, caseData)
        end
        
        -- Refresh UI if open
        if GCM.CasesFrame and GCM.CasesFrame:IsShown() then
            GCM.RefreshCasesList()
        end
    end
end

-- Process case deletions
function GCM.Sync.ProcessCaseDelete(deleteData, sender)
    for i, case in ipairs(GCM_Database.cases) do
        if case.id == deleteData.id then
            table.remove(GCM_Database.cases, i)
            print("|cff00ccffGCM Sync:|r Case deleted by " .. sender .. ": " .. (case.title or "Untitled"))
            
            -- Refresh UI if open
            if GCM.CasesFrame and GCM.CasesFrame:IsShown() then
                GCM.RefreshCasesList()
            end
            break
        end
    end
end

-- Process person updates
function GCM.Sync.ProcessPersonUpdate(personData, sender)
    local existingPerson = nil
    local personIndex = nil
    
    for i, person in ipairs(GCM_Database.people or {}) do
        if person.id == personData.id then
            existingPerson = person
            personIndex = i
            break
        end
    end
    
    local shouldUpdate = false
    
    if not existingPerson then
        shouldUpdate = true
        print("|cff00ccffGCM Sync:|r New person record from " .. sender .. ": " .. (personData.name or "Unknown"))
    else
        local remoteTime = personData.updated or personData.createdAt or ""
        local localTime = existingPerson.updated or existingPerson.createdAt or ""
        
        if remoteTime > localTime then
            shouldUpdate = true
            print("|cff00ccffGCM Sync:|r Person record updated from " .. sender .. ": " .. (personData.name or "Unknown"))
        end
    end
    
    if shouldUpdate then
        personData.syncedFrom = sender
        GCM_Database.people = GCM_Database.people or {}
        
        if personIndex then
            GCM_Database.people[personIndex] = personData
        else
            table.insert(GCM_Database.people, personData)
        end
        
        -- Refresh UI if open
        if GCM.PeopleFrame and GCM.PeopleFrame:IsShown() then
            GCM.RefreshPeopleList()
        end
    end
end

-- Process person deletions
function GCM.Sync.ProcessPersonDelete(deleteData, sender)
    for i, person in ipairs(GCM_Database.people or {}) do
        if person.id == deleteData.id then
            table.remove(GCM_Database.people, i)
            print("|cff00ccffGCM Sync:|r Person record deleted by " .. sender .. ": " .. (person.name or "Unknown"))
            
            -- Refresh UI if open
            if GCM.PeopleFrame and GCM.PeopleFrame:IsShown() then
                GCM.RefreshPeopleList()
            end
            break
        end
    end
end

-- Request full sync from other detectives
function GCM.Sync.RequestFullSync()
    if not GCM.Sync.HasRequiredRank() then return end
    
    local guildMembers = GCM.Sync.GetOnlineGuildMembers()
    if #guildMembers > 1 then -- More than just us
        print("|cff00ccffGCM Sync:|r Requesting data sync from online guild members...")
        GCM.Sync.SendData("FULL_SYNC_REQUEST", {}, nil)
    end
end

-- Send full database to requesting guild member
function GCM.Sync.SendFullSync(requester)
    local fullData = {
        cases = GCM_Database.cases or {},
        people = GCM_Database.people or {},
        version = GCM_Database.version or 2
    }
    
    GCM.Sync.SendData("FULL_SYNC_DATA", fullData, requester)
end

-- Process full sync data
function GCM.Sync.ProcessFullSync(fullData, sender)
    local casesAdded = 0
    local peopleAdded = 0
    
    -- Merge cases
    for _, remoteCase in ipairs(fullData.cases or {}) do
        local exists = false
        for _, localCase in ipairs(GCM_Database.cases) do
            if localCase.id == remoteCase.id then
                exists = true
                break
            end
        end
        
        if not exists then
            remoteCase.syncedFrom = sender
            table.insert(GCM_Database.cases, remoteCase)
            casesAdded = casesAdded + 1
        end
    end
    
    -- Merge people
    GCM_Database.people = GCM_Database.people or {}
    for _, remotePerson in ipairs(fullData.people or {}) do
        local exists = false
        for _, localPerson in ipairs(GCM_Database.people) do
            if localPerson.id == remotePerson.id then
                exists = true
                break
            end
        end
        
        if not exists then
            remotePerson.syncedFrom = sender
            table.insert(GCM_Database.people, remotePerson)
            peopleAdded = peopleAdded + 1
        end
    end
    
    if casesAdded > 0 or peopleAdded > 0 then
        print("|cff00ccffGCM Sync:|r Sync complete from " .. sender .. " - Added " .. casesAdded .. " cases, " .. peopleAdded .. " people")
        
        -- Refresh UI
        if GCM.CasesFrame and GCM.CasesFrame:IsShown() then
            GCM.RefreshCasesList()
        end
        if GCM.PeopleFrame and GCM.PeopleFrame:IsShown() then
            GCM.RefreshPeopleList()
        end
    end
end

-- Guild roster update handler
function GCM.Sync.OnGuildRosterUpdate()
    -- Could be used to detect when guild members come online/offline
    -- For now, just a placeholder
end

-- Simple serialization functions
function GCM.Sync.SerializeData(data)
    -- Simple table-to-string serialization
    -- In a production addon, you might want to use a more robust library
    local success, result = pcall(function()
        return GCM.Sync.TableToString(data)
    end)
    
    return success and result or nil
end

function GCM.Sync.DeserializeData(str)
    local success, result = pcall(function()
        return GCM.Sync.StringToTable(str)
    end)
    
    return success and result or nil
end

-- Basic table serialization (simplified)
function GCM.Sync.TableToString(tbl)
    local result = "{"
    local first = true
    
    for k, v in pairs(tbl) do
        if not first then result = result .. "," end
        first = false
        
        local key = type(k) == "string" and '["' .. k:gsub('"', '\\"') .. '"]' or "[" .. k .. "]"
        
        if type(v) == "table" then
            result = result .. key .. "=" .. GCM.Sync.TableToString(v)
        elseif type(v) == "string" then
            result = result .. key .. '="' .. v:gsub('"', '\\"') .. '"'
        elseif type(v) == "number" then
            result = result .. key .. "=" .. v
        elseif type(v) == "boolean" then
            result = result .. key .. "=" .. (v and "true" or "false")
        end
    end
    
    return result .. "}"
end

function GCM.Sync.StringToTable(str)
    -- This is a simplified parser - in production, use a proper serialization library
    local func = loadstring("return " .. str)
    return func and func() or nil
end

-- Sync wrapper functions for existing save/delete operations
function GCM.Sync.SyncCaseUpdate(caseData)
    if GCM.Sync.HasRequiredRank() then
        caseData.lastModified = date("%Y-%m-%d %H:%M")
        GCM.Sync.SendData("CASE_UPDATE", caseData)
    end
end

function GCM.Sync.SyncCaseDelete(caseId)
    if GCM.Sync.HasRequiredRank() then
        GCM.Sync.SendData("CASE_DELETE", {id = caseId})
    end
end

function GCM.Sync.SyncPersonUpdate(personData)
    if GCM.Sync.HasRequiredRank() then
        personData.updated = date("%Y-%m-%d %H:%M")
        GCM.Sync.SendData("PERSON_UPDATE", personData)
    end
end

function GCM.Sync.SyncPersonDelete(personId)
    if GCM.Sync.HasRequiredRank() then
        GCM.Sync.SendData("PERSON_DELETE", {id = personId})
    end
end

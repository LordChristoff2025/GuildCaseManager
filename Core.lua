-- Global table creation
GuildCaseManager = {
    GUI = {},
    Database = {},
    Utils = {}
}

local GCM = GuildCaseManager

-- Initialize on PLAYER_LOGIN
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    -- Initialize SavedVariables
    GCM_Database = GCM_Database or {}
    GCM_Database.cases = GCM_Database.cases or {}
    GCM_Database.people = GCM_Database.people or {}
    GCM_Database.mapMarkers = GCM_Database.mapMarkers or {}
    GCM_Database.version = GCM_Database.version or 2
    GCM_Database.settings = GCM_Database.settings or {}
    GCM_Database.settings.welcomeShown = GCM_Database.settings.welcomeShown or false
    
    -- Slash command
    SLASH_GUILDCASEMANAGER1 = "/acdb"
    SlashCmdList["GUILDCASEMANAGER"] = function()
        GCM.ToggleUI()
    end
    
    -- Welcome screen command
    SLASH_GUILDCASEMANAGERWELCOME1 = "/acdbw"
    SlashCmdList["GUILDCASEMANAGERWELCOME"] = function()
        GCM.ShowWelcomeScreen()
    end
    
    -- Initialize sync system
    if GCM.Sync then
        GCM.Sync.Initialize()
    end
    
    -- Show welcome screen for first-time users
    if not GCM_Database.settings.welcomeShown then
        C_Timer.After(2, function()
            GCM.ShowWelcomeScreen()
        end)
    end
    
    print("Guild Case Manager by @LordChristoff loaded. Type |cff00ff00/acdb|r to open.")
end)

-- Toggle UI
function GCM.ToggleUI()
    if not GCM.MainFrame then
        GCM.CreateMainFrame()
    end
    if GCM.MainFrame:IsShown() then
        GCM.MainFrame:Hide()
    else
        GCM.MainFrame:Show()
    end
end

-- Add these new functions:
function GCM.SavePerson(personData)
    if not personData.id then
        -- New person
        personData.id = time().."-"..math.random(1000,9999)
        personData.createdBy = UnitName("player")
        personData.createdAt = date("%Y-%m-%d %H:%M:%S")
        GCM_Database.people = GCM_Database.people or {}
        table.insert(GCM_Database.people, personData)
    else
        -- Update existing person
        for i, p in ipairs(GCM_Database.people or {}) do
            if p.id == personData.id then
                personData.createdBy = p.createdBy -- Preserve original creator
                personData.createdAt = p.createdAt -- Preserve original creation date
                GCM_Database.people[i] = personData
                break
            end
        end
    end
    
    -- Sync to other detectives
    if GCM.Sync and GCM.Sync.SyncPersonUpdate then
        GCM.Sync.SyncPersonUpdate(personData)
    end
end

function GCM.GetStaffList()
    return {
        {
            name = "Detective Charles Magnussen",
            rank = "Head of the Arcane Consortium: Detective Bureau",
            description = "Charles Magnussen the seasoned magi, the founder of the original Arcane Consortium in 2018 and (IC) founder of the Kirin Tor Intelligence in 2019. Returns to restart the Arcane Consortium Detective Bureau in 2025.",
            contact = "lorchristoff on Discord or @LordChristoff"
        }
        -- Add more staff members as needed
    }
end

-- Case Management Functions
function GCM.SaveCase(caseData)
    if not caseData.id then
        -- New case
        caseData.id = #GCM_Database.cases + 1
        caseData.createdBy = UnitName("player")
        caseData.createdAt = date("%Y-%m-%d %H:%M")
        table.insert(GCM_Database.cases, caseData)
    else
        -- Update existing case
        for i, case in ipairs(GCM_Database.cases) do
            if case.id == caseData.id then
                GCM_Database.cases[i] = caseData
                break
            end
        end
    end
    
    -- Sync to other detectives
    if GCM.Sync then
        GCM.Sync.SyncCaseUpdate(caseData)
    end
end

function GCM.DeleteCase(caseId)
    if not caseId then return false end
    
    for i, case in ipairs(GCM_Database.cases) do
        if case.id == caseId then
            table.remove(GCM_Database.cases, i)
            
            -- Sync deletion to other detectives
            if GCM.Sync then
                GCM.Sync.SyncCaseDelete(caseId)
            end
            
            -- Refresh UI if cases frame is open
            if GCM.CasesFrame and GCM.CasesFrame:IsShown() then
                GCM.RefreshCasesList()
            end
            
            print("Case #"..caseId.." deleted successfully.")
            return true
        end
    end
    
    print("Error: Case not found!")
    return false
end

function GCM.DeletePerson(personId)
    if not personId then return false end
    
    for i, person in ipairs(GCM_Database.people or {}) do
        if person.id == personId then
            table.remove(GCM_Database.people, i)
            
            -- Sync deletion to other detectives
            if GCM.Sync then
                GCM.Sync.SyncPersonDelete(personId)
            end
            
            -- Refresh UI if people frame is open
            if GCM.PeopleFrame and GCM.PeopleFrame:IsShown() then
                GCM.RefreshPeopleList()
            end
            
            print("Person record deleted successfully.")
            return true
        end
    end
    
    print("Error: Person not found!")
    return false
end

-- Helper functions for Timeline compatibility
function GCM.InitDB()
    return GCM_Database
end

function GCM.GetCase(caseId)
    for _, case in ipairs(GCM_Database.cases or {}) do
        if case.id == caseId then
            return case
        end
    end
    return nil
end

function GCM.GetCurrentDateTime()
    return date("%Y-%m-%d %H:%M")
end

-- Map Marker Management Functions
function GCM.SaveMapMarker(markerData)
    if not markerData.id then
        -- New marker
        markerData.id = time() .. "-" .. math.random(1000, 9999)
        markerData.createdBy = UnitName("player")
        markerData.createdAt = date("%Y-%m-%d %H:%M:%S")
    end
    
    GCM_Database.mapMarkers = GCM_Database.mapMarkers or {}
    
    -- Check if marker already exists (update)
    local found = false
    for i, marker in ipairs(GCM_Database.mapMarkers) do
        if marker.id == markerData.id then
            GCM_Database.mapMarkers[i] = markerData
            found = true
            break
        end
    end
    
    -- If not found, add as new
    if not found then
        table.insert(GCM_Database.mapMarkers, markerData)
    end
    
    -- Sync to other detectives
    if GCM.Sync and GCM.Sync.SyncMapMarkerUpdate then
        GCM.Sync.SyncMapMarkerUpdate(markerData)
    end
    
    return markerData.id
end

function GCM.DeleteMapMarker(markerId)
    if not markerId then return false end
    
    for i, marker in ipairs(GCM_Database.mapMarkers or {}) do
        if marker.id == markerId then
            table.remove(GCM_Database.mapMarkers, i)
            
            -- Sync deletion to other detectives
            if GCM.Sync and GCM.Sync.SyncMapMarkerDelete then
                GCM.Sync.SyncMapMarkerDelete(markerId)
            end
            
            return true
        end
    end
    
    return false
end

function GCM.GetMapMarkers()
    return GCM_Database.mapMarkers or {}
end

function GCM.ClearAllMapMarkers()
    GCM_Database.mapMarkers = {}
    
    -- Sync clear to other detectives
    if GCM.Sync and GCM.Sync.SyncMapMarkersClear then
        GCM.Sync.SyncMapMarkersClear()
    end
end


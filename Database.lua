local GCM = _G["GuildCaseManager"]

-- These functions are now handled in Core.lua
-- This file is kept for compatibility but the functions are deprecated
-- The main SaveCase, DeleteCase, and GetCase functions are in Core.lua

-- Legacy wrapper functions for backwards compatibility
function GCM.Database.SaveCase(caseData)
    return GCM.SaveCase(caseData)
end

function GCM.Database.DeleteCase(caseID)
    return GCM.DeleteCase(caseID)
end

function GCM.Database.GetCase(caseID)
    return GCM.GetCase(caseID)
end

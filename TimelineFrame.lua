local addonName, private = ...
local GCM = _G.GuildCaseManager

if not GCM then
    return  -- Silent fail since this is optional
end

local GCM = _G["GuildCaseManager"]

function GCM.ShowTimelineFrame(caseId)
    local db = GCM.InitDB()
    local case = GCM.GetCase(caseId)
    
    -- Create frame if it doesn't exist
    if not GCM.TimelineFrame then
        GCM.TimelineFrame = CreateFrame("Frame", "GCM_TimelineFrame", UIParent, "BasicFrameTemplate")
        GCM.TimelineFrame:SetSize(800, 500)
        GCM.TimelineFrame:SetPoint("CENTER")
        GCM.TimelineFrame.TitleText:SetText("Case Timeline")
        
        -- Scroll frame
        GCM.TimelineFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, GCM.TimelineFrame, "UIPanelScrollFrameTemplate")
        GCM.TimelineFrame.ScrollFrame:SetPoint("TOPLEFT", 10, -30)
        GCM.TimelineFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
        
        -- Content frame
        GCM.TimelineFrame.Content = CreateFrame("Frame")
        GCM.TimelineFrame.Content:SetSize(760, 1)
        GCM.TimelineFrame.ScrollFrame:SetScrollChild(GCM.TimelineFrame.Content)
        
        -- Close button
        local closeBtn = CreateFrame("Button", nil, GCM.TimelineFrame, "UIPanelButtonTemplate")
        closeBtn:SetSize(100, 25)
        closeBtn:SetPoint("BOTTOM", 0, 10)
        closeBtn:SetText("Close")
        closeBtn:SetScript("OnClick", function() GCM.TimelineFrame:Hide() end)
        
        -- Add event button
        local addBtn = CreateFrame("Button", nil, GCM.TimelineFrame, "UIPanelButtonTemplate")
        addBtn:SetSize(120, 25)
        addBtn:SetPoint("RIGHT", closeBtn, "LEFT", -10, 0)
        addBtn:SetText("Add Event")
        addBtn:SetScript("OnClick", function() 
            GCM.ShowTimelineEventEditor(caseId) 
        end)
    end
    
    -- Refresh timeline display
    GCM.RefreshTimelineDisplay(caseId)
    GCM.TimelineFrame:Show()
end

function GCM.RefreshTimelineDisplay(caseId)
    local db = GCM.InitDB()
    local case = GCM.GetCase(caseId)
    
    -- Clear existing events
    for _, child in ipairs({GCM.TimelineFrame.Content:GetChildren()}) do
        child:Hide()
    end
    
    -- Sort events by date
    table.sort(case.timelineEvents or {}, function(a, b) 
        return a.date < b.date 
    end)
    
    -- Create timeline elements
    local yOffset = -10
    for i, event in ipairs(case.timelineEvents or {}) do
        local eventFrame = CreateFrame("Frame", nil, GCM.TimelineFrame.Content)
        eventFrame:SetSize(740, 60)
        eventFrame:SetPoint("TOPLEFT", 10, yOffset)
        
        -- Timeline line
        local line = eventFrame:CreateTexture(nil, "BACKGROUND")
        line:SetSize(20, 60)
        line:SetPoint("LEFT", 10, 0)
        line:SetColorTexture(0.5, 0.5, 0.8)
        
        -- Event dot
        local dot = eventFrame:CreateTexture(nil, "OVERLAY")
        dot:SetSize(16, 16)
        dot:SetPoint("CENTER", line, "TOP")
        dot:SetColorTexture(0.8, 0.2, 0.2)
        dot:SetRotation(math.pi/4)
        
        -- Date text
        local dateText = eventFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dateText:SetPoint("LEFT", line, "RIGHT", 10, 0)
        dateText:SetText(event.date)
        
        -- Event text
        local eventText = eventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        eventText:SetPoint("LEFT", dateText, "RIGHT", 20, 0)
        eventText:SetPoint("RIGHT", -10, 0)
        eventText:SetJustifyH("LEFT")
        eventText:SetText(event.description)
        
        -- Edit button
        local editBtn = CreateFrame("Button", nil, eventFrame, "UIPanelButtonTemplate")
        editBtn:SetSize(60, 20)
        editBtn:SetPoint("BOTTOMRIGHT", -10, 5)
        editBtn:SetText("Edit")
        editBtn:SetScript("OnClick", function()
            GCM.ShowTimelineEventEditor(caseId, i)
        end)
        
        yOffset = yOffset - 70
    end
    
    -- Adjust content height
    GCM.TimelineFrame.Content:SetHeight(math.abs(yOffset) + 20)
end

function GCM.ShowTimelineEventEditor(caseId, eventIndex)
    local db = GCM.InitDB()
    local case = GCM.GetCase(caseId)
    local event = eventIndex and case.timelineEvents[eventIndex] or {}
    
    if not GCM.TimelineEventEditor then
        GCM.TimelineEventEditor = CreateFrame("Frame", "GCM_TimelineEventEditor", UIParent, "BasicFrameTemplate")
        GCM.TimelineEventEditor:SetSize(400, 300)
        GCM.TimelineEventEditor:SetPoint("CENTER")
        GCM.TimelineEventEditor:SetFrameStrata("DIALOG")
        
        -- Date input
        local dateLabel = GCM.TimelineEventEditor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dateLabel:SetPoint("TOPLEFT", 20, -30)
        dateLabel:SetText("Date:")
        
        GCM.TimelineEventEditor.DateInput = CreateFrame("EditBox", nil, GCM.TimelineEventEditor, "InputBoxTemplate")
        GCM.TimelineEventEditor.DateInput:SetSize(150, 24)
        GCM.TimelineEventEditor.DateInput:SetPoint("TOPLEFT", 80, -30)
        
        -- Description input
        local descLabel = GCM.TimelineEventEditor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descLabel:SetPoint("TOPLEFT", 20, -70)
        descLabel:SetText("Description:")
        
        GCM.TimelineEventEditor.DescInput = CreateFrame("EditBox", nil, GCM.TimelineEventEditor, "InputBoxTemplate")
        GCM.TimelineEventEditor.DescInput:SetSize(360, 150)
        GCM.TimelineEventEditor.DescInput:SetPoint("TOPLEFT", 20, -90)
        GCM.TimelineEventEditor.DescInput:SetMultiLine(true)
        
        -- Save button
        local saveBtn = CreateFrame("Button", nil, GCM.TimelineEventEditor, "UIPanelButtonTemplate")
        saveBtn:SetSize(100, 25)
        saveBtn:SetPoint("BOTTOMRIGHT", -10, 10)
        saveBtn:SetText("Save")
        saveBtn:SetScript("OnClick", function()
            local eventData = {
                date = GCM.TimelineEventEditor.DateInput:GetText(),
                description = GCM.TimelineEventEditor.DescInput:GetText(),
                createdBy = UnitName("player"),
                createdAt = date("%Y-%m-%d")
            }
            
            if eventIndex then
                case.timelineEvents[eventIndex] = eventData
            else
                table.insert(case.timelineEvents or {}, eventData)
                case.timelineEvents = case.timelineEvents or {}
            end
            
            GCM.TimelineEventEditor:Hide()
            GCM.RefreshTimelineDisplay(caseId)
        end)
        
        -- Cancel button
        local cancelBtn = CreateFrame("Button", nil, GCM.TimelineEventEditor, "UIPanelButtonTemplate")
        cancelBtn:SetSize(100, 25)
        cancelBtn:SetPoint("BOTTOMLEFT", 10, 10)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetScript("OnClick", function()
            GCM.TimelineEventEditor:Hide()
        end)
    end
    
    -- Populate fields if editing
    GCM.TimelineEventEditor.DateInput:SetText(event.date or date("%Y-%m-%d"))
    GCM.TimelineEventEditor.DescInput:SetText(event.description or "")
    
    GCM.TimelineEventEditor:Show()
end

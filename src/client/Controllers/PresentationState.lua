--!strict
-- UI focus is local; accepted action availability comes from server state.
local PresentationState = {}
local snapshot: any = nil
local modals: { [string]: boolean } = {}
local gameplayMenu: ScreenGui? = nil
local changed = Instance.new("BindableEvent")
PresentationState.Changed = changed.Event
function PresentationState.Get(): any return snapshot end
function PresentationState.Update(value: any)
	if typeof(value) ~= "table" then return end
	if snapshot and typeof(value.generation) == "number" and typeof(snapshot.generation) == "number" and value.generation < snapshot.generation then return end
	snapshot = value
	changed:Fire(value)
end
function PresentationState.SetModal(id: string, enabled: boolean)
	if enabled then modals[id] = true else modals[id] = nil end
	changed:Fire(snapshot)
end
function PresentationState.IsModal(): boolean return next(modals) ~= nil end
-- This menu owns D-pad navigation and L3 confirmation; stick and A remain gameplay inputs.
function PresentationState.SetGameplayMenu(owner: ScreenGui) gameplayMenu=owner end
function PresentationState.ReleaseGameplayMenu(owner: ScreenGui)
	if gameplayMenu==owner then gameplayMenu=nil end
end
function PresentationState.GameplayMenuOwnsSelection(selected: GuiObject?): boolean
	local owner=gameplayMenu
	return owner~=nil and owner.Parent~=nil and selected~=nil and selected:IsDescendantOf(owner)
end
function PresentationState.ClearModals() table.clear(modals) end
return PresentationState

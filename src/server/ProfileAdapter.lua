--!strict
-- Injectable storage boundary. Provider calls may yield; transforms are pure.
local Adapter = {}
Adapter.LEASE_SECONDS = 180

function Adapter.New(provider: any, rules: any, config: any): any
	local self = {}
	function self.Acquire(key: string, owner: string, now: number): any
		local ok, raw = pcall(provider.read, key)
		if not ok then return {ok = false, state = "failed-load", reason = "read-failed"} end
		local state = if raw == nil then "confirmed-new" else "loaded-existing"
		local migration = nil
		if raw == nil then
			local legacyOk, legacy = pcall(provider.legacyRead, key)
			if not legacyOk then return {ok = false, state = "failed-load", reason = "migration-read-failed"} end
			migration = legacy
			if legacy ~= nil then state = "loaded-existing" end
		end
		local seed = if raw ~= nil then raw elseif migration ~= nil then migration else rules.Default(config)
		local normalized, reason = rules.Normalize(seed, config)
		if not normalized then return {ok = false, state = reason, reason = reason} end
		local rejection = "session-conflict"
		local claimOk, claimed = pcall(provider.update, key, function(current: any)
			local clockNow = if provider.now then provider.now() else now
			local source = if current ~= nil then current elseif migration ~= nil then migration else rules.Default(config)
			local data, errorReason = rules.Normalize(source, config)
			if not data then rejection = errorReason; return nil end
			local lease = current and current.lease
			if type(lease) == "table" and lease.owner ~= owner and type(lease.expiresAt) == "number" and lease.expiresAt > clockNow then
				return nil
			end
			data.revision = rules.Number(current and current.revision, 0, 9007199254740000)
			data.lease = {owner = owner, expiresAt = clockNow + Adapter.LEASE_SECONDS}
			return data
		end)
		if not claimOk then return {ok = false, state = "failed-load", reason = "lease-acquire-failed"} end
		if not claimed or not claimed.lease or claimed.lease.owner ~= owner then
			return {ok = false, state = rejection, reason = rejection}
		end
		local profile = rules.Normalize(claimed, config)
		return {ok = true, state = state, profile = profile, revision = claimed.revision, expiresAt = claimed.lease.expiresAt}
	end

	function self.Write(key: string, owner: string, expected: number, revision: number, snapshot: any, now: number, release: boolean): any
		local reason = "session-conflict"
		local writeToken = owner .. ":" .. tostring(revision) .. (if release then ":close" else ":save")
		local ok, result = pcall(provider.update, key, function(current: any)
			local clockNow = if provider.now then provider.now() else now
			if type(current) ~= "table" then return nil end
			local valid, invalidCurrent = rules.Normalize(current, config)
			if not valid then reason = invalidCurrent; return nil end
			local data, invalid = rules.Normalize(snapshot, config)
			if not data then reason = invalid; return nil end
			-- UpdateAsync may commit and then fail to return a response. Retrying the
			-- exact immutable write is safe, even when the final lease was released.
			if current.writeToken == writeToken and current.revision == revision and rules.Equal(valid, data) then
				if release and current.lease == nil then return rules.Clone(current) end
				if not release and type(current.lease) == "table" and current.lease.owner == owner and type(current.lease.expiresAt) == "number" and current.lease.expiresAt > clockNow then
					local retried = rules.Clone(current)
					retried.lease.expiresAt = clockNow + Adapter.LEASE_SECONDS
					return retried
				end
			end
			if type(current.lease) ~= "table" then return nil end
			if current.lease.owner ~= owner or type(current.lease.expiresAt) ~= "number" or current.lease.expiresAt <= clockNow then return nil end
			if current.revision ~= expected then reason = "revision-conflict"; return nil end
			data.revision = revision
			data.writeToken = writeToken
			if not release then data.lease = {owner = owner, expiresAt = clockNow + Adapter.LEASE_SECONDS} end
			return data
		end)
		if not ok then return {ok = false, retry = true, reason = "write-failed"} end
		if not result or result.revision ~= revision then return {ok = false, retry = false, reason = reason} end
		if release and result.lease ~= nil then return {ok = false, retry = false, reason = "release-conflict"} end
		if not release and (not result.lease or result.lease.owner ~= owner) then return {ok = false, retry = false, reason = reason} end
		return {ok = true, expiresAt = if result.lease then result.lease.expiresAt else now}
	end
	return self
end

return Adapter

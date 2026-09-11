--!strict
-- Pure bounded save-queue bookkeeping. One newest revision, never an event list.
local Queue = {}

function Queue.Request(record: any, force: boolean, now: number, minGap: number): boolean
	if not record.loaded or not record.writable then return false end
	if not force and record.revision <= record.savedRevision then return true end
	record.queued = true
	record.nextAttempt = math.max(record.nextAttempt, record.lastWrite + minGap, now)
	return true
end

function Queue.Snapshot(record: any, rules: any): any
	-- A failed response may follow a committed write. Retry that exact operation
	-- before coalescing later mutations, or the old CAS expectation would conflict.
	if record.pendingWrite then return record.pendingWrite end
	local written = rules.Freeze({expectedRevision = record.providerRevision, revision = record.revision,
		payload = rules.Clone(record.profile), release = record.closing})
	record.pendingWrite = written
	return written
end

function Queue.Succeeded(record: any, written: any, expiresAt: number, now: number, minGap: number)
	record.pendingWrite = nil
	record.providerRevision = written.revision
	record.savedRevision = written.revision
	record.expiresAt = expiresAt
	record.retries = 0
	record.reason = nil
	-- A mutation or close request accepted while storage yielded still needs work.
	record.queued = record.revision > written.revision or (record.closing and not written.release)
	record.nextAttempt = now + minGap
end

return Queue

local schedStack = {};
local ScheduleFrame = CreateFrame("Frame", "LootFilterScheduleFrame");
local Schedule = nil; -- Handle to scheduler coroutine

function LootFilter.schedule(delay, func, ...)
	if type(func) ~= "function" and type(func) ~= "string" then
		error("LootFilter.schedule: expected function or string as 2nd parameter, recieved `" .. type(func) .. "`");
	end
	table.insert(schedStack, {Time = (GetTime() + delay), Func = func, Args = {...}});
	table.sort(schedStack, function(a, b) -- Ensure the stack is properly sorted
		return a.Time < b.Time;
	end);
end

local function Scheduler(errorHandler)
	errorHandler = errorHandler or geterrorhandler();
	local addon = LootFilter;
	local StartTime, MaxTime = 0, .005;
	local function Yield(force)
		if force or (StartTime + MaxTime) > GetTime() then
			coroutine.yield();
		end
	end
	local stack = schedStack;
	local event = nil;
	Yield(true); -- Force a yield after setting up the scheduler
	while true do
		StartTime = GetTime();
		stack = schedStack; -- Make sure we have the correct stack
		if table.getn(stack) > 0 then
			event = stack[1];
			if event.Time < StartTime then
				-- Remove first so one bad task cannot poison the queue forever.
				table.remove(stack, 1);
				if type(event.Func) == "function" then
					xpcall(function()
						event.Func(unpack(event.Args));
					end, errorHandler);
				elseif type(event.Func) == "string" and type(addon[event.Func]) == "function" then
					xpcall(function()
						addon[event.Func](unpack(event.Args));
					end, errorHandler);
				else
					errorHandler("LootFilter.schedule: invalid scheduled function");
				end
			end
			Yield();
		else
			Yield(true);
		end
	end
end

local function OnUpdate(...)
	if not Schedule then
		Schedule = coroutine.wrap(Scheduler);
	end
	local ok = xpcall(Schedule, geterrorhandler())
	if not ok then
		-- Coroutine is dead after an error; reset so it can be recreated next frame
		Schedule = nil;
	end
end

ScheduleFrame:SetScript("OnUpdate", OnUpdate);

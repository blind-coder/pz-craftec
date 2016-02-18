require "TimedActions/ISBaseTimedAction"

--[[
--{{{
--ModData used:
--CrafTec: Object containing modData for CrafTecs with following attributes:
--  product: contains getFullType (e.g.: "Base.Axe") of finished product
--  tools: contains list of required tools (e.g.: { "Base.Saw", "Base.Screwdriver" })
--  requirements: Object containing requirements of Skills and Professions, e.g.:
--    Elecrician:
--      any: {level: 0, time: 100, progress: 10} -- any electrician can do this and take 100 minutes and already 10 minutes done
--    Engineer:
--      Carpentry: {level: 2, time: 200} -- any Engineer with Carpentry at least level 2 can do this and take 200 minutes and no units done
--    any:
--      Foraging: {level: 4, time: 0} -- any player with Foraging at least level 4 can do this regardless of profession and be finished immediately
--    any:
--      any: {level: 0, time: 500} -- anyone can do this in 500 minutes
--      -- actually, any: {level: >0} doesn't make sense and will be ignored.
--
--As of Build 32.03 the following Perks are available:
--  Agility, Cooking, Melee, Crafting, Fitness, Strength, Blunt, Axe, Sprinting, Lightfoot, Nimble, Sneak, Woodwork, Aiming, Reloading, Farming, Survivalist, Fishing, Trapping, Passiv, Firearm, PlantScavenging, BluntParent, BladeParent, BluntGuard, BladeGuard, BluntMaintenance, BladeMaintenance, Doctor, Electricity
--
-- }}}
--]]

BCCrafTecTA = ISBaseTimedAction:derive("BCCrafTecTA");
function BCCrafTecTA:isValid() -- {{{
	-- TODO
	return true;
end
-- }}}

function BCCrafTecTA:update() -- {{{
	if self.stopped then return end;
	local modData = self.object:getModData()["recipe"];
	local prof = self.character:getDescriptor():getProfession();

	local maxPartsProgress = 100;
	for part,amount in pairs(modData.ingredients) do
		local avail = (modData.ingredientsAdded and modData.ingredientsAdded[part]) or 0;
		maxPartsProgress = math.min(avail*100/amount, maxPartsProgress);
	end

	local canProgress = false;
	for k,profession in pairs(modData.requirements) do
		if (not canProgress) and ((k == prof) or (k == "any")) then
			for k2,skill in pairs(profession) do
				print("maxPartsProgress: "..maxPartsProgress);
				print(skill.progress.." < "..skill.time.." / (100 / "..maxPartsProgress..") = "..(skill.time / (100 / maxPartsProgress)));
				if (not canProgress)
						and (skill.progress < skill.time)
						and (skill.progress < skill.time / (100 / maxPartsProgress))
						and (
							(k2 == "any")
							or self.character:getPerkLevel(Perk.FromString(k2)) >= skill.level
						)
					then
					canProgress = skill;
				end
			end
		end
	end

	local haveAllTools = true;
	for tools,_ in pairs(modData.tools or {}) do
		local haveOneTool = false;
		for _,tool in pairs(bcUtils.split(tools, "/")) do
			if self.character:getInventory():FindAndReturn(tool) then
				haveOneTool = true;
			end
		end
		if (haveAllTools) and (not haveOneTool) then
			haveAllTools = false;
		end
	end

	if not haveAllTools then
		self.character:Say("I don't have the required tools.");
		self:stop();
		return;
	end

	if not canProgress then
		if maxPartsProgress < 100 then
			self.character:Say("I don't have the necessary parts.");
		else
			self.character:Say("I can't progress on this project.");
		end
		self:stop();
		return;
	end

	local timeHours = getGameTime():getTimeOfDay();
	if not self.lastCheck then self.lastCheck = timeHours; end
	if timeHours < self.lastCheck then timeHours = timeHours + 24 end
	local elapsedMins = (timeHours - self.lastCheck) * 60
	local progress = math.floor(elapsedMins + 0.0001)
	if progress > 0 then
		self.lastCheck = timeHours;
		canProgress.progress = math.min(canProgress.progress + progress, canProgress.time);
	end

	if canProgress.progress >= canProgress.time then
		self:checkIfFinished();
	end
end
-- }}}

function BCCrafTecTA:start() -- {{{
	--self.object:setJobType('CrafTec '.. self.object:getModData()["CrafTec"]["product"]);
	--self.object:setJobDelta(0.0);
	self.startTimeHours = getGameTime():getTimeOfDay()
	self.lastCheck = self.startTimeHours;
end
-- }}}

function BCCrafTecTA:stop() -- {{{
	if self.stopped then return end;
	ISBaseTimedAction.stop(self);
	self.stopped = true;
	self:checkIfFinished();
end
-- }}}

function BCCrafTecTA:perform() -- {{{
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end
-- }}}

function BCCrafTecTA:checkIfFinished() -- {{{
	if not self.object then return end

	local modData = self.object:getModData()["recipe"];

	for k,skills in pairs(modData.requirements) do
		for k2,s in pairs(skills) do
			if s.progress < s.time then
				return;
			end
		end
	end

	-- TODO
	--local inventory = self.character:getInventory();
	--inventory:AddItem(modData["product"]);
	--inventory:Remove(self.item);

	self.object = nil;
	if not self.stopped then
		self:stop();
	end
end
-- }}}

function BCCrafTecTA:calculateMaxTime() -- {{{
	local requirements = self.object:getModData()["recipe"]["requirements"];
	local retVal = 1;

	for _,p in pairs(requirements) do
		for _,v in pairs(p) do
			if not v.progress then v.progress = 0; end
			retVal = retVal + v.time - v.progress;
		end
	end

	local f = 1 / getGameTime():getMinutesPerDay() / 2;
	retVal = retVal / f; -- taken from ISReadABook, not sure why it's this way

	return retVal;
end
-- }}}

function BCCrafTecTA:new(character, object) -- {{{
	local modData = object:getModData();
	if not modData.recipe then
		getSpecificPlayer(character):Say("BUG CRAFTEC001: object has no modData.recipe");
		return false;
	end

	local o = {}

	setmetatable(o, self)
	self.__index = self
	o.character = getSpecificPlayer(character);
	o.object = object;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.stopped = false;

	o.maxTime = o:calculateMaxTime();
	return o;
end
-- }}}

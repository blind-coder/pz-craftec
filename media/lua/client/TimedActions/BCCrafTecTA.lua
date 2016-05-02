require "TimedActions/ISBaseTimedAction"

BCCrafTecTA = ISBaseTimedAction:derive("BCCrafTecTA");
BCCrafTecTA.worldCraftingFinished = function(object, recipe, character, retVal) -- {{{
	if retVal.object then return end; -- might be overriden by another event

	local md = object:getModData()["recipe"];
	local images = BCCrafTec.getImages(getSpecificPlayer(character), recipe);
	if md.resultClass == "ISLightSource" then
		-- FIXME this is really bad, but necessary for proper compatibility.
		local it = getSpecificPlayer(character):getInventory():AddItem("Base.Torch");
		it:setUsedDelta(recipe.ingredientData["Base.Torch"][1].UsedDelta);
		it:setUseDelta(recipe.ingredientData["Base.Torch"][1].UseDelta);
		-- FIXME End

		retVal.object = ISLightSource:new(images.west, images.north, character);
	elseif md.resultClass == "ISSimpleFurniture" then
		retVal.object = ISSimpleFurniture:new(md.name, images.west, images.north);
	elseif md.resultClass == "ISWoodenContainer" then
		retVal.object = ISWoodenContainer:new(images.west, images.north);
	elseif md.resultClass == "ISWoodenDoorFrame" then
		retVal.object = ISWoodenDoorFrame:new(images.west, images.north, images.corner);
	elseif md.resultClass == "ISWoodenDoor" then
		retVal.object = ISWoodenDoor:new(images.west, images.north, images.open, images.openNorth);
	elseif md.resultClass == "ISWoodenFloor" then
		retVal.object = ISWoodenFloor:new(images.west, images.north);
	elseif md.resultClass == "ISWoodenWall" then
		retVal.object = ISWoodenWall:new(images.west, images.north, images.corner);
	elseif md.resultClass == "RainCollectorBarrel" then
		retVal.object = RainCollectorBarrel:new(character, images.west, md.data.waterMax);
	elseif md.resultClass == "ISWoodenStairs" then
		retVal.object = ISWoodenStairs:new(images.sprite1, images.sprite2, images.sprite3, images.northSprite1, images.northSprite2, images.northSprite3, images.pillar, images.pillarNorth)
	elseif md.resultClass == "ISDoubleTileFurniture" then
		retVal.object = ISDoubleTileFurniture:new(md.name, images.sprite1, images.sprite2, images.northSprite1, images.northSprite2)
	end
end
-- }}}
BCCrafTecTA.worldCraftingObjectCreated = function(object, recipe, character, object) -- {{{
	-- Is this nice? No. Does it work? Probably.
	-- if recipe.resultClass == "ISLightSource" then
		-- object.javaObject:setLifeLeft(recipe.ingredientData["Base.Torch"][1].UsedDelta);
		-- object.javaObject:setLifeDelta(recipe.ingredientData["Base.Torch"][1].UseDelta);
		-- object.javaObject:setHaveFuel(recipe.ingredientData["Base.Torch"][1].UsedDelta > 0);
	-- end
	if recipe.resultClass == "ISWoodenDoor" then
		object.javaObject:setKeyId(recipe.ingredientData["Base.Doorknob"][1].KeyId, false);
	elseif recipe.resultClass == "RainCollectorBarrel" then
		object.javaObject:setName("Rain Collector Barrel");
	end
end
-- }}}
local copyData = function(javaObject, dst) -- {{{
	local md = javaObject:getModData();
	dst.name = md.recipe.name or dst.name;

	for k,v in pairs(md.recipe.data) do
		if k ~= "modData" then
			if type(v) == "table" then
				dst[k] = bcUtils.cloneTable(v);
			else
				dst[k] = v;
			end
		end
	end
end
-- }}}
local copyModData = function(javaObject, dst) -- {{{
local md = javaObject:getModData();
local dmd = dst.javaObject:getModData();
for part,amount in pairs(md.recipe.ingredients) do
	dmd["need:"..part] = amount;
end

for k,v in pairs(md.recipe.data.modData) do
	if type(v) == "table" then
		dmd[k] = bcUtils.cloneTable(v);
	else
		dmd[k] = v;
	end
end

dst:getSprite(); -- sets sprite, north, west, south and east values
end
-- }}}
local createRealObjectFromCrafTec = function(crafTec, recipe, character)--{{{
local md = crafTec:getModData()["recipe"];
	local retVal = {};

	triggerEvent("OnWorldCraftingFinished", crafTec, recipe, character, retVal);

	o = retVal.object;
	local images = BCCrafTec.getImages(getSpecificPlayer(character), recipe);
	o:setSprite(images.west);
	o:setNorthSprite(images.north);
	o:setEastSprite(images.east);
	o:setSouthSprite(images.south);

	local x = crafTec:getSquare():getX();
	local y = crafTec:getSquare():getY();
	local z = crafTec:getSquare():getZ();

	local cell = getWorld():getCell();
	o.sq = cell:getGridSquare(x, y, z);

	o.player = character;
	o.character = getSpecificPlayer(character);
	copyData(crafTec, o);
	o.sprite = o:getSprite(); -- copyData sets nSprite (added in BCCrafTecObject:create), so this sets .sprite and the north, east, south and west options

	local saveFunc = buildUtil.consumeMaterial;
	buildUtil.consumeMaterial = function() end
	o:create(x, y, z, o.north, o.sprite);
	buildUtil.consumeMaterial = saveFunc;

	triggerEvent("OnWorldCraftingObjectCreated", crafTec, recipe, character, o);

	copyModData(crafTec, o);
	return o;
end
--}}}

function BCCrafTecTA:isValid(square, north) -- {{{
	if self.stopped then return false end;
	if not self.haveAllTools then
		self.character:Say("I don't have the required tools.");
		self:stop();
		return false;
	end

	if bcUtils.tableIsEmpty(self.canProgress) then
		if not self:checkIfFinished() then
			if self.maxPartsProgress < 100 then
				self.character:Say("I don't have the necessary parts.");
			else
				if self.isDeconstruction then
					return true;
				else
					self.character:Say("I don't have the necessary skills.");
				end
			end
			self:stop();
			return false;
		end
	end

	return true;
end
-- }}}
function BCCrafTecTA:update() -- {{{
	if self.stopped then return end;

	local timeHours = getGameTime():getTimeOfDay();
	if not self.lastCheck then self.lastCheck = timeHours; end
	if timeHours < self.lastCheck then timeHours = timeHours + 24 end
	local elapsedMins = (timeHours - self.lastCheck) * 60
	local progress = math.floor(elapsedMins + 0.0001)
	if progress > 0 then
		self.lastCheck = timeHours;
		for _,skill in pairs(self.canProgress) do
			if self.isDeconstruction then
				if skill.progress > 0 then
					if skill.progress - progress < 0 then
						progress = progress - skill.progress;
						skill.progress = 0;
					else
						skill.progress = skill.progress - progress;
						progress = 0;
					end
				end
			else
				if skill.progress < (skill.time / (100 / self.maxPartsProgress)) then
					if skill.progress + progress > skill.time then
						progress = progress - (skill.time - skill.progress);
						skill.progress = skill.time;
					else
						skill.progress = skill.progress + progress;
						progress = 0;
					end
				end
			end
		end
	end

	self:checkIfFinished();
end
-- }}}
function BCCrafTecTA:start() -- {{{
	--TODO: set job delta for any required tools
	--self.object:setJobType('CrafTec '.. self.object:getModData()["CrafTec"]["product"]);
	--self.object:setJobDelta(0.0);

	self.startTimeHours = getGameTime():getTimeOfDay()
	self.lastCheck = self.startTimeHours;
end
-- }}}
function BCCrafTecTA:stop() -- {{{
	-- TODO: remove ourselves from the queue properly
	ISBaseTimedAction.stop(self);
	if self.stopped then return end;
	self.stopped = true;
	self:checkIfFinished();
end
-- }}}
function BCCrafTecTA:perform() -- {{{
	if not self:checkIfFinished() then
		self.character:Say("I've done all I could right now.");
	end
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end
-- }}}
function BCCrafTecTA:restoreItemInformation(item) -- {{{
	if not self.recipe.ingredientData then self.recipe.ingredientData = {} end
	if not self.recipe.ingredientData[item:getFullType()] then self.recipe.ingredientData[item:getFullType()]= {} end
	local table = self.recipe.ingredientData[item:getFullType()];
	local data = table[#table]
	if tostring(data) == "nil" then return end;
	-- table[#table] = nil;

	if instanceof(item, "DrainableComboItem") then
		item:setUsedDelta(data.UsedDelta);
		item:setUseDelta(data.UseDelta);
	end

	if  data.A                     and  item.setA                     then  item:setA(data.A)                                        end;
	if  data.R                     and  item.setR                     then  item:setR(data.R)                                        end;
	if  data.G                     and  item.setG                     then  item:setG(data.G)                                        end;
	if  data.B                     and  item.setB                     then  item:setB(data.B)                                        end;
	if  data.Name                  and  item.setName                  then  item:setName(data.Name)                                  end;
	if  data.ReplaceOnUse          and  item.setReplaceOnUse          then  item:setReplaceOnUse(data.ReplaceOnUse)                  end;
	if  data.ConditionMax          and  item.setConditionMax          then  item:setConditionMax(data.ConditionMax)                  end;
	if  data.Texture               and  item.setTexture               then  item:setTexture(data.Texture)                            end;
	if  data.Texturerotten         and  item.setTexturerotten         then  item:setTexturerotten(data.Texturerotten)                end;
	if  data.TextureCooked         and  item.setTextureCooked         then  item:setTextureCooked(data.TextureCooked)                end;
	if  data.TextureBurnt          and  item.setTextureBurnt          then  item:setTextureBurnt(data.TextureBurnt)                  end;
	if  data.Uses                  and  item.setUses                  then  item:setUses(data.Uses)                                  end;
	if  data.Age                   and  item.setAge                   then  item:setAge(data.Age)                                    end;
	if  data.LastAged              and  item.setLastAged              then  item:setLastAged(data.LastAged)                          end;
	if  data.CookingTime           and  item.setCookingTime           then  item:setCookingTime(data.CookingTime)                    end;
	if  data.MinutesToCook         and  item.setMinutesToCook         then  item:setMinutesToCook(data.MinutesToCook)                end;
	if  data.MinutesToBurn         and  item.setMinutesToBurn         then  item:setMinutesToBurn(data.MinutesToBurn)                end;
	if  data.OffAge                and  item.setOffAge                then  item:setOffAge(data.OffAge)                              end;
	if  data.OffAgeMax             and  item.setOffAgeMax             then  item:setOffAgeMax(data.OffAgeMax)                        end;
	if  data.Weight                and  item.setWeight                then  item:setWeight(data.Weight)                              end;
	if  data.ActualWeight          and  item.setActualWeight          then  item:setActualWeight(data.ActualWeight)                  end;
	if  data.WorldTexture          and  item.setWorldTexture          then  item:setWorldTexture(data.WorldTexture)                  end;
	if  data.Description           and  item.setDescription           then  item:setDescription(data.Description)                    end;
	if  data.Condition             and  item.setCondition             then  item:setCondition(data.Condition)                        end;
	if  data.OffString             and  item.setOffString             then  item:setOffString(data.OffString)                        end;
	if  data.CookedString          and  item.setCookedString          then  item:setCookedString(data.CookedString)                  end;
	if  data.UnCookedString        and  item.setUnCookedString        then  item:setUnCookedString(data.UnCookedString)              end;
	if  data.BurntString           and  item.setBurntString           then  item:setBurntString(data.BurntString)                    end;
	if  data.Module                and  item.setModule                then  item:setModule(data.Module)                              end;
	if  data.BoredomChange         and  item.setBoredomChange         then  item:setBoredomChange(data.BoredomChange)                end;
	if  data.UnhappyChange         and  item.setUnhappyChange         then  item:setUnhappyChange(data.UnhappyChange)                end;
	if  data.StressChange          and  item.setStressChange          then  item:setStressChange(data.StressChange)                  end;
	if  data.ReplaceOnUseOn        and  item.setReplaceOnUseOn        then  item:setReplaceOnUseOn(data.ReplaceOnUseOn)              end;
	if  data.Count                 and  item.setCount                 then  item:setCount(data.Count)                                end;
	if  data.LightStrength         and  item.setLightStrength         then  item:setLightStrength(data.LightStrength)                end;
	if  data.LightDistance         and  item.setLightDistance         then  item:setLightDistance(data.LightDistance)                end;
	if  data.FatigueChange         and  item.setFatigueChange         then  item:setFatigueChange(data.FatigueChange)                end;
	if  data.CurrentCondition      and  item.setCurrentCondition      then  item:setCurrentCondition(data.CurrentCondition)          end;
	if  data.CustomMenuOption      and  item.setCustomMenuOption      then  item:setCustomMenuOption(data.CustomMenuOption)          end;
	if  data.Tooltip               and  item.setTooltip               then  item:setTooltip(data.Tooltip)                            end;
	if  data.DisplayCategory       and  item.setDisplayCategory       then  item:setDisplayCategory(data.DisplayCategory)            end;
	if  data.HaveBeenRepaired      and  item.setHaveBeenRepaired      then  item:setHaveBeenRepaired(data.HaveBeenRepaired)          end;
	if  data.ReplaceOnBreak        and  item.setReplaceOnBreak        then  item:setReplaceOnBreak(data.ReplaceOnBreak)              end;
	if  data.DisplayName           and  item.setDisplayName           then  item:setDisplayName(data.DisplayName)                    end;
	if  data.BreakSound            and  item.setBreakSound            then  item:setBreakSound(data.BreakSound)                      end;
	if  data.AlcoholPower          and  item.setAlcoholPower          then  item:setAlcoholPower(data.AlcoholPower)                  end;
	if  data.BandagePower          and  item.setBandagePower          then  item:setBandagePower(data.BandagePower)                  end;
	if  data.ReduceInfectionPower  and  item.setReduceInfectionPower  then  item:setReduceInfectionPower(data.ReduceInfectionPower)  end;
	if  data.ContentsWeight        and  item.setContentsWeight        then  item:setContentsWeight(data.ContentsWeight)              end;
	if  data.EquippedWeight        and  item.setEquippedWeight        then  item:setEquippedWeight(data.EquippedWeight)              end;
	if  data.UnequippedWeight      and  item.setUnequippedWeight      then  item:setUnequippedWeight(data.UnequippedWeight)          end;
	if  data.KeyId                 and  item.setKeyId                 then  item:setKeyId(data.KeyId)                                end;
	if  data.RemoteControlID       and  item.setRemoteControlID       then  item:setRemoteControlID(data.RemoteControlID)            end;
	if  data.RemoteRange           and  item.setRemoteRange           then  item:setRemoteRange(data.RemoteRange)                    end;
	if  data.ExplosionSound        and  item.setExplosionSound        then  item:setExplosionSound(data.ExplosionSound)              end;
	if  data.CountDownSound        and  item.setCountDownSound        then  item:setCountDownSound(data.CountDownSound)              end;
	if  data.ColorRed              and  item.setColorRed              then  item:setColorRed(data.ColorRed)                          end;
	if  data.ColorGreen            and  item.setColorGreen            then  item:setColorGreen(data.ColorGreen)                      end;
	if  data.ColorBlue             and  item.setColorBlue             then  item:setColorBlue(data.ColorBlue)                        end;
	if  data.EvolvedRecipeName     and  item.setEvolvedRecipeName     then  item:setEvolvedRecipeName(data.EvolvedRecipeName)        end;
end
-- }}}
function BCCrafTecTA:checkIfFinished() -- {{{
	if not self.object then return end

	for k,skills in pairs(self.recipe.requirements) do
		for k2,s in pairs(skills) do
			if self.isDeconstruction then
				if s.progress > 0 then
					return false;
				end
			elseif s.progress < s.time then
				return false;
			end
		end
	end

	if self.isDeconstruction then
		local sq = self.object:getSquare();
		for part,amount in pairs(self.recipe.ingredientsAdded) do
			for i=0,amount-1 do
				local newItem = sq:AddWorldInventoryItem(part, 0, 0, 0);
				self:restoreItemInformation(newItem);
			end
		end
		self.recipe.ingredientsAdded.amount = 0;
	else
		createRealObjectFromCrafTec(self.object, self.recipe, self.player);
	end

	local sq = self.object:getSquare();
	if isClient() then
		sq:transmitRemoveItemFromSquare(self.object);
	end
	sq:RemoveTileObject(self.object);

	self.object = nil;
	if not self.stopped then
		self:stop();
	end
	return true;
end
-- }}}
function BCCrafTecTA:calculateMaxTime() -- {{{
	local retVal = 1;

	for _,skill in pairs(self.canProgress) do
		if not skill.progress then skill.progress = 0; end
		if self.isDeconstruction then
			retVal = retVal + skill.progress;
		else
			retVal = retVal + (skill.time - skill.progress) / (100 / self.maxPartsProgress);
		end
	end

	local f = 1 / getGameTime():getMinutesPerDay() / 2;
	retVal = retVal / f; -- taken from ISReadABook, not sure why it's this way
	retVal = retVal + 2 / f; -- go over time a bit so we don't stop 2 minutes early

	return retVal;
end
-- }}}
function BCCrafTecTA:getImages() -- {{{
	-- duplicated in BCCrafTecWorldMenu.lua
	local recipe = self.recipe;
	local character = self.character;
	if recipe.images.any ~= nil then
		return recipe.images.any;
	end
	for perk,levels in pairs(recipe.images) do
		local retVal = {};
		local perkLevel = character:getPerkLevel(Perks.FromString(perk));
		local oldLevel = -1;
		for level,images in pairs(levels) do
			if level > oldLevel and perkLevel >= level then
				retVal = images;
				level = oldLevel;
			end
		end
		return retVal;
	end
end
-- }}}

function BCCrafTecTA:new(character, object, isDeconstruction) -- {{{
	local modData = object:getModData();
	if not modData.recipe then
		getSpecificPlayer(character):Say("BUG CRAFTEC001: object has no modData.recipe");
		return false;
	end

	local o = {}

	setmetatable(o, self)
	self.__index = self
	o.isDeconstruction = isDeconstruction;
	o.character = getSpecificPlayer(character);
	o.player = character;
	o.object = object;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.stopped = false;

	o.recipe = o.object:getModData()["recipe"];

	o.maxPartsProgress = 100;
	if not o.isDeconstruction then
		for part,amount in pairs(o.recipe.ingredients) do
			local avail = (o.recipe.ingredientsAdded and o.recipe.ingredientsAdded[part]) or 0;
			o.maxPartsProgress = math.min(avail*100/amount, o.maxPartsProgress);
		end
	end

	o.haveAllTools = true;
	for _,tools in pairs(o.recipe.tools or {}) do
		local haveOneTool = false;
		for _,tool in pairs(bcUtils.split(tools, "/")) do
			if o.character:getInventory():FindAndReturn(tool) then
				haveOneTool = true;
			end
		end
		o.haveAllTools = o.haveAllTools and haveOneTool;
	end

	o.canProgress = {};

	local prof = o.character:getDescriptor():getProfession();
	for profession,skills in pairs(o.recipe.requirements) do
		if o.isDeconstruction then
			for k,skill in pairs(skills) do
				if skill.progress > 0 then
					table.insert(o.canProgress, skill);
				end
			end
		elseif (profession == prof) or (profession == "any") then
			for k,skill in pairs(skills) do
				if (skill.progress < skill.time) and (skill.progress < skill.time / (100 / o.maxPartsProgress))
				and ((k == "any") or o.character:getPerkLevel(Perks.FromString(k)) >= skill.level) then
					table.insert(o.canProgress, skill);
				end
			end
		end
	end

	o.maxTime = o:calculateMaxTime();
	return o;
end
-- }}}

LuaEventManager.AddEvent("OnWorldCraftingFinished");
LuaEventManager.AddEvent("OnWorldCraftingObjectCreated");
Events.OnWorldCraftingFinished.Add(BCCrafTecTA.worldCraftingFinished);
Events.OnWorldCraftingObjectCreated.Add(BCCrafTecTA.worldCraftingObjectCreated);

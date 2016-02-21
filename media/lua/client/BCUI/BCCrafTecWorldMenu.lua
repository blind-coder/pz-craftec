require "bcUtils_client"

if not BCCrafTec then BCCrafTec = {} end
--[[
-- {{{
--To extend CrafTecs, just add to this object like this:
--Simple recipe:
--local recipe = {};
--recipe.name = "Makeshift chair";
--recipe.resultClass = "ISSimpleFurniture";
--recipe.images = { west = "chair_west", north = "chair_north", east = "chair_east", south = "chair_south" };
--recipe.tools = {}; -- no tools
--recipe.ingredients = { ["Base.Plank"] = 4, ["Base.RippedSheets"] = 4};
--recipe.requirements = { any = { any = { level = 0, time = 60, progress = 0 } } };
--table.insert(BCCrafTec.Recipes, recipe);
--
--More complex:
--lecal recipe = {};
--recipe.name = "Metal sheet wall";
--recipe.resultClass = "MyModMetalSheetWall";
--recipe.images = { west = "mymod_sheetwall_west", north = "mymod_sheetwall_north", east = nil, south = nil };
--recipe.tools = { "MyMod.Blowtorch", "MyMod.Simplegloves/MyMod.Workinggloves" }; -- require a blowtorch and either simple gloves or working gloves
--recipe.ingredients = { ["MyMod.Metalsheet"] = 4, ["MyMod.Blowtorchfuel"] = 1 };
--recipe.requirements = {
--	Engineer = {
--		Woodwork = { -- need an engineer with level 2 or better in woodwoorking for 600 minutes
--			level = 2,
--			time = 600,
--			progress = 0
--		}
--	},
--	Electrician = {
--		Electricity = { -- need an electrician with level 4 in electricity for 300 minutes
--			level = 4,
--			time = 300,
--			progress = 0
--		}
--	},
--	any = {
--		any = {
--			level = 0, -- need anyone else for 120 minutes
--			time = 120,
--			progress = 0
--		}
--	}
--};
--table.insert(BCCrafTec.Recipes, recipe);
-- }}}
--]] 

BCCrafTec.RecipesOld = { -- {{{
	{ product = getText("Logwall"),
		resultClass = "ISWoodenWall",
		ingredients = {["Base.Log"] = 4, ["Base.RippedSheets"] = 4},
		images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
		tools = {"Base.Hammer/Base.HammerStone", "Base.Saw"},
		canBarricade = false,
		requirements = { any = { any = { level = 0, time = 60, progress = 0 } } }
	},
	{ product = getText("Logwall"),
		resultClass = "ISWoodenWall",
		ingredients = { ["Base.Log"] = 4, ["Base.Twine"] = 4},
		images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
		tools = {},
		canBarricade = false,
		requirements = { any = { any = { level = 0, time = 60, progress = 0 } } }
	},
	{ product = getText("Logwall"),
		resultClass = "ISWoodenWall",
		ingredients = { ["Base.Log"] = 4, ["Base.Rope"] = 2},
		images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
		tools = {},
		canBarricade = false,
		requirements = { any = { any = { level = 0, time = 60, progress = 0 } } }
	}
};
-- }}}
-- {{{
BCCrafTec.Recipes = {
	ContextMenu_Wooden_Crate = {
		name = "Wooden crate",
		resultClass = "ISWoodenContainer",
		ingredients = {["Base.Plank"] = 2, ["Base.Nails"] = 2},
		images = {west = "carpentry_01_16", north = "carpentry_01_17", east = "carpentry_01_18", south = nil }, -- TODO level sprites crate.canBeAlwaysPlaced = true;
		tools = {"Base.Hammer/Base.HammerStone"},
		requirements = { any = { Woodwork = { level = 3, time = 60 } } },
	},
	Indoor = {
		isCategory = true,
		ContextMenu_Bar = {
			isCategory = true,
			ContextMenu_Bar_Element = {
				name = "Bar element",
				resultClass = "ISWoodenContainer",
				ingredients = {["Base.Plank"] = 4, ["Base.Nails"] = 4},
				images ={west = "carpentry_02_19", north = "carpentry_02_21", east = "carpentry_02_23", south = "carpentry_02_17" }, -- level 3 images only
				tools = {"Base.Hammer/Base.HammerStone"},
				requirements = { any = { Woodwork = { level = 7, time = 60 } } },
			},
			ContextMenu_Bar_Corner = {
				name = "Bar corner",
				resultClass = "ISWoodenContainer",
				ingredients = {["Base.Plank"] = 4, ["Base.Nails"] = 4},
				images = {west = "carpentry_02_18", north = "carpentry_02_20", east = "carpentry_02_22", south = "carpentry_02_16"}, -- level 3 images only
				tools = {"Base.Hammer/Base.HammerStone"},
				requirements = { any = { Woodwork = { level = 7, time = 60 } } },
			}
		},
		ContextMenu_Bed = {
			name = "Bed",
			resultClass = "ISDoubleTileFurniture", -- uh-oh
			ingredients = {["Base.Plank"] = 6, ["Base.Nails"] = 4, ["Base.Mattress"] = 1},
			images = {sprite1 = "carpentry_02_73", sprite2 = "carpentry_02_72", northSprite1 = "carpentry_02_74", northSprite2 = "carpentry_02_75"},
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 4, time = 80 } } },
		},
		ContextMenu_Bookcase = {
			name = "Bookcase",
			resultClass = "ISSimpleFurniture",
			ingredients = {["Base.Plank"] = 5, ["Base.Nails"] = 4},
			images = {west = "furniture_shelving_01_41", north = "furniture_shelving_01_40", east = "furniture_shelving_01_42", south = "furniture_shelving_01_43"}, -- TODO level images furniture.canBeAlwaysPlaced = true furniture.isContainer = true;furniture.containerType = "shelves" 
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 5, time = 60 } } },
		},
		ContextMenu_SmallBookcase = {
			name = "Small bookcase",
			resultClass = "ISSimpleFurniture",
			ingredients = {["Base.Plank"] = 3, ["Base.Nails"] = 3},
			images = {west = "furniture_shelving_01_23", north = "furniture_shelving_01_19", east = nil, south = nil}, -- TODO level images furniture.canBeAlwaysPlaced = true furniture.isContainer = true;furniture.containerType = "shelves" 
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 3, time = 30 } } },
		},
		ContextMenu_Shelves = {
			name = "Shelf",
			resultClass = "ISSimpleFurniture",
			ingredients = {["Base.Plank"] = 1, ["Base.Nails"] = 2},
			images = {west = "carpentry_02_68", north = "carpentry_02_69", east = nil, south = nil}, -- TODO level images furniture.isContainer = true furniture.needToBeAgainstWall = true furniture.blockAllTheSquare = false furniture.containerType = "shelves"
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 2, time = 30 } } },
		},
		ContextMenu_DoubleShelves = {
			name = "Two shelves",
			resultClass = "ISSimpleFurniture",
			ingredients = {["Base.Plank"] = 2, ["Base.Nails"] = 4},
			images = {west = "furniture_shelving_01_2", north = "furniture_shelving_01_1", east = nil, south = nil}, -- TODO level images furniture.isContainer = true furniture.needToBeAgainstWall = true furniture.blockAllTheSquare = false furniture.containerType = "shelves"
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 4, time = 30 } } },
		},
		ContextMenu_Small_Table = {
			name = "Small table",
			resultClass = "ISSimpleFurniture",
			ingredients = {["Base.Plank"] = 5, ["Base.Nails"] = 4},
			images = {west = "carpentry_01_62", north = nil, east = nil, south = nil}, -- TODO level images
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 3, time = 60 } } },
		},
		ContextMenu_Large_Table = {
			name = "Large table",
			resultClass = "ISDoubleTileFurniture", -- TODO uh-oh
			ingredients = {["Base.Plank"] = 6, ["Base.Nails"] = 4},
			images = {sprite1 = "carpentry_01_33", sprite2 = "carpentry_01_32", northSprite1 = "carpentry_01_34", northSprite2 = "carpentry_01_35"}, -- TODO level images
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 4, time = 90 } } },
		},
		ContextMenu_Table_with_Drawer = {
			name = "Table with drawer",
			resultClass = "ISWoodenContainer",
			ingredients = {["Base.Plank"] = 5, ["Base.Nails"] = 4, ["Base.Drawer"] = 1},
			images = {west = "carpentry_02_8", north = "carpentry_02_10", east = "carpentry_02_11", south = "carpentry_02_9"}, -- TODO level images furniture.isContainer = true;
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 5, time = 60 } } },
		},
		ContextMenu_Wooden_Chair = {
			name = "Wooden chair",
			resultClass = "ISSimpleFurniture",
			ingredients = {["Base.Plank"] = 5, ["Base.Nails"] = 4},
			images = {west = "carpentry_01_45", north = "carpentry_01_44", east = "carpentry_01_47", south = "carpentry_01_46"}, -- TODO level images furniture.canPassThrough = true;
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 2, time = 30 } } },
		}
	},
	Outdoor = {
		isCategory = true,
		ContextMenu_Lamp_on_Pillar = {
			name = "Lamp on pillar",
			resultClass = "ISLightSource",
			ingredients = {["Base.Plank"] = 2, ["Base.Nails"] = 4, ["Base.Torch"] = 1, ["Base.Rope"] = 1}, -- TODO: lamp.fuel = Base.Battery lamp.baseItem = Torch lamp.radius = 10
			images = {west = "carpentry_02_61", north = "carpentry_02_60", east = "carpentry_02_62", south = "carpentry_02_59"},
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 4, time = 40 } } },
		},
		ContextMenu_Rain_Collector_Barrel = {
			name = "Rain collector",
			resultClass = "RainCollectorBarrel",
			ingredients = {["Base.Plank"] = 2, ["Base.Nails"] = 4, ["Base.Garbagebag"] = 2}, -- TODO: RainCollectorBarrel.smallWaterMax
			images = {west = "carpentry_02_54", north = "carpentry_02_54", east = nil, south = nil},
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 4, time = 60 } } },
		},
		ContextMenu_Rain_Collector_Barrel = {
			name = "Rain collector",
			resultClass = "RainCollectorBarrel",
			ingredients = {["Base.Plank"] = 4, ["Base.Nails"] = 4, ["Base.Garbagebag"] = 4}, -- TODO: RainCollectorBarrel.largeWaterMax
			images = {west = "carpentry_02_52", north = "carpentry_02_52", east = nil, south = nil},
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 7, time = 90 } } },
		},
		ContextMenu_Sign = {
			name = "Sign",
			resultClass = "ISSimpleFurniture",
			ingredients = {["Base.Plank"] = 3, ["Base.Nails"] = 3},
			images = {west = "constructedobjects_signs_01_27", north = "constructedobjects_signs_01_11", east = nil, south = nil}, -- TODO furniture.blockAllTheSquare = false
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 1, time = 10 } } },
		}
	},
	Fence = {
		isCategory = true,
		ContextMenu_Wooden_Stake = {
			name = "Wooden stake",
			resultClass = "ISWoodenWall",
			ingredients = {["Base.Plank"] = 1, ["Base.Nails"] = 2},
			images = {west = "fencing_01_19", north = "fencing_01_19", east = nil, south = nil},
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 5, time = 20 } } },
		},
		ContextMenu_Wooden_Fence = {
			name = "Wooden fence",
			resultClass = "ISWoodenWall",
			ingredients = {["Base.Plank"] = 2, ["Base.Nails"] = 3},
			images = {west = "carpentry_02_48", north = "carpentry_02_49", east = nil, south = nil, corner = "carpentry_02_51"}, -- TODO corner?! WTF? -- TODO carpentry levels
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 2, time = 30 } } },
		},
		ContextMenu_Barbed_Fence = {
			name = "Barbed fence",
			resultClass = "ISWoodenWall",
			ingredients = {["Base.BarbedWire"] = 1},
			images = {west = "fencing_01_20", north = "fencing_01_20", east = nil, south = nil},
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 5, time = 30 } } },
		},
		ContextMenu_Sand_Bag_Wall = {
			name = "Sandbag wall",
			resultClass = "ISWoodenWall",
			ingredients = {["Base.Sandbag"] = 3},
			images = {west = "carpentry_02_12", north = "carpentry_02_13", east = "carpentry_02_14", south = "carpentry_02_15"},
			tools = {},
			requirements = { any = { any = { level = 0, time = 10 } } },
		},
		ContextMenu_Gravel_Bag_Wall = {
			name = "Gravelbag wall",
			resultClass = "ISWoodenWall",
			ingredients = {["Base.Gravelbag"] = 3},
			images = {west = "carpentry_02_12", north = "carpentry_02_13", east = "carpentry_02_14", south = "carpentry_02_15"},
			tools = {},
			requirements = { any = { any = { level = 0, time = 10 } } },
		}
	},
	Floor = {
		isCategory = true,
		ContextMenu_Wooden_Floor = {
			name = "Wooden floor",
			resultClass = "ISWoodenFloor",
			ingredients = {["Base.Log"] = 1, ["Base.Nails"] = 1},
			images = { west = "carpentry_02_56", north = "carpentry_02_56", east = nil, south = nil }, -- TODO level sprites
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 1, time = 15, progress = 0 } } }
		}
	},
	Stairs = {
		isCategory = true,
		ContextMenu_Stairs = {
			name = "Wooden stairs",
			resultClass = "ISWoodenStairs",
			ingredients = {["Base.Plank"] = 8, ["Base.Nails"] = 8},
			images = { "fixtures_stairs_01_16", "fixtures_stairs_01_17", "fixtures_stairs_01_18", "fixtures_stairs_01_24", "fixtures_stairs_01_25", "fixtures_stairs_01_26", "fixtures_stairs_01_22", "fixtures_stairs_01_23" }, -- TODO uh-oh stairs.isThumpable = false;
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 6, time = 240, progress = 0 } } }
		}
	},
	Walls = {
		isCategory = true,
		ContextMenu_Log_Wall = {
			isCategory = true,
			ContextMenu_Log_Wall_With_Sheets = {
				name = "Logwall",
				resultClass = "ISWoodenWall",
				ingredients = {["Base.Log"] = 4, ["Base.RippedSheets"] = 4},
				images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
				tools = {},
				requirements = { any = { any = { level = 0, time = 30, progress = 0 } } }
			},
			ContextMenu_Log_Wall_With_Twine = {
				name = "Logwall",
				resultClass = "ISWoodenWall",
				ingredients = { ["Base.Log"] = 4, ["Base.Twine"] = 4},
				images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
				tools = {},
				requirements = { any = { any = { level = 0, time = 30, progress = 0 } } }
			},
			ContextMenu_Log_Wall_With_Rope= {
				name = "Logwall",
				resultClass = "ISWoodenWall",
				ingredients = { ["Base.Log"] = 4, ["Base.Rope"] = 2},
				images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
				tools = {},
				requirements = { any = { any = { level = 0, time = 30, progress = 0 } } }
			}
		},
		ContextMenu_Wooden_Door = {
			name = "Wooden door",
			resultClass = "ISWoodenDoor",
			ingredients = { ["Base.Plank"] = 4, ["Base.Nails"] = 4, ["Base.Hinge"] = 2, ["Base.Doorknob"] = 1},
			images = { west = "carpentry_01_56", north = "carpentry_01_57", open = "carpentry_01_58", openNorth = "carpentry_01_59" }, -- TODO level sprites opensprites doorknob id
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 2, time = 30, progress = 0 } } }
		},
		ContextMenu_Door_Frame = {
			name = "Door frame",
			resultClass = "ISWoodenDoorFrame",
			ingredients = { ["Base.Plank"] = 4, ["Base.Nails"] = 4 },
			images = { west = "walls_exterior_wooden_01_34", north = "walls_exterior_wooden_01_35", east = nil, south = nil, corner = "walls_exterior_wooden_01_27"}, -- TODO level sprites corner doorFrame.modData["wallType"] = "doorframe" doorFrame.canBePlastered = true
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 2, time = 60, progress = 0 } } }
		},
		ContextMenu_Windows_Frame = {
			name = "Window frame",
			resultClass = "ISWoodenWall",
			ingredients = { ["Base.Plank"] = 4, ["Base.Nails"] = 4},
			images = { west = "walls_exterior_wooden_01_32", north = "walls_exterior_wooden_01_33", east = nil, south = nil, corner = "walls_exterior_wooden_01_27"}, -- TODO frame.canBePlastered = true frame.hoppable = true frame.isThumpable = false level sprites corner
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 2, time = 30, progress = 0 } } }
		},
		ContextMenu_Wooden_Pillar = {
			name = "Wooden pillar",
			resultClass = "ISWoodenWall",
			ingredients = { ["Base.Plank"] = 2, ["Base.Nails"] = 3},
			images = { west = "walls_exterior_wooden_01_27", north = "walls_exterior_wooden_01_27", east = nil, south = nil},
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 2, time = 30, progress = 0 } } }
		},
		ContextMenu_Wooden_Wall = {
			name = "Wooden wall",
			resultClass = "ISWoodenWall",
			ingredients = { ["Base.Plank"] = 3, ["Base.Nails"] = 3},
			images = { west = "walls_exterior_wooden_01_24", north = "walls_exterior_wooden_01_25", east = nil, south = nil, corner = "walls_exterior_wooden_01_27" }, -- TODO level sprites TODO corner
			tools = {"Base.Hammer/Base.HammerStone"},
			requirements = { any = { Woodwork = { level = 2, time = 30, progress = 0 } } }
		}
	}
};
-- }}}

BCCrafTec.LogwallIsValid = function(self, square) -- {{{
	if not buildUtil.canBePlace(self, square) then
		return false;
	end
	if buildUtil.stairIsBlockingPlacement(square, true, (self.nSprite==4 or self.nSprite==2)) then
		return false;
	end
	return square:isFreeOrMidair(false);
end
-- }}}
BCCrafTec.startCrafTec = function(player, recipe) -- {{{
	local crafTec = BCCrafTecObject:new(recipe);

	crafTec.player = player;
	crafTec.noNeedHammer = true; -- do not need a hammer to _start_, but maybe later to _build_
	getCell():setDrag(crafTec, player);
end
-- }}}
BCCrafTec.buildCrafTec = function(player, object) -- {{{
	BCCrafTec.consumeMaterial(player, object);
	local ta = BCCrafTecTA:new(player, object);
	ISTimedActionQueue.add(ta);
end
-- }}}
BCCrafTec.consumeMaterial = function(player, object) -- {{{ -- taken and butchered from ISBuildUtil
	player = getSpecificPlayer(player);
  local inventory = player:getInventory();
  local recipe = object:getModData()["recipe"];
  local removed = false;
	for part,amount in pairs(recipe.ingredients) do
		if not recipe.ingredientsAdded then recipe.ingredientsAdded = {}; end
		if not recipe.ingredientsAdded[part] then recipe.ingredientsAdded[part] = 0; end

		amount = amount - recipe.ingredientsAdded[part];
		local checkGround = 0;
		-- if we didn't have all the required material inside our inventory,
		-- it's because the missing materials are on the ground, we gonna check them
		if inventory:getNumberOfItem(part) < amount then
			checkGround = amount - inventory:getNumberOfItem(part);
		end
		for i=1,(amount - checkGround) do
			inventory:Remove(inventory:FindAndReturn(part));
			recipe.ingredientsAdded[part] = recipe.ingredientsAdded[part] + 1;
		end

		-- for each missing material in inventory
		if checkGround > 0 then
			-- check a 3x3 square around the player
			for x=math.floor(player:getX())-1,math.floor(player:getX())+1 do
				for y=math.floor(player:getY())-1,math.floor(player:getY())+1 do
					local square = getCell():getGridSquare(x,y,math.floor(player:getZ()));
					local wobs = square and square:getWorldObjects() or nil;

					-- do we have the needed material on the ground ?
					if wobs ~= nil then
						local itemToRemove = {};
						for m=0, wobs:size()-1 do
							local o = wobs:get(m);
							if instanceof(o, "IsoWorldInventoryObject") and o:getItem():getFullType() == part then
								table.insert(itemToRemove, o);
								checkGround = checkGround - 1;
								if checkGround == 0 then
									break;
								end
							end
						end
						for i,v in pairs(itemToRemove) do
							square:transmitRemoveItemFromSquare(v);
							square:removeWorldObject(v);
							recipe.ingredientsAdded[part] = recipe.ingredientsAdded[part] + 1;
							removed = true
						end
						if checkGround == 0 then
							break;
						end
						itemToRemove = {};
					end
				end
				if checkGround == 0 then
					break;
				end
			end
		end
	end
	if removed then ISInventoryPage.dirtyUI() end
end
--}}}
BCCrafTec.makeTooltip = function(player, recipe) -- {{{
	local toolTip = ISToolTip:new();
	toolTip:initialise();
	--toolTip:setVisible(false);
	toolTip:setName("Project: "..getText(recipe.name));
	toolTip:setTexture(recipe.images.east);

	local desc = "Project: "..recipe.name.." <LINE> ";

	local needsTools = false;
	for _,tools in pairs(recipe.tools) do
		if not needsTools then
			needsTools = true;
			desc = desc .. "Needs tools: <LINE> ";
		end

		local first = true;
		desc = desc .. "  - ";
		for _,tool in pairs(bcUtils.split(tools, "/")) do
			local item = BCCrafTec.GetItemInstance(tool);
			if not first then
				desc = desc .. " / ";
			end
			local color = "";
			if ISBuildMenu.countMaterial(player, tool) <= 0 then
				color = " <RED> ";
			else
				color = " <GREEN> ";
			end
			desc = desc .. color..item:getDisplayName().." <RGB:1,1,1> ";
			first = false;
		end
		desc = desc .. " <LINE> ";
	end

	if recipe.started then
		-- Project on the ground
		desc = desc .. "Needs parts: <LINE> ";
		for ing,amount in pairs(recipe.ingredients) do
			local color = "";
			local item = BCCrafTec.GetItemInstance(ing);
			local avail = ISBuildMenu.countMaterial(player, ing);
			if avail + (recipe.ingredientsAdded and recipe.ingredientsAdded[ing] or 0) < amount then
				color = " <RED> ";
			else
				color = " <GREEN> ";
			end
			desc = desc .. "  - "..color..item:getDisplayName()..": "..((recipe.ingredientsAdded and recipe.ingredientsAdded[ing]) or 0).."+"..avail.."/"..amount.." <RGB:1,1,1>  <LINE> ";
		end
	else
		-- Tooltip in build menu
		desc = desc .. "Needs parts: <LINE> ";
		for ing,amount in pairs(recipe.ingredients) do
			local color = "";
			local item = BCCrafTec.GetItemInstance(ing);
			local avail = ISBuildMenu.countMaterial(player, ing); -- needs ISBuildMenu.materialOnGround above
			if (avail or 0) < amount then
				color = " <RED> ";
			else
				color = " <GREEN> ";
			end
			desc = desc .. "  - "..color..item:getDisplayName()..": "..(avail or 0).."/"..amount.." <RGB:1,1,1>  <LINE> ";
		end
	end

	for k,profession in pairs(recipe.requirements) do
		desc = desc .. "Profession: "..getText(k).." <LINE> ";
		for k,skill in pairs(profession) do
			if k ~= "any" then
				desc = desc .. "  Skill: "..getText(k).." Level "..skill["level"].." <LINE> ";
			end
			desc = desc .. "    Progress: "..skill["progress"].." / "..skill["time"].." <LINE> ";
		end
	end

	toolTip.description = desc;

	return toolTip;
end
-- }}}

BCCrafTec.GetItemInstance = function(type) -- {{{ taken from ISCraftingUI.lua
	if not BCCrafTec.ItemInstances then BCCrafTec.ItemInstances = {} end
	local item = BCCrafTec.ItemInstances[type];
	if not item then
		item = InventoryItemFactory.CreateItem(type);
		if item then
			BCCrafTec.ItemInstances[type] = item;
			BCCrafTec.ItemInstances[item:getFullType()] = item;
		else
			print("ERROR! Item not found: "..type);
		end
	end
	return item;
end
-- }}}

BCCrafTec.sanitizeRecipe = function(recipe)
	-- do some sanity checks that modders / devs might forget
	for pkey,pval in pairs(recipe.requirements) do
		for skey,sval in pairs(pval) do
			sval.progress = sval.progress or 0;
		end
	end
end

BCCrafTec.WorldMenu = function(player, context, worldObjects) -- {{{
	for _,object in ipairs(worldObjects) do
		local md = object:getModData();
		if md.recipe then
			local o = context:addOption("Continue "..getText(md.recipe.name), player, BCCrafTec.buildCrafTec, object);
			o.toolTip = BCCrafTec.makeTooltip(player, md.recipe);
		end
	end

	local subMenu = ISContextMenu:getNew(context);
	local buildOption = context:addOption("CrafTec");
	context:addSubMenu(buildOption, subMenu);

	BCCrafTec.doMenuRecursive(subMenu, BCCrafTec.Recipes, player);
end
BCCrafTec.doMenuRecursive = function(menu, recipes, player) -- {{{
	for name,recipe in pairs(recipes) do
		if name ~= "isCategory" then

			if recipe.isCategory then
				local subMenu = ISContextMenu:getNew(menu);
				local subMenuOption = menu:addOption(getText(name));
				menu:addSubMenu(subMenuOption, subMenu);
				BCCrafTec.doMenuRecursive(subMenu, recipe, player);
			else
				BCCrafTec.sanitizeRecipe(recipe);
				local o = menu:addOption(name, player, BCCrafTec.startCrafTec, recipe);
				o.toolTip = BCCrafTec.makeTooltip(player, recipe);
			end
		end

	end
end
-- }}}
Events.OnFillWorldObjectContextMenu.Add(BCCrafTec.WorldMenu);

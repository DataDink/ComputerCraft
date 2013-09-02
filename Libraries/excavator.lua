if (excavator == nil) then 
	excavator = {};
	
	(function() 
		local directions = {
			forward = 270, front = 270,
			rear = 90, back = 90, backward = 90,
			left = 180, 
			right = 0,
			up = "up",
			down = "down"
		};
	
		local position = {
			marker = { x = 0, y = 0, z = 0 },
			current = { x = 0, y = 0, z = 0, d = directions.forward }
		};
		position.mark = function() 
			position.marker.x = position.current.x; 
			position.marker.y = position.current.y; 
			position.marker.z = position.current.z; 
		end
		position.reset = function() 
			position.current.x = 0; 
			position.current.y = 0; 
			position.current.z = 0; 
			position.current.d = directions.forward; 
		end
		
		local fuel = {};
		local move = {};
		local inventory = {};
		
		-- Fuel
		fuel.movesPerFuel = 0;
		fuel.calcRemainingFuel = function() return turtle.getItemCount(1) * fuel.movesPerFuel + turtle.getFuelLevel(); end
		fuel.needsRefuel = function() return move.calcReturnDist() >= fuel.calcRemainingFuel(); end
		fuel.initialize = function()
			local before = turtle.getFuelLevel();
			turtle.select(inventory.fuelSlot);
			turtle.refuel(1);
			local after = turtle.getFuelLevel();
			fuel.movesPerFuel = after - before;
		end
		fuel.refuel = function()
			if (turtle.getFuelLevel() > 0) then return; end
			fuel.initialize();
		end
		
		-- Inventory
		inventory.fuelSlot = 1;
		inventory.calcRemainingSlots = function() 
			local count = 0;
			for i = 2, 16 do
				if (turtle.getItemCount(i) == 0) then count = count + 1; end
			end
			return count;
		end
		inventory.needsUnload = function() return inventory.calcRemainingSlots() == 0; end
		inventory.unload = function()
			move.face(directions.backward);
			for i = 2, 16 do
				if (turtle.getItemCount(i) > 0) then
					turtle.select(i);
					if (not turtle.drop()) then
						error("Aborting: Can't unload inventory.");
					end
				end				
			end
			move.face(directions.forward);
		end
		
		-- Movement
		move.calcReturnDist = function() return math.abs(position.current.x) + math.abs(position.current.y) + math.abs(position.current.z) + 4; end
		move.face = function(direction)
			if (direction == directions.up or direction == directions.down or direction == position.current.d) then return; end
			if (direction == (position.current.d + 270) % 360) then 
				turtle.turnLeft();
				position.current.d = direction;
			else
				while (direction ~= position.current.d) do
					turtle.turnRight();
					position.current.d = (position.current.d + 90) % 360;
				end
			end
		end
		move.dig = function(direction)
			if (turtle.detectUp() and (not turtle.digUp()) and direction == directions.up) then return false; end
			if (turtle.detectDown() and (not turtle.digDown()) and direction == directions.down) then return false; end
			if (turtle.detect() and (not turtle.dig()) and direction ~= directions.up and direction ~= directions.down) then return false; end
			return true;
		end
		move.direction = function(direction)
			move.face(direction);
			if (not move.dig(direction)) then return false; end
			fuel.refuel();
						
			local method = turtle.forward;
			if (direction == directions.up) then method = turtle.up end
			if (direction == directions.down) then  method = turtle.down end
			
			while (not method()) do
				sleep(0.01);
				if (not move.dig(direction)) then return false; end
			end

			if (direction == directions.up) then position.current.z = position.current.z + 1; 
			elseif (direction == directions.down) then position.current.z = position.current.z - 1; 
			elseif (direction == directions.front) then position.current.y = position.current.y + 1; 
			elseif (direction == directions.back) then position.current.y = position.current.y - 1; 
			elseif (direction == directions.left) then position.current.x = position.current.x - 1; 
			elseif (direction == directions.right) then position.current.x = position.current.x + 1; end
			return true;
		end
		move.to = function(x, y, z)
			while (position.current.z < z) do if (not move.direction(directions.up)) then return false; end end
			while (position.current.z > z) do if (not move.direction(directions.down)) then return false; end end
			while (position.current.x < x) do if (not move.direction(directions.right)) then return false; end end
			while (position.current.x > x) do if (not move.direction(directions.left)) then return false; end end
			while (position.current.y < y) do if (not move.direction(directions.forward)) then return false; end end
			while (position.current.y > y) do if (not move.direction(directions.backward)) then return false; end end
			return true;
		end
		move.home = function(callback)
			position.mark();
			move.to(0, 0, 0);
			callback();
			move.face(directions.forward);
			move.to(position.marker.x, position.marker.y, position.marker.z);
		end
		move.finish = function()
			move.to(0, 0, 0);
			move.face(directions.backward);
			inventory.unload();
			turtle.select(1);
			turtle.drop();
		end
		move.excavate = function(x, y, z)
			position.reset();
			fuel.initialize();
			if (fuel.calcRemainingFuel() < 4) then
				error("Aborting: Insufficient fuel.");
			end
			
			local row = 0;
			local rowStep = y / math.abs(y);
			local rowMax = math.max(0, y);
			local rowMin = math.min(0, y);
			
			local column = 0;
			local columnStep = x / math.abs(x);
			local columnMax = math.max(0, x);
			local columnMin = math.min(0, x);
			
			local layer = 0;
			local layerStart = z / math.abs(z);
			local layerStep = layerStart * 3;
			local layerMax = math.max(0, z);
			local layerMin = math.min(0, z);
			
			for layer = layerStart, z, layerStep do
				move.face(directions.forward);
				if (not move.to(position.current.x, position.current.y, layer)) then
					print("Returning: Reached unbreakable blocks");
					move.finish();
					return;
				end
				
				while (row >= rowMin and row <= rowMax) do
					while (column >= columnMin and column <= columnMax) do
						
						if (fuel.needsRefuel()) then
							print("Returning for refuel...");
							move.home(function() 
								print("Waiting for more fuel in slot 1.");
								turtle.refuel();
								while (not turtle.refuel(1)) do
									sleep(3);
									turtle.select(1);
								end
								fuel.initialize();
								print("Continuing");
							end);
						end
						
						if (inventory.needsUnload()) then
							print("Returning for unload...");
							move.home(function() 
								inventory.unload();
								print("Continuing");
							end);
						end
						
						if (not move.to(column, row, layer)) then
							print("Returning: Reached unbreakable blocks");
							return move.finish();
						end
						
						column = column + columnStep;
					end
					if (column > columnMax) then column = columnMax; end
					if (column < columnMin) then column = columnMin; end
					columnStep = -columnStep;
					row = row + rowStep;
				end
				if (row > rowMax) then row = rowMax; end
				if (row < rowMin) then row = rowMin; end
				rowStep = -rowStep;				
			end
			
			print("Returning: Mission complete");
			move.finish();
		end
	
		excavator.start = function(x, y, z)
			move.excavate(x, y, z);
		end
	end)();	
end
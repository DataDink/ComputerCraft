if (filler == nil) then
	filler = {};
	
	(function() 
	
		local inventory = {};
		inventory.selectItem = function() 
			for i = 2, 16 do
				if (turtle.getItemCount(i) > 0) then
					turtle.select(i);
					return true;
				end
			end
			return false;
		end
		inventory.placeItem = function(placeDelegate) 
			if (not inventory.selectItem()) then
				print("Awaiting Inventory Refill");
				while (not inventory.selectItem()) do
					sleep(5);
				end
				print("Resuming in 15 seconds");
				sleep(15);
			end
			placeDelegate();
		end
		
		local fuel = {};
		fuel.manage = function()
			if (turtle.getFuelLevel() > 0) then return true; end
			turtle.select(1);
			if (not turtle.refuel(1)) then
				print("Awaiting Refuel");
				while (not turtle.refuel(1)) do
					sleep(5);
					turtle.select(1);
				end
				print("Resuming");
			end
		end
		
		local movement = {};
		movement.fillRow = function(placeDelegate)
			repeat
				placeDelegate();
				fuel.manage();
			until (not turtle.back());
		end
		movement.direction = true;
		movement.nextRow = function()
			local turn = turtle.turnLeft;
			if (movement.direction) then 
				turn = turtle.turnRight;
			end
			movement.direction = not movement.direction;
			turn();
			if (turtle.back()) then
				turn();
				return true;
			end
			return false;
		end
		movement.fill = function(levelDelegate, placeDelegate)
			repeat
				repeat
					movement.fillRow(placeDelegate);
					fuel.manage();
				until (not movement.nextRow());
				fuel.manage();
			until (not levelDelegate());
		end
		
		filler.fillUp = function()
			movement.fill(turtle.up, turtle.placeDown);
		end
		
		filler.fillDown = function()
			movement.fill(turtle.down, turtle.placeUp);
		end
		
	end)();
end
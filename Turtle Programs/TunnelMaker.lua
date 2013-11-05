local clear = function()
  print(shell);
  print(term);
  shell.run('clear');
  print('==== Tunnel Maker ====');
  print();
end

local slots = {};

local init = function()
	slots = {};
	for i = 2, 16 do
		if (turtle.getItemCount(i) > 0) then
			table.insert(slot, i);
		end
	end
end

local select = function()
  while (true) do
    for _, index in ipairs(slots) do
      if (turtle.getItemCount(index) > 1) then
        turtle.select(index);
		return;
		end
	end

    clear();    
    print('Please add more inventory');
    sleep(5);
  end
end

local refuel = function(required)
  if (turtle.getFuelLevel() > required) then return; end
  
  while (turtle.getFuelLevel() < required) do
    while (turtle.getItemCount(1) == 0) do
      clear();
      print('Please add more fuel');
      sleep(5);
    end
    turtle.select(1);
    turtle.refuel(1);
  end
end

local place = function(compare, dig, place)
  select();
  if (compare()) then return; end
  dig();
  place();
end

local placeUp = function()
  place(turtle.compareUp, turtle.digUp, turtle.placeUp);
end

local placeDown = function()
  place(turtle.compareDown, turtle.digDown, turtle.placeDown);
end

local placeForward = function()
  place(turtle.compare, turtle.dig, turtle.place);
end

local dig = function(detect, dig)
  while (detect()) do dig(); end
end

local digUp = function()
  dig(turtle.detectUp, turtle.digUp);
end

local digDown = function()
  dig(turtle.detectDown, turtle.digDown);
end

local digForward = function()
  dig(turtle.detect, turtle.dig);
end

local move = function(movement)
  refuel(1);
  while (not movement()) do sleep(1); end
end

local moveUp = function() 
  digUp();
  move(turtle.up); 
end

local moveDown = function() 
  digDown();
  move(turtle.down); 
end

local moveForward = function() 
  digForward();
  move(turtle.forward); 
end

local section = function()
  refuel(10)
  digUp();
  placeDown();
  turtle.turnRight();
  moveForward();
  placeDown();
  placeForward();
  moveUp();
  placeForward();
  moveUp();
  placeForward();
  placeUp();
  turtle.turnLeft();
  turtle.turnLeft();
  moveForward();
  placeUp();
  moveForward();
  placeUp();
  placeForward();
  moveDown();
  placeForward();
  moveDown();
  placeForward();
  placeDown();
  turtle.turnRight();
  turtle.turnRight();
  moveForward();
  turtle.turnLeft();
  moveForward();
end

local tunnel = function(distance)
  for i = 1, distance do
    section();
    moveForward();
  end
end

local cornerFrame = function(place, dig)
  turtle.turnRight();
  for side = 1, 4 do
    moveForward();
    place();
    dig();
    turtle.turnLeft();
    moveForward();
    place();
    dig();
  end
  turtle.turnLeft();
end
  
local corner = function()
  cornerFrame(placeDown, digUp);
  moveUp(); moveUp(); 
  cornerFrame(placeUp, digDown);
  moveForward();
  placeUp();
  moveDown();
  moveDown();
  placeDown(); 
end

while (true) do
  clear();
  print('5. Tunnel Forward');
  print('4. Turn Left');
  print('6. Turn Right');
  print('8. Tunnel Up');
  print('2. Tunnel Down');
  
  local _, char = os.pullEvent('char');
  init();
  if (char == '4') then
    clear();
    print('Building Corner');
    corner();
    turtle.turnLeft();
    moveForward(); moveForward();
  elseif (char == '6') then
    clear();
    print('Building Corner');
    corner();
    turtle.turnRight();
    moveForward(); moveForward();
  else
    clear();
    print('How far? ');
    local distance = read();
    if (distance == nil) then distance = '0'; end
    distance = tonumber(distance);
    
    clear();
    print('Building Tunnel');
    for d = 1, distance do
       if (char == '8') then moveUp(); end
       if (char == '2') then moveDown(); end
       section();   
    end    
  end
end

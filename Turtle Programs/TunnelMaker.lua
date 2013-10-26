local clear = function()
  shell.run('clear');
  print('==== Tunnel Maker ====');
  print();
end

local select = function(compare)
  while (true) do
    for i = 2, 16 do
      if (turtle.getItemCount(i) > 0) then
        turtle.select(i);
        if (compare == nil or not compare()) then
          return;
        end
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
  select(compare);
  dig();
  place();
end

local placeUp = function()
  place(turtle.compareUp, turtle.digUp, turtle.placeUp);
end

local placeDown = function()
  place(turtle.compareDown, turtle.digDown, turtle.placeDown);
end

local placeFront = function()
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

local digFront = function()
  dig(turtle.detect, turtle.dig);
end

local move = function(move)
  refuel(1);
  while (not move()) do sleep(1); end
end

local moveUp = function() 
  digUp();
  move(turtle.up); 
end

local moveDown = function() 
  digDown();
  move(turtle.down); 
end

local moveFront = function() 
  digFront();
  move(turtle.forward); 
end

local section = function()
  refuel(10)
  digUp();
  placeDown();
  turtle.turnRight();
  moveFront();
  placeDown();
  placeFront();
  moveUp();
  placeFront();
  moveUp();
  placeFront();
  placeUp();
  turtle.turnLeft();
  turtle.turnLeft();
  moveFront();
  placeUp();
  moveFront();
  placeUp();
  placeFront();
  moveDown();
  placeFront();
  moveDown();
  placeFront();
  placeDown();
  turtle.turnRight();
  turtle.turnRight();
  moveFront();
  turtle.turnLeft();
  moveFront();
end

local tunnel = function(distance)
  for i = 1, distance do
    section();
    moveFront();
  end
end

local cornerFrame = function(place, dig)
  turtle.turnRight();
  for side = 1, 4 do
    moveFront();
    place();
    dig();
    turtle.turnLeft();
    moveFront();
    place();
    dig();
  end
  turtle.turnLeft();
end
  
local corner = function()
  cornerFrame(placeDown, digUp);
  moveUp(); moveUp(); 
  cornerFrame(placeUp, digDown);
  moveFront();
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
  if (char == '4') then
    clear();
    print('Building Corner');
    corner();
    turtle.turnLeft();
    moveFront(); moveFront();
  elseif (char == '6') then
    clear();
    print('Building Corner');
    corner();
    turtle.turnRight();
    moveFront(); moveFront();
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

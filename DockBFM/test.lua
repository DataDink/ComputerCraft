local monitor = peripheral.wrap("top");
term.redirect(monitor);
term.setCursorPos(0, 0);
term.write("Boat House Monitor - test");
term.setCursorPos(10, 5);
term.write("I'm on a muther fucking boat!");
term.setCursorPos(0,10);
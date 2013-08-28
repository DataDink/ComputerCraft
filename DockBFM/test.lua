local monitor = peripheral.wrap("top");
term.redirect(monitor);
term.setCursorPos(1, 1);
term.write("Boat House Monitor");
term.setCursorPos(15, 5);
term.write("I'm on a muther fucking boat!");
term.restore();
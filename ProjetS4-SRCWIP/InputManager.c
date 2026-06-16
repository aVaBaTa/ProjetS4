//this is file is used to manage the input of the user. For now, it only reads keyboard inputs.

#include "InputManager.h"
#include <stdio.h>
#include <conio.h> // Required for _kbhit and _getch

int InputManager() {

        if (_kbhit()) { // Checks if a key has been pressed
            char ch = _getch(); 

            // Look at the content of InputManager.h for more detail. I use ASCI codes of arrow keys.
            if (ch == KEY_ESC) {
                return 0;
            }
            else if (ch == KEY_UP)
            {
                return 1;
            }
            else if (ch == KEY_DOWN)
            {
                return 2;
            }
            else if (ch == KEY_LEFT)
            {
                return 3;
            }
            else if (ch == KEY_RIGHT)
            {
                return 4;
            }
			else if (ch == KEY_SPACE)
			{
				return 5;
			}
        }
    return 0;
}

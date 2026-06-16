#include <stdio.h>
#include "InputManager.h"
#include "InitialWindow.h"

char pokemon_names[5][12] = {
	"Bulbasaur",
	"Charmander",
	"Squirtle",
	"Pikachu",
	"Eevee"
};
char animation[4] = {
	'/',
	'-',
	'\\',
	'|'
};

int current_pokemon_index = 0;
int animation_index = 0;
int intial_screen_index = 0;
int result = 0;

int InitialWindow()
{

	printf("Choose your initial pokemon: \n \t < %s > \n", pokemon_names[current_pokemon_index]);

	while (1)
	{
		result = InputManager();
		system("cls"); // Clears the console

		if (result == 3) //left input
		{
			if (current_pokemon_index == 0)
			{
				current_pokemon_index = 5;
			}
			current_pokemon_index--;
		}
		if (result == 4) //right input
		{
			if (current_pokemon_index == 4)
			{
				current_pokemon_index = -1;
			}
			current_pokemon_index++;
		}
		else if (result == 5) //space input
		{
			printf("\nStarting the game with %s...\n", pokemon_names[current_pokemon_index]);
			return current_pokemon_index;
		}

		if (animation_index == 3)
		{
			animation_index = -1;
		}

		//the animation only changes one time per 15 cycles of the loop, so it doesn't go too fast.
		intial_screen_index++;
		if (intial_screen_index == 15)
		{
			intial_screen_index = 0;
			animation_index++;
		}
		printf("%c\n", animation[animation_index]);

		printf("Choose your initial pokemon: \n \t < %s > \n", pokemon_names[current_pokemon_index]);
	}
}
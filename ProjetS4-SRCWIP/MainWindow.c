#include "MainWindow.h"

int currentSelection = 0;

void MainWindow(Pokemon* yourpokemon, Pokemon* oponentpokemon) {
    if (oponentpokemon->Speed > yourpokemon->Speed)
    {
        system("cls"); // Efface la console
        printf("Your pokemon: %s \t\t Opponent's pokemon: %s\n", yourpokemon->name, oponentpokemon->name);
        printf("PV: %d / %d \t\t\t\t PV: %d / %d\n", yourpokemon->CurrentPV, yourpokemon->MaxPV, oponentpokemon->CurrentPV, oponentpokemon->MaxPV);
		Fight(oponentpokemon, yourpokemon);
		if (yourpokemon->CurrentPV == 0)
		{
            int selected_pokemon_index = InitialWindow();
            Pokemon myPokemon = PokemonManager(selected_pokemon_index);
            Pokemon theirPokemon = PokemonManager(rand() % 5);
            MainWindow(&myPokemon, &theirPokemon);
		}
    }
    while (1)
    {
        system("cls"); // Efface la console
        printf("Your pokemon: %s \t\t Opponent's pokemon: %s\n", yourpokemon->name, oponentpokemon->name);
        printf("PV: %d / %d \t\t\t\t PV: %d / %d\n", yourpokemon->CurrentPV, yourpokemon->MaxPV, oponentpokemon->CurrentPV, oponentpokemon->MaxPV);

        int result = InputManager();

        if (result == 3) //left input
        {
            if (currentSelection == 0)
            {
                currentSelection = 4;
            }
            currentSelection--;
        }
        else if (result == 4) //right input
        {
            if (currentSelection == 3)
            {
                currentSelection = -1;
            }
            currentSelection++;
        }
        else if (result == 1) //up input
        {
            if (currentSelection == 0 || currentSelection == 1)
            {
                currentSelection += 2;
            }
            else
            {
                currentSelection -= 2;
            }
        }
        else if (result == 2) //down input
        {
            if (currentSelection == 2 || currentSelection == 3)
            {
                currentSelection -= 2;
            }
            else
            {
                currentSelection += 2;
            }
        }
        else if (result == 5) //space input
        {
            if (currentSelection == 0)
            {
                Fight(yourpokemon, oponentpokemon);
                if (oponentpokemon->CurrentPV == 0)
                {
                    break;
                }
            }
            else if (currentSelection == 1)
            {

            }
            else if (currentSelection == 2)
            {
            }
            else if (currentSelection == 3)
            {

            }
			Fight(oponentpokemon, yourpokemon);
            if (yourpokemon->CurrentPV == 0)
            {
                break;
            }
        }
        if (currentSelection == 0)
        {
            printf("\n \n What will you do? \n \t < Fight > \t   Pkmn   \n \t   Item   \t   Run   \n");
        }
        else if (currentSelection == 1)
        {
            printf("\n \n What will you do? \n \t   Fight   \t < Pkmn > \n \t   Item   \t   Run   \n");
        }
        else if (currentSelection == 2)
        {
            printf("\n \n What will you do? \n \t   Fight   \t   Pkmn   \n \t < Item > \t   Run   \n");
        }
        else if (currentSelection == 3)
        {
            printf("\n \n What will you do? \n \t   Fight   \t   Pkmn   \n \t   Item   \t < Run > \n");
        }
    }
    if (yourpokemon->CurrentPV != 0)
    {
        currentSelection = 0;
        while (1)
        {
            system("cls"); // Efface la console
            if (currentSelection == 0)
            {
                printf("\n \n Do you want to continue ? \n \t <Yes> \t  No \n");
            }
			else if (currentSelection == 1)
			{
				printf("\n \n Do you want to continue ? \n \t  Yes  \t <No> \n");
			}
            int result = InputManager();
            if (result == 3 && currentSelection == 1) //left input
            {
                currentSelection = 0;
            }
            else if (result == 4 && currentSelection == 0) //right input
            {
                currentSelection = 1;
            }
            else if (result == 5) //space input
            {
                break;
            }
        }
        if (currentSelection == 0)
        {
            Pokemon theirPokemon = PokemonManager(rand() % 5);
            MainWindow(yourpokemon, &theirPokemon);
        }
        else if (currentSelection == 1)
        {
            int selected_pokemon_index = InitialWindow();
            Pokemon myPokemon = PokemonManager(selected_pokemon_index);
            Pokemon theirPokemon = PokemonManager(rand() % 5);

            //you have your selected pokemon, the opponent has a random pokemon
            MainWindow(&myPokemon, &theirPokemon);
        }
    }
    else
    {
        int selected_pokemon_index = InitialWindow();
        Pokemon myPokemon = PokemonManager(selected_pokemon_index);
        Pokemon theirPokemon = PokemonManager(rand() % 5);
		MainWindow(&myPokemon, &theirPokemon);
    }
}

void Fight(Pokemon* attackingpokemon, Pokemon* defendingpokemon)
{
	int randomattackbonus = rand() %2;
    printf("\n \n %s used %s !\n", attackingpokemon->name, attackingpokemon->attack);
    Sleep(2000); // Attend 2 secondes pour simuler l'animation

    if ((attackingpokemon->Type == GRASS && defendingpokemon->Type == WATER) ||
        (attackingpokemon->Type == FIRE && defendingpokemon->Type == GRASS) ||
        (attackingpokemon->Type == WATER && defendingpokemon->Type == FIRE) ||
        (attackingpokemon->Type == ELECTRIC && defendingpokemon->Type == WATER))
    {
        printf("It's super effective!\n");
        Sleep(2000);
        defendingpokemon->CurrentPV -= (attackingpokemon->Attack + randomattackbonus) * 2;
    }
    else if ((attackingpokemon->Type == GRASS && defendingpokemon->Type == FIRE) ||
        (attackingpokemon->Type == FIRE && defendingpokemon->Type == WATER) ||
        (attackingpokemon->Type == WATER && defendingpokemon->Type == GRASS) ||
        (attackingpokemon->Type == ELECTRIC && defendingpokemon->Type == GRASS))
    {
        printf("It's not very effective...\n");
        Sleep(2000);
        defendingpokemon->CurrentPV -= (attackingpokemon->Attack + randomattackbonus) / 2;
    }
    else
    {
        defendingpokemon->CurrentPV -= attackingpokemon->Attack;
    }

    if (defendingpokemon->CurrentPV <= 0)
    {
        defendingpokemon->CurrentPV = 0;
        printf("%s fainted!\n", defendingpokemon->name);
        Sleep(2000);
    }
    else
    {
        printf("%s has %d PV left.\n", defendingpokemon->name, defendingpokemon->CurrentPV);
        Sleep(2000);
    }
}

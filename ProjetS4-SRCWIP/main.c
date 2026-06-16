// main,c : Ce fichier contient la fonction 'main'. L'exécution du programme commence et se termine à cet endroit.

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include"InputManager.h"
#include"InitialWindow.h"
#include "PokemonManager.h"
#include "MainWindow.h"



int main()
{
srand((unsigned int)time(NULL));
int selected_pokemon_index = InitialWindow();
Pokemon myPokemon = PokemonManager(selected_pokemon_index);
Pokemon theirPokemon = PokemonManager(rand() % 5);

//you have your selected pokemon, the opponent has a random pokemon
MainWindow(&myPokemon, &theirPokemon);

}

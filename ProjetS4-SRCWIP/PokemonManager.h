#ifndef POKEMON_MANAGER_H
#define POKEMON_MANAGER_H

#define GRASS    1
#define FIRE     2
#define WATER    3
#define ELECTRIC 4
#define NORMAL   5

typedef struct {
	char name[12];
	char attack[15];
	int CurrentPV;
	int MaxPV;
	int Attack;
	int Speed;
	int Type;
} Pokemon;

Pokemon PokemonManager(int selected_pokemon_index);

#endif
#pragma once

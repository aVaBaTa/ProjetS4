#include "PokemonManager.h"  
#include <string.h> // Include for strcpy  

Pokemon PokemonManager(int selected_pokemon_index)  
{  
Pokemon pokemon;  
if (selected_pokemon_index == 0)  
{  
	//Bulbasaur  
	//Grass pokemon with good attack and good PV but low speed.  
	strcpy_s(pokemon.name, sizeof(pokemon.name), "Bulbasaur");  
	strcpy_s(pokemon.attack, sizeof(pokemon.attack), "Vine Whip");  
	pokemon.MaxPV = 10;
	pokemon.Attack = 5;  
	pokemon.Speed = 45;  
	pokemon.Type = GRASS;  
}  
else if (selected_pokemon_index == 1)  
{  
	//Charmander  
	//Fire pokemon with good attack and good speed but low PV.  
	strcpy_s(pokemon.name, sizeof(pokemon.name), "Charmander");  
	strcpy_s(pokemon.attack, sizeof(pokemon.attack), "Ember");  
	pokemon.MaxPV = 10;  
	pokemon.Attack = 5;  
	pokemon.Speed = 65;  
	pokemon.Type = FIRE;  
}  
else if (selected_pokemon_index == 2)  
{  
	//Squirtle  
	//Water pokemon with good PV and good speed but low attack.  
	strcpy_s(pokemon.name, sizeof(pokemon.name), "Squirtle");  
	strcpy_s(pokemon.attack, sizeof(pokemon.attack), "Water Gun");  
	pokemon.MaxPV = 10;  
	pokemon.Attack = 3;  
	pokemon.Speed = 50;  
	pokemon.Type = WATER;  
}  
else if (selected_pokemon_index == 3)  
{  
	//Pikachu  
	//Electric pokemon with good attack and good speed but low PV.  
	strcpy_s(pokemon.name, sizeof(pokemon.name), "Pikachu");  
	strcpy_s(pokemon.attack, sizeof(pokemon.attack), "Thunder Shock");  
	pokemon.MaxPV = 10;  
	pokemon.Attack = 5;  
	pokemon.Speed = 90;  
	pokemon.Type = ELECTRIC;  
}  
else if (selected_pokemon_index == 4)  
{  
	//Eevee  
	//Normal pokemon with balanced stats.  
	strcpy_s(pokemon.name, sizeof(pokemon.name), "Eevee");  
	strcpy_s(pokemon.attack, sizeof(pokemon.attack), "Tackle");  
	pokemon.MaxPV = 10;  
	pokemon.Attack = 4;  
	pokemon.Speed = 55;  
	pokemon.Type = NORMAL;  
}  
pokemon.CurrentPV = pokemon.MaxPV; // Set current PV to max PV at the start of the game
return pokemon;  
}
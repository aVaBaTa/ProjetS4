#ifndef MAIN_WINDOW_H
#define MAIN_WINDOW_H

#include <conio.h> // Required for clearing the console
#include <stdio.h>
#include "PokemonManager.h"
#include <windows.h>
#include "InputManager.h"
#include "InitialWindow.h"
void MainWindow(Pokemon* yourpokemon, Pokemon* oponentpokemon);
void Fight(Pokemon* yourpokemon, Pokemon* oponentpokemon);

#endif // !MAIN_WINDOW_H
#pragma once

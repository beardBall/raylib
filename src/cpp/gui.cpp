#pragma once
#include <string> 
#include "raylib.h"
#include "gui.hpp"

using namespace  GAME;
using namespace std;


GUI::GUI(){

    visible = true;
}

void draw(){

    // DrawText(GetFPS(), );
    // DrawText("FPS: " + std::to_string(GetFPS()).c_str(), 100, 100, 10, BLUE);
    DrawText("FPS: ", 100, 100, 10, BLUE);
}


void update(float deltaTime){


}


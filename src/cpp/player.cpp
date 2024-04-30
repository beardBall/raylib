

#include "player.hpp"

using namespace Game;

Player::Player(){

}

void Player::draw(){
    // Draw player bar
    DrawRectangle(Player::position.x - Player::size.x / 2, position.y - size.y / 2, size.x, size.y, color);
    DrawRectangle(Player::position.x - Player::size.x / 2, position.y - size.y / 2, size.x, size.y, color);
    DrawCircle(Player::position.x, Player::position.y, Player::size.y/2, PURPLE); // Draw a color-filled circle

    // Draw player lives
    for (int i = 0; i < Player::life; i++)
        DrawRectangle(20 + 40 * i, GetScreenHeight() - 30, 35, 10, LIGHTGRAY);
}








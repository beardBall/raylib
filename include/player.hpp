

#include "raylib.h"
namespace Game{

    class Player
    {

    public:

        Vector2 position;
        Vector2 size;
        int life;
        Color color;

        Player();
        void draw();
        void update(float deltaTime);

    private:


    };
}
/*******************************************************************************************
*
*   raylib - classic game: arkanoid
*
*   Sample game developed by Marc Palau and Ramon Santamaria
*
*   This game has been created using raylib v1.3 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*   Copyright (c) 2015 Ramon Santamaria (@raysan5)
*
********************************************************************************************/
typedef enum
{
    false,
    true
}
bool;

#include "raylib.h"
#ifdef __ANDROID__
#include "androidsensor.h"
#endif


#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
// #include <stdbool.h>

#if defined(PLATFORM_WEB)
    #include <emscripten/emscripten.h>
#endif

//----------------------------------------------------------------------------------
// Some Defines
//----------------------------------------------------------------------------------
#define PLAYER_MAX_LIFE         2
#define LINES_OF_BRICKS         5
#define BRICKS_PER_LINE        30

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
typedef struct Player {
    Vector2 position;
    Vector2 size;
    int life;
    Color color;
} Player;

typedef struct Ball {
    Vector2 position;
    Vector2 speed;
    int radius;
    bool active;
} Ball;

typedef struct Brick {
    Vector2 position;
    bool active;
} Brick;

Sound fxOn;


//------------------------------------------------------------------------------------
// Global Variables Declaration
//------------------------------------------------------------------------------------
static const int screenWidth = 800;
static const int screenHeight = 450;

static bool gameOver = false;
static bool pause = false;

static Player player = { 0 };
static Ball ball = { 0 };
static Brick brick[LINES_OF_BRICKS][BRICKS_PER_LINE] = { 0 };
static Vector2 brickSize = { 0 };

//------------------------------------------------------------------------------------
// Module Functions Declaration (local)
//------------------------------------------------------------------------------------
static void InitGame(void);         // Initialize game
static void UpdateGame(void);       // Update game (one frame)
static void UpdateControls(void);       // Update game (one frame)
static void DrawGame(void);         // Draw game (one frame)
static void UnloadGame(void);       // Unload game
static void UpdateDrawFrame(void);  // Update and Draw (one frame)

int currentGesture;
int lastGesture;

#ifdef __ANDROID__
AndroidSensor angle;
#endif

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
int main(void)
{
    // Initialization (Note windowTitle is unused on Android)
    //---------------------------------------------------------
    InitWindow(screenWidth, screenHeight, "classic game: arkanoid");

    InitGame();

#if defined(PLATFORM_WEB)
    emscripten_set_main_loop(UpdateDrawFrame, 60, 1);
#else
    SetTargetFPS(60);
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!WindowShouldClose())    // Detect window close button or ESC key
    {
        // Update and Draw
        //----------------------------------------------------------------------------------
        UpdateDrawFrame();
        //----------------------------------------------------------------------------------
    }
#endif
    // De-Initialization
    //--------------------------------------------------------------------------------------
    UnloadGame();         // Unload loaded data (textures, sounds, models...)

    UnloadSound(fxOn); // Unload sound data

#ifdef __ANDROID__
    CloseSensor(&angle);
#endif

    CloseAudioDevice(); // Close audio device

    CloseWindow();        // Close window and OpenGL context
    //--------------------------------------------------------------------------------------

    return 0;
}

//------------------------------------------------------------------------------------
// Module Functions Definitions (local)
//------------------------------------------------------------------------------------

// Initialize game variables
void InitGame(void)
{

    InitAudioDevice(); // Initialize audio device
    fxOn = LoadSound("assets/audio/complete.ogg"); // Load WAV audio file
    PlaySound(fxOn);
    // Sound fxOgg = LoadSound("resources/target.ogg");
#ifdef _ANDROID_
    angle = InitAndroidSensor(GAMEVECTOR, 10000);
#endif
    brickSize = (Vector2){ GetScreenWidth()/BRICKS_PER_LINE, 40 };

    // Initialize player
    player.position = (Vector2){ screenWidth/2, screenHeight*7/8 };
    player.size = (Vector2){ screenWidth/5, 20 };
    player.life = PLAYER_MAX_LIFE;
    player.color = BLUE;

    // Initialize ball
    ball.position = (Vector2){ screenWidth/2, screenHeight*7/8 - 30 };
    ball.speed = (Vector2){ 0, 0 };
    ball.radius = 7;
    ball.active = false;
    // Playsound(fxOn);
    // Initialize bricks
    int initialDownPosition = 50;

    for (int i = 0; i < LINES_OF_BRICKS; i++)
    {
        for (int j = 0; j < BRICKS_PER_LINE; j++)
        {
            brick[i][j].position = (Vector2){ j*brickSize.x + brickSize.x/2, i*brickSize.y + initialDownPosition };
            brick[i][j].active = true;
        }
    }

    int currentGesture = GESTURE_NONE;
    int lastGesture = GESTURE_NONE;
}

// Update game (one frame)
void UpdateGame(void)
{
    if (!gameOver)
    {
        if (IsKeyPressed('P')) pause = !pause;

        if (!pause)
        {
            // Player movement logic
            UpdateControls();
            if (IsKeyDown(KEY_LEFT))
                player.position.x -= 5;
            if (currentGesture == GESTURE_SWIPE_LEFT)
                player.position.x -= 5;
            if (currentGesture == GESTURE_SWIPE_RIGHT)
                player.position.x += 5;

            if ((player.position.x - player.size.x/2) <= 0) player.position.x = player.size.x/2;
            if (IsKeyDown(KEY_RIGHT)) player.position.x += 5;
            if ((player.position.x + player.size.x/2) >= screenWidth) player.position.x = screenWidth - player.size.x/2;
            if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) 
            {
                player.color = RED;
            }
            // Ball launching logic
            if (!ball.active)
            {
                if ( IsKeyPressed(KEY_SPACE) || currentGesture == GESTURE_TAP)
                {
                    ball.active = true;
                    ball.speed = (Vector2){ 0, -5 };
                }
            }

            // Ball movement logic
            if (ball.active)
            {
                ball.position.x += ball.speed.x;
                ball.position.y += ball.speed.y;
            }
            else
            {
                ball.position = (Vector2){ player.position.x, screenHeight*7/8 - 30 };
            }

            // Collision logic: ball vs walls
            if (((ball.position.x + ball.radius) >= screenWidth) || ((ball.position.x - ball.radius) <= 0)) ball.speed.x *= -1;
            if ((ball.position.y - ball.radius) <= 0) ball.speed.y *= -1;
            if ((ball.position.y + ball.radius) >= screenHeight)
            {
                ball.speed = (Vector2){ 0, 0 };
                ball.active = false;

                player.life--;
            }

            // Collision logic: ball vs player
            if (CheckCollisionCircleRec(ball.position, ball.radius,
                (Rectangle){ player.position.x - player.size.x/2, player.position.y - player.size.y/2, player.size.x, player.size.y}))
            {
                if (ball.speed.y > 0)
                {
                    ball.speed.y *= -1;
                    ball.speed.x = (ball.position.x - player.position.x)/(player.size.x/2)*5;
                    PlaySound(fxOn);
                }
            }

            // Collision logic: ball vs bricks
            for (int i = 0; i < LINES_OF_BRICKS; i++)
            {
                for (int j = 0; j < BRICKS_PER_LINE; j++)
                {
                    if (brick[i][j].active)
                    {
                        // Hit below
                        if (((ball.position.y - ball.radius) <= (brick[i][j].position.y + brickSize.y/2)) &&
                            ((ball.position.y - ball.radius) > (brick[i][j].position.y + brickSize.y/2 + ball.speed.y)) &&
                            ((fabs(ball.position.x - brick[i][j].position.x)) < (brickSize.x/2 + ball.radius*2/3)) && (ball.speed.y < 0))
                        {
                            brick[i][j].active = false;
                            ball.speed.y *= -1;
                        }
                        // Hit above
                        else if (((ball.position.y + ball.radius) >= (brick[i][j].position.y - brickSize.y/2)) &&
                                ((ball.position.y + ball.radius) < (brick[i][j].position.y - brickSize.y/2 + ball.speed.y)) &&
                                ((fabs(ball.position.x - brick[i][j].position.x)) < (brickSize.x/2 + ball.radius*2/3)) && (ball.speed.y > 0))
                        {
                            brick[i][j].active = false;
                            ball.speed.y *= -1;
                        }
                        // Hit left
                        else if (((ball.position.x + ball.radius) >= (brick[i][j].position.x - brickSize.x/2)) &&
                                ((ball.position.x + ball.radius) < (brick[i][j].position.x - brickSize.x/2 + ball.speed.x)) &&
                                ((fabs(ball.position.y - brick[i][j].position.y)) < (brickSize.y/2 + ball.radius*2/3)) && (ball.speed.x > 0))
                        {
                            brick[i][j].active = false;
                            ball.speed.x *= -1;
                        }
                        // Hit right
                        else if (((ball.position.x - ball.radius) <= (brick[i][j].position.x + brickSize.x/2)) &&
                                ((ball.position.x - ball.radius) > (brick[i][j].position.x + brickSize.x/2 + ball.speed.x)) &&
                                ((fabs(ball.position.y - brick[i][j].position.y)) < (brickSize.y/2 + ball.radius*2/3)) && (ball.speed.x < 0))
                        {
                            brick[i][j].active = false;
                            ball.speed.x *= -1;
                        }
                    }
                }
            }

            // Game over logic
            if (player.life <= 0) gameOver = true;
            else
            {
                gameOver = true;

                for (int i = 0; i < LINES_OF_BRICKS; i++)
                {
                    for (int j = 0; j < BRICKS_PER_LINE; j++)
                    {
                        if (brick[i][j].active) gameOver = false;
                    }
                }
            }
        }
    }
    else
    {
        if (IsKeyPressed(KEY_ENTER) || currentGesture == GESTURE_TAP)
        {
            InitGame();
            gameOver = false;
        }
    }
}

// Draw game (one frame)
void DrawGame(void)
{
    BeginDrawing();

        ClearBackground(RAYWHITE);
        

        if (!gameOver)
        {
            // Draw player bar
            DrawRectangle(player.position.x - player.size.x/2, player.position.y - player.size.y/2, player.size.x, player.size.y, player.color);

            // Draw player lives
            for (int i = 0; i < player.life; i++) DrawRectangle(20 + 40*i, screenHeight - 30, 35, 10, LIGHTGRAY);

            // Draw ball
            DrawCircleV(ball.position, ball.radius, PINK);

            // Draw bricks
            for (int i = 0; i < LINES_OF_BRICKS; i++)
            {
                for (int j = 0; j < BRICKS_PER_LINE; j++)
                {
                    if (brick[i][j].active)
                    {
                        if ((i + j) % 2 == 0) DrawRectangle(brick[i][j].position.x - brickSize.x/2, brick[i][j].position.y - brickSize.y/2, brickSize.x, brickSize.y, GRAY);
                        else DrawRectangle(brick[i][j].position.x - brickSize.x/2, brick[i][j].position.y - brickSize.y/2, brickSize.x, brickSize.y, DARKGRAY);
                    }
                }
            }

            if (pause) DrawText("GAME PAUSED", screenWidth/2 - MeasureText("GAME PAUSED", 40)/2, screenHeight/2 - 40, 40, GRAY);
        }
        else DrawText("PRESS [ENTER] TO PLAY AGAIN", GetScreenWidth()/2 - MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20)/2, GetScreenHeight()/2 - 50, 20, GRAY);

        DrawText("Tilt x", 100, 100, 10, BLUE);

#ifdef __ANDROID__
        DrawText(TextFormat("X: %.3f", angle.value.x), 100, 160, 30, RED);
        DrawText(TextFormat("Y: %.3f", angle.value.y), 300, 160, 30, RED);
        DrawText(TextFormat("Z: %.3f", angle.value.z), 500, 160, 30, RED);
#endif

        EndDrawing();
}

// Unload game variables
void UnloadGame(void)
{
    // TODO: Unload all dynamic loaded data (textures, sounds, models...)
}

// Update and Draw (one frame)
void UpdateDrawFrame(void)
{
    UpdateGame();
    DrawGame();
}


void UpdateControls(){

    lastGesture = currentGesture;
    currentGesture = GetGestureDetected();
#ifdef __ANDROID__
    UseSensor(&angle);
#endif

    if (currentGesture != lastGesture)
    {
            // Store gesture string
            switch (currentGesture)
            {
            case GESTURE_TAP:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE TAP");
                break;
            case GESTURE_DOUBLETAP:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE DOUBLETAP");
                break;
            case GESTURE_HOLD:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE HOLD");
                break;
            case GESTURE_DRAG:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE DRAG");
                break;
            case GESTURE_SWIPE_RIGHT:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE SWIPE RIGHT");
                break;
            case GESTURE_SWIPE_LEFT:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE SWIPE LEFT");
                break;
            case GESTURE_SWIPE_UP:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE SWIPE UP");
                break;
            case GESTURE_SWIPE_DOWN:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE SWIPE DOWN");
                break;
            case GESTURE_PINCH_IN:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE PINCH IN");
                break;
            case GESTURE_PINCH_OUT:
                // TextCopy(gestureStrings[gesturesCount], "GESTURE PINCH OUT");
                break;
            default:
                break;
            }
    }
}

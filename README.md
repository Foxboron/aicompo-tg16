Turn On Me
============

This is a game where you circle a sun and try to shoot down the other players.

All players have an amount of energy, which is used for both the anti-gravity engine that allows the extremely heavy ships to stay in orbit, as well as doing actions.

All players start the round with 1000 energy.

The anti-gravity engine uses 1 energy for each game tick, and as the energy goes lower your ship gets heavier, and therefore circles closer to the sun.

Turning your ship with your thrusters costs 1 energy.

Accelerating forward costs 10 energy.

Firing a normal missile costs 100 energy, firing a homing missile costs 150 energy and dropping a hovermine costs 200 energy.

If you hit another player with either a missile or a hovermine, that player loses 100 energy, and you get 100 energy.

**These values are subject to change, until we freeze them sometime before The Gathering 2016.**

We might also add more weapons, if we find some fun ideas.

---

## Keymap

 * F5: Restarts round
 * p: Pause
 * ESC: Stop game

### Keys for human player

 * Left: turn left
 * Right: turn right
 * Forward: Accelerate
 * m: Fire normal missile.
 * ,: Drop mine.
 * .: Fire homing missile.

---


## Communication Protocol

The protocol is based on JSON.

To connect to the game, open a TCP connection to where the game is running on port `54321`. When running on the same machine, just connect to localhost (127.0.0.1).

After connecting, send "NAME " followed by the name of your bot to set a name (for example: "NAME superbot\n").

When the game starts, you will start to get "stateupdate" JSON objects, that look like this:

```JSON
{
    "messagetype": "stateupdate",
    "gamestate": {
        "missiles": [
            {
                "energy": 0,
                "owner": 0,
                "rotation": 1.5125629973121255,
                "type": "NORMAL",
                "velocityX": 0.002812616921765813,
                "velocityY": 0.048244483355828163,
                "x": -0.1065170720879374,
                "y": 0.057297497784823674
            },
            {
                "energy": 4981,
                "owner": 0,
                "rotation": 1.8384380069025155,
                "type": "MINE",
                "velocityX": 0.00042820233654171418,
                "velocityY": -0.0015615237322931463,
                "x": -0.22436009460522804,
                "y": 0.81817305140153029
            },
            {
                "energy": 350,
                "owner": 0,
                "rotation": -1.1475855031033397,
                "type": "SEEKING",
                "velocityX": 0.032627412854647569,
                "velocityY": -0.03970474002645958,
                "x": -0.086567348713245326,
                "y": 0.69192650021900126
            }
        ],
        "others": [
            {
                "energy": 858,
                "id": 0,
                "rotation": 90,
                "velocityX": -0.007226001197449654,
                "velocityY": -0.026401470594673109,
                "x": -0.42907664254625305,
                "y": 0.40928029816990924
            }
        ],
        "you": {
            "energy": 918,
            "id": 1,
            "rotation": 270,
            "velocityX": 0.0076515503238599285,
            "velocityY": 0.025595966187665863,
            "x": 0.43292444925334561,
            "y": -0.41881639474014176
        }
    }
}
```

There are also two other kinds of messages:

--

`dead` - You've been killed, and cannot expect more data until next round

```JSON
{ "type": "dead" }
```   

--

`endofround` - There's only one player left (for your sake I hope it's you)

```JSON
{ "type": "endofround" }
```

### Controlling

To do something, send the appropriate command followed by `\n`, for example `RIGHT\n`.

The available commands are:

 * `ACCELERATE`: Accelerate in the direction you're currently pointing.
 * `LEFT`: Turn left.
 * `RIGHT`: Turn right.
 * `MISSILE`: Fire a normal missile in the direction you're currently pointing.
 * `SEEKING`: Fire a homing missile that tries to home in on the closest player.
 * `MINE`: Drop a "mine" that tries to hover around the sun.

---

## How to compile

On Linux, in the folder where the source is, run:
```
qmake && make
```

Alternatively, the easiest on Windows/OS X, download the Qt SDK, launch QtCreator, and open the "turnonme.pro" file in the project, and click the green and pretty play button to the left.


import QtQuick 2.2
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0
import QtQuick.Particles 2.0

Rectangle {
    id: main

    color: "black"

    height: 1200
    width: 1600

    property int scaleSize: (width < height) ? width : height

    property var playerColors: [
        "#c0ff400f", // red
        "#c0400fff", // blue
        "#c040ff0f", // green
        "#c0f0ff40"  // yellow
    ]

    signal userMove(string direction)

    Keys.onDownPressed: userMove("DOWN")
    Keys.onUpPressed: userMove("ACCELERATE")
    Keys.onRightPressed: userMove("RIGHT")
    Keys.onLeftPressed: userMove("LEFT")
    Keys.onEscapePressed: {
        GameManager.stopGame();
        startScreen.opacity = 1
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_F5) {
            GameManager.endRound();
            return true;
        } else if (event.key === Qt.Key_P) {
            GameManager.togglePause()
            pauseText.visible = !pauseText.visible
            pauseAnimation.restart()
            return true;
        } else if (event.key === Qt.Key_Period) {
            userMove("SEEKING")
        } else if (event.key === Qt.Key_Comma) {
            userMove("MINE")
        } else if (event.key === Qt.Key_M) {
            userMove("MISSILE")
        }

        return false;
    }


    ColorAnimation on color {
        id: backgroundColorAnimation
        from: "red"
        to: "black"
        duration: 5000
        running: false
    }

    Connections {
        target: GameManager
        onRoundOver: {
            backgroundColorAnimation.restart()
        }
    }

    Item {
        id: gameArea
        anchors.fill: parent


        Image {
            id: background
            anchors.fill: parent
            source: "qrc:/sprites/starfield.jpg"
            fillMode: Image.Tile
            opacity: 0.5
            //visible: false
        }

        Text {
            id: pauseText
            anchors.top: parent.top
            anchors.right: parent.right
            text: "PAUSED"
            color: "white"
            font.bold: true
            font.pointSize: 40
            opacity: 0.7
            visible: false
            z: 10


            Text {
                id: pauseOverlay
                anchors.top: parent.top
                anchors.right: parent.right
                color: "white"
                text: parent.text
                visible: opacity > 0
                font.bold: true

                ParallelAnimation {
                    id: pauseAnimation
                    NumberAnimation {
                        target: pauseOverlay
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 200
                    }
                    NumberAnimation {
                        target: pauseOverlay
                        property: "font.pointSize"
                        from: 40
                        to: 200
                        duration: 300
                    }
                }
            }
        }

        Text {
            id: roundsPlayed
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            text: "round: " + GameManager.roundsPlayed + "/" + GameManager.maxRounds
            color: "#7f000000"
            font.bold: true
            style: Text.Outline
            styleColor: "white"
            font.pointSize: 40
            z: 10
            opacity: 0.7
        }

        Image {
            id: sun
            source: "qrc:///sprites/sun.png"
            anchors.centerIn: parent
            width: main.scaleSize / 10
            height: width

            ParticleSystem {
                anchors.fill: parent
                ImageParticle {
                    source: "qrc:///sprites/star.png"
                    alphaVariation: 0.1
                    colorVariation: 0.5
                    color: "#0fffff00"
                }

                Emitter {
                    anchors.fill: parent
                    //group: "center"
                    emitRate: 1000
                    lifeSpan: 2000
                    size: 20
                    sizeVariation: 5
                    endSize: 0
                    //! [0]
                    shape: EllipseShape {fill: false}
                    velocity: TargetDirection {
                        targetX: sun.width/2
                        targetY: sun.height/2
                        proportionalMagnitude: true
                        magnitude: 0.5
                        magnitudeVariation: 0.9
                    }
                    //! [0]
                }
            }
        }

        ParticleSystem {
            id: missileParticles
            anchors.fill: parent

//            ImageParticle {
//                opacity: 0.5
//                source: "qrc:///sprites/star.png"
//                alpha: 0.1
//                alphaVariation: 0.1
//                colorVariation: 0.5
//                color: "#01ffffff"
//                groups: ["Player1"]
//            }
            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                colorVariation: 0.5
                color: playerColors[0]
                groups: ["Player1"]
            }
            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                colorVariation: 0.5
                color: playerColors[1]
                groups: ["Player2"]
            }
            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                colorVariation: 0.5
                color: playerColors[2]
                groups: ["Player3"]
            }
            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                colorVariation: 0.5
                color: playerColors[3]
                groups: ["Player4"]
            }
            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                colorVariation: 0.5
                color: "white"
                groups: ["Explosion"]
            }
        }

        Emitter {
            id: crashEmitter
            anchors.centerIn: parent
            width: 10
            height: 10
            emitRate: 1000
            lifeSpan: 500
            lifeSpanVariation: 100
            enabled: false
            velocity: AngleDirection{magnitude: 128; angleVariation: 360}
            size: 32
            sizeVariation: 16
            system: missileParticles
            group: "Explosion"

            Connections {
                target: GameManager
                onExplosion: {
                    blurAnimation.restart()
                    crashEmitter.burst(500, main.width / 2 + position.x * main.width / 2, main.height/ 2 + position.y * main.height/ 2)
                }
            }
        }

        // List of player sprites
        Repeater {
            model: GameManager.players
            delegate: PlayerSprite {
                playerId: model.modelData.id
//                x: main.width / 2 + modelData.position.x * main.width / 2 - width / 2
//                y: main.height / 2 + modelData.position.y * main.height / 2 - height / 2
                height: main.scaleSize / 20
                width: height
            }
        }

        Component {
            id: missileSpriteSpawner

            MissileSprite {
            }
        }
        Connections {
            target: GameManager
            onMissileCreated: {
                missileSpriteSpawner.createObject(gameArea, {"missileData": missile})
            }
        }


        // List of names of players
        Column {
            anchors.left: parent.left
            anchors.top: parent.top
            height: 100
            width: 100
            Repeater {
                model: GameManager.players
                delegate: Image {
                    source: modelData.spritePath
                    height: 45
                    width: height


                    Rectangle {
//                        border.width: 2
//                        border.color: "white"
                        anchors.left: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        color: playerColors[modelData.id]
                        opacity: modelData.energy / 2000 + 0.5
                        width: 400 * modelData.energy / 1000
                        Behavior on width { NumberAnimation { duration: 60; } }
                        ColorAnimation on color {
                            id: coloranim
                            duration: 100
                            from: "white"
                            to: playerColors[modelData.id]
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.right
                        text: modelData.name + ": " + modelData.energy
                        color: "white"
                        style: Text.Outline
                        styleColor: "black"
                        font.family: "Aldrich"
                        font.pointSize: 20
                        font.strikeout: !modelData.alive
                    }
                }
            }
        }

        //visible: startScreen.opacity < 1
    }

    FastBlur {
        id: gameBlur
        anchors.fill: gameArea
        source: gameArea
        radius: 32
        //opacity: startScreen.opacity
        visible: false;//opacity > 0

    }

    BrightnessContrast {
        id: gameFilter
        source: gameBlur
        anchors.fill: gameBlur
        //visible: opacity > 0
        opacity: 0
        NumberAnimation on opacity {
            running: false
            id: blurAnimation
            duration: 500
            from: 1
            to: 0
        }
        brightness: 0.9
        contrast: 0.4
    }

    focus: true


    EndScreen {
        opacity: (GameManager.roundsPlayed >= GameManager.maxRounds)
        objectName: "endScreen"
    }

    StartScreen {
        id: startScreen
        opacity: 1
        //onOpacityChanged: gameFilter.opacity = opacity
    }

//    FastBlur {
//        id: titleBlur
//        anchors.fill: startScreen
//        source: startScreen
//        radius: 16
//        //opacity: startScreen.opacity
//        visible: false;//opacity > 0

//    }

//    BrightnessContrast {
//        source: titleBlur
//        anchors.fill: titleBlur
//        //visible: opacity > 0
//        brightness: 1
//        contrast: 1
//    }

    Text {
        id: aboutText
        anchors.bottom: buildId.top
        anchors.right: parent.right
        anchors.margins: 10
        color: "white"
        text: "code:martin^remarkable"
        font.pointSize: 10
        opacity: 0.5
    }

    Text {
        id: buildId
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        color: "white"
        text: GameManager.version()
        font.pointSize: 10
        opacity: 0.3
    }
}

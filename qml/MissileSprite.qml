import QtQuick 2.0
import QtQuick.Particles 2.0
import QtGraphicalEffects 1.0

Item {
    id: missile
    smooth: false
    width: main.scaleSize / 20
    height: width

    property var missileData
    property int energy: (missileData === null) ? 0 : missileData.energy
    rotation: (missileData === null) ? 0 : missileData.rotation + 90

    onMissileDataChanged: {
        if (missileData === null) {
            destroy()
        }
    }

    x: (missileData === null) ? 0 : main.width / 2 + missileData.position.x * main.width / 2 - width / 2
    y: (missileData === null) ? 0 : main.height / 2 + missileData.position.y * main.height / 2 - height / 2

    Image {
        id: image
        anchors.fill: parent
        source: missile.energy < 75 ?
                    (missile.energy < 40 ?
                         "qrc:/sprites/missile-empty.png" :
                         "qrc:/sprites/missile-half.png") :
                    "qrc:/sprites/missile-full.png"
        visible: false
        smooth: false
    }
    //onRotationChanged: console.log(rotation)
    ColorOverlay {
        anchors.fill: image
        source: image
        color: missileData === null ? "transparent" : playerColors[missileData.owner()]
//        rotation: missile.rotation
    }

    property var particleGroups: ["Player1", "Player2", "Player3", "Player4"]
    Emitter {
        id: trailEmitter
        anchors.centerIn: parent
        width: parent.width / 2
        height: width
        emitRate: missile.energy > 10 ? 500 : 10
        lifeSpan: 500
        lifeSpanVariation: 90
        enabled: true
        group: (missileData === null) ? "" : particleGroups[missileData.owner()]
        velocity: AngleDirection {
            angle: missile.rotation + 90
            magnitude: missile.energy > 10 ? 200 : 0
            magnitudeVariation: missile.energy > 10 ? 100 : 10
            angleVariation: 5
        }
        size: 8
        sizeVariation: 4
        system: missileParticles
        //velocityFromMovement: 10
        endSize: 20
        shape: EllipseShape {
        }
    }

//    RotationAnimation on rotation {
//        from: 0
//        to: 360
//        duration: 5000
//        loops: Animation.Infinite
//    }
}

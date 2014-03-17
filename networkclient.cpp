#include "networkclient.h"
#include <QTcpSocket>
#include <QHostAddress>
#include <QCryptographicHash>
#include "player.h"
#include "map.h"
#include "bomb.h"

NetworkClient::NetworkClient(QTcpSocket *socket) :
    QObject(socket), m_socket(socket), m_isWebSocket(false), m_json(false)
{
    socket->open(QIODevice::ReadWrite);
    m_name = m_socket->peerAddress().toString();

    connect(m_socket, SIGNAL(disconnected()), SIGNAL(clientDisconnected()));
    connect(m_socket, SIGNAL(readyRead()), SLOT(dataReceived()));
}

QString NetworkClient::remoteName()
{
    return m_name;
}

void NetworkClient::sendString(QByteArray string)
{
    if (m_isWebSocket) {
        foreach(QByteArray line, string.split('\n')) {
            m_socket->write("\0");
            m_socket->write(line + "\r\n");
            m_socket->write("\xff");
        }
    } else {
        m_socket->write(string);
    }
}

void NetworkClient::sendWelcome(const QByteArray &mapData, const QPoint &startData)
{
    sendString("HELLO\n");
    sendString("MAP\n");
    sendString(mapData);
    sendString("ENDMAP\n");
    sendString("STARTPOSITION\n");
    sendString(QByteArray::number(startData.x()) + ',');
    sendString(QByteArray::number(startData.y()) + '\n');
}

void NetworkClient::sendOK()
{
    sendString("OK\n");
}

void NetworkClient::sendState(QList<Player *> players, const Map *map)
{
    if (m_json) {
        sendString("{\n  players: [\n");
        foreach(Player *player, players) {
            if (!player) continue;
            sendString("    { id: " + QByteArray::number(player->id()) +
                       ", x: " + QByteArray::number(player->position().x()) +
                       ', y:' + QByteArray::number(player->position().y()) + " }\n");
        }
        sendString("  ],\n");

        sendString("  bombs: [\n");
        foreach(Bomb *bomb, map->bombs()) {
            if (!bomb) continue;
            sendString("    { x: " + QByteArray::number(bomb->position().x()) + ", y:" +
                       QByteArray::number(bomb->position().y()) + ", state:" +
                       QByteArray::number(BOMB_STATES - bomb->state()) + " }\n");
        }
        sendString("  ],\n");
    } else {
        sendString("PLAYERS\n");
        foreach(Player *player, players) {
            if (!player) continue;
            sendString(QByteArray::number(player->id()) + ' ' +
                       QByteArray::number(player->position().x()) + ',' +
                       QByteArray::number(player->position().y()) + '\n');
        }
        sendString("ENDPLAYERS\n");

        sendString("BOMBS\n");
        foreach(Bomb *bomb, map->bombs()) {
            if (!bomb) continue;
            sendString(QByteArray::number(bomb->position().x()) + ',' +
                       QByteArray::number(bomb->position().y()) + ' ' +
                       QByteArray::number(BOMB_STATES - bomb->state()) + '\n');
        }
        sendString("ENDBOMBS\n");
    }


    if (m_json) {
        sendString("   map: [");
    } else {
        sendString("MAP\n");
    }

    for (int y=0; y<map->height(); y++) {
        QByteArray mapLine;
        for (int x=0; x<map->width(); x++) {
            switch (map->tileAt(QPoint(x, y))->type()) {
            case Tile::Grass:
                mapLine += '.';
                break;
            case Tile::Floor:
                mapLine += '_';
                break;
            case Tile::Wall:
                mapLine += '+';
                break;
            case Tile::Stone:
                mapLine += '#';
                break;
            case Tile::Debris:
                mapLine += ' ';
                break;
            case Tile::Invalid:
                mapLine += 'x';
                break;
            }
        }
        if (m_json) {
            sendString("\"" + mapLine + "\",");
        } else {
            sendString(mapLine + '\n');
        }
    }

    if (m_json) {
        sendString("  ]\n}\n");
    } else {
        sendString("ENDMAP\n");
    }
}

void NetworkClient::dataReceived()
{
    QByteArray data = m_socket->readAll();
    if (m_isWebSocket) {
        if (m_webSocketFrame.isEmpty() && !data.startsWith('\0')) return; // invalid data

        m_webSocketFrame += data;

        if (data.endsWith('\xff')) {
            data = m_webSocketFrame;
            m_webSocketFrame.clear();
        } else {
            return;
        }
    }


    QList<QByteArray> lines = data.split('\n');
    foreach(const QByteArray line, lines) {
        qDebug() << "LINE:" << line;
        if (line.isEmpty()) continue;

        if (line.startsWith("NAME ")) {
            QList<QByteArray> splitLine = line.split(' ');
            if (splitLine.length() < 2) continue;
            m_name = splitLine[1];
            if (m_name.length() > 10) {
                m_name = m_name.left(10);
            }
            emit nameChanged(m_name);
            continue;
        }

        if (line.startsWith("JSON")) {
            m_json = true;
            continue;
        }

        if (line.startsWith("Sec-WebSocket-Key:")) {
            qDebug() << "GOT SEECRKET";
            QList<QByteArray> splitLine = line.split(':');
            if (splitLine.length() < 2) continue;
            QByteArray handshake = splitLine[1].trimmed() + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

            QCryptographicHash hash(QCryptographicHash::Sha1);
            hash.addData(handshake);
            handshake = hash.result().toBase64();
            m_socket->write("HTTP/1.1 101 Switching Protocols\r\n"
                            "Upgrade: websocket\r\n"
                            "Connection: Upgrade\r\n"
                            "Sec-WebSocket-Accept: " + handshake + "\r\n"
                            "Sec-WebSocket-Protocol: chat\r\n");
            continue;
        }

        emit commandReceived(QString::fromLatin1(line.trimmed()));
    }
}

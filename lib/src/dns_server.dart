// Copyright 2019 Gohilla.com team.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:raw/raw.dart';
import 'package:universal_io/io.dart';

import 'dns_client.dart';
import 'dns_packet.dart';

typedef void DnsPacketHandler(DnsPacket response, InternetAddress address, int port);

class DnsServer {
  static const int defaultPort = 53;

  final RawDatagramSocket socket;
  // final DnsClient client;
  static StreamSubscription<RawSocketEvent>? _dnsSocketSubscription;

  DnsServer(this.socket/*, this.client*/);

  void close() {
    socket.close();
    _dnsSocketSubscription?.cancel();
  }

  static Future<DnsServer> bind(DnsClient client,
      {InternetAddress? address, int port = defaultPort, DnsPacketHandler? receivedDnsPacket}) async {
    address ??= InternetAddress.loopbackIPv4;
    final socket = await RawDatagramSocket.bind(address, port);
    // final server = DnsServer(socket, client);
    final server = DnsServer(socket);
    _dnsSocketSubscription = socket.listen((event) {
      if (event == RawSocketEvent.read) {
        while (true) {
          final datagram = socket.receive();
          if (datagram == null) {
            break;
          }
          server._receivedDatagram(datagram, receivedDnsPacket: receivedDnsPacket);
        }
      }
    });
    return server;
  }

  void _receivedDatagram(Datagram datagram, {DnsPacketHandler? receivedDnsPacket}) async {
    // Decode packet
    final dnsPacket = DnsPacket();
    dnsPacket.decodeRaw(RawReader.withBytes(datagram.data));
    receivedDnsPacket?.call(dnsPacket, datagram.address, datagram.port);
  }

  // void receivedDnsPacket(
  //     DnsPacket packet, InternetAddress address, int port) async {
  //   // Handle packet
  //   final result = await client.handlePacket(packet);

  //   if (result != null) {
  //     // Send response back
  //     result.id = packet.id;
  //     socket.send(result.toUint8ListViewOrCopy(), address, port);
  //   }
  // }

  void respond(DnsPacket response, InternetAddress address, int port) {
    socket.send(response.toUint8ListViewOrCopy(), address, port);
  }

}

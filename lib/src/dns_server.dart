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
import 'dart:typed_data';

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
    print('DnsServer: Binding to ${address.address} on port ${port}');
    final socket = await RawDatagramSocket.bind(address, port, reuseAddress: true, reusePort: true);
    socket.joinMulticast(address);
    
    final server = DnsServer(socket);
    server.socket.broadcastEnabled = true;
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
    try {
      // Decode packet
      final dnsPacket = DnsPacket();
      dnsPacket.decodeRaw(RawReader.withBytes(datagram.data));
      // print('DnsServer: Received packet ${dnsPacket.id} from ${datagram.address.address}:${datagram.port}');
      receivedDnsPacket?.call(dnsPacket, datagram.address, datagram.port);
    } catch (err, st) {
      print('DnsServer: An error occurred while decoding packet.');
      print(err.toString());
      print(st.toString());
    } 
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

  void respondWithBytes(Uint8List response, InternetAddress address, int port) {
    int sent = socket.send(response, address, port);
    print('DnsServer: Wrote $sent / ${response.length} bytes');
  }

}

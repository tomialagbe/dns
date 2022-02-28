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

import 'package:dns/dns.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void main() {
  group("DnsClient.system", () {
    test("lookupPacket('google.com')", () async {
      final client = SystemDnsClient();
      final packet = await client.lookupPacket("google.com");
      expect(packet, isNotNull);
      expect(packet.isResponse, isTrue);
      expect(packet.answers, hasLength(greaterThan(0)));
      expect(packet.answers[0].name, "google.com");
      expect(packet.answers[0].data, hasLength(greaterThan(1)));
    }, testOn: "vm");

    test("lookup('google.com')", () async {
      final client = SystemDnsClient();
      final response = await client.lookup("google.com");
      expect(response, hasLength(greaterThan(0)));
    }, testOn: "vm");
  });

  group("UdpDnsClient", () {
    test("lookupPacket('google.com')", () async {
      final client = UdpDnsClient(
        remoteAddress: InternetAddress("8.8.8.8"),
      );
      final packet = await client.lookupPacket("google.com");
      expect(packet, isNotNull);
      expect(packet.isResponse, isTrue);
      expect(packet.answers, hasLength(greaterThan(0)));
      expect(packet.answers[0].name, "google.com");
      expect(packet.answers[0].data, hasLength(greaterThan(1)));
    }, testOn: "vm");

    test("lookup('google.com')", () async {
      final client = UdpDnsClient(
        remoteAddress: InternetAddress("8.8.8.8"),
      );
      final response = await client.lookup("google.com");
      expect(response, hasLength(greaterThan(0)));
    }, testOn: "vm");
  });

  group("HttpDnsClient", () {
    test("lookupPacket('google.com')", () async {
      final client = HttpDnsClient.google();
      final packet = await client.lookupPacket("google.com");
      expect(packet, isNotNull);
      expect(packet.isResponse, isTrue);
      expect(packet.answers, hasLength(greaterThan(0)));
      expect(packet.answers[0].name, "google.com");
      expect(packet.answers[0].data, hasLength(greaterThan(1)));
    });

    test("lookup('google.com')", () async {
      final client = HttpDnsClient.google();
      final addresses = await client.lookup("google.com");
      expect(addresses, hasLength(greaterThan(0)));
      for (var address in addresses) {
        expect(address, isNotNull);
        expect(address.toUint8ListViewOrCopy(), hasLength(greaterThan(3)));
      }
    });
  });
}

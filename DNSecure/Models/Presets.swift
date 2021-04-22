//
//  Presets.swift
//  DNSecure
//
//  Created by Kenta Kubo on 9/25/20.
//

import Foundation

enum Presets {
    static let servers: Resolvers = [
        .init(
            name: "Protect you from Malware, Adults & Unsafe things (Cloudflare)",
            configuration: .dnsOverHTTPS(
                DoHConfiguration(
                    servers: [
                        "1.1.1.3",
                        "1.0.0.3",
                        "2606:4700:4700::1113",
                        "2606:4700:4700::1003",
                    ],
                    serverURL: URL(string: "https://family.cloudflare-dns.com/dns-query")
                )
            )
        ),
        .init(
            name: "Block Inapproriate contents & Unsafe Videos on Youtube and Internet (Cleanbrowsing)",
            configuration: .dnsOverHTTPS(
                DoHConfiguration(
                    servers: [
                        "185.228.168.168",
                        "185.228.169.168",
                        "2a0d:2a00:1::",
                        "2a0d:2a00:2::",
                    ],
                    serverURL: URL(string: "https://doh.cleanbrowsing.org/doh/family-filter/")
                )
            )
        ),
        .init(
            name: "Protect parent and kids from threats & bad contents on the Internet (OpenDNS Family Shield)",
            configuration: .dnsOverHTTPS(
                DoHConfiguration(
                    servers: [
                        "208.67.222.123",
                        "208.67.220.123",
                        "::ffff:d043:de7b",
                        "::ffff:d043:dc7b",
                    ],
                    serverURL: URL(string: "https://doh.familyshield.opendns.com/dns-query")
                )
            )
        ),
    ]
}

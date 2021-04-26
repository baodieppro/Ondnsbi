//
//  DetailView.swift
//  DNSecure
//
//  Created by Kenta Kubo on 9/25/20.
//

import SwiftUI

struct DetailView {
    @Binding var server: Resolver
    @Binding var isOn: Bool

    func binding(for rule: OnDemandRule) -> Binding<OnDemandRule> {
        guard let index = self.server.onDemandRules.firstIndex(of: rule) else {
            preconditionFailure("Can't find rule in array")
        }
        return self.$server.onDemandRules[index]
    }
}

extension DetailView: View {
    var body: some View {
        Form {
            Section {
                Toggle("Use This Server", isOn: self.$isOn)
            }
            Section {
                HStack {
                    Text("Name")
                    TextField("Name", text: self.$server.name)
                        .multilineTextAlignment(.trailing)
                }
            }
            switch self.server.configuration {
            case var .dnsOverTLS(configuration):
                Section(
                    header: EditButton()
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .overlay(Text("Family-friendly Internet Filters"), alignment: .leading),
                    footer: Text("The DNS server IP addresses.")
                ) {
                    ForEach(0..<configuration.servers.count, id: \.self) { i in
                        TextField(
                            "IP address",
                            text: .init(
                                get: { configuration.servers[i] },
                                set: { configuration.servers[i] = $0 }
                            ),
                            onCommit: {
                                self.server.configuration = .dnsOverTLS(configuration)
                            }
                        )
                        .textContentType(.URL)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                    .onDelete {
                        configuration.servers.remove(atOffsets: $0)
                        self.server.configuration = .dnsOverTLS(configuration)
                    }
                    .onMove {
                        configuration.servers.move(fromOffsets: $0, toOffset: $1)
                        self.server.configuration = .dnsOverTLS(configuration)
                    }
                    Button("Add New Server") {
                        configuration.servers.append("")
                        self.server.configuration = .dnsOverTLS(configuration)
                    }
                }
                Section(
                    header: Text("Powered by Onbibi, feedback us at giabaodiep@gmail.com"),
                    footer: Text("Onbibi Shield is a free application for protecting children from inapproriate contents and bad websites on the Internet.")
                ) {
                    HStack {
                        Text("Server Name")
                        Spacer()
                        TextField(
                            "Server Name",
                            text: .init(
                                get: {
                                    configuration.serverName ?? ""
                                },
                                set: {
                                    configuration.serverName = $0
                                }
                            ),
                            onCommit: {
                                self.server.configuration = .dnsOverTLS(configuration)
                            }
                        )
                        .multilineTextAlignment(.trailing)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                }
            case var .dnsOverHTTPS(configuration):
                Section(
                    header: EditButton()
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .overlay(Text("Servers"), alignment: .leading),
                    footer: Text("The DNS server IP addresses.")
                ) {
                    ForEach(0..<configuration.servers.count, id: \.self) { i in
                        TextField(
                            "IP address",
                            text: .init(
                                get: { configuration.servers[i] },
                                set: { configuration.servers[i] = $0 }
                            ),
                            onCommit: {
                                self.server.configuration = .dnsOverHTTPS(configuration)
                            }
                        )
                        .textContentType(.URL)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                    .onDelete {
                        configuration.servers.remove(atOffsets: $0)
                        self.server.configuration = .dnsOverHTTPS(configuration)
                    }
                    .onMove {
                        configuration.servers.move(fromOffsets: $0, toOffset: $1)
                        self.server.configuration = .dnsOverHTTPS(configuration)
                    }
                    Button("Add New Server") {
                        configuration.servers.append("")
                        self.server.configuration = .dnsOverHTTPS(configuration)
                    }
                }
                Section(
                    header: Text("DNS-over-HTTPS Settings"),
                    footer: Text("The URL of a DNS-over-HTTPS server.")
                ) {
                    HStack {
                        Text("Server URL")
                        Spacer()
                        TextField(
                            "Server URL",
                            text: .init(
                                get: {
                                    configuration.serverURL?.absoluteString ?? ""
                                },
                                set: {
                                    configuration.serverURL = URL(string: $0)
                                }
                            ),
                            onCommit: {
                                self.server.configuration = .dnsOverHTTPS(configuration)
                            }
                        )
                        .multilineTextAlignment(.trailing)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                }
            }
            Section(
                header: EditButton()
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .overlay(Text("On Demand Rules"), alignment: .leading)
            ) {
                ForEach(self.server.onDemandRules) { rule in
                    NavigationLink(
                        rule.name,
                        destination: RuleView(rule: self.binding(for: rule))
                    )
                }
                .onDelete { self.server.onDemandRules.remove(atOffsets: $0) }
                .onMove { self.server.onDemandRules.move(fromOffsets: $0, toOffset: $1) }
                Button("Add New Rule") {
                    self.server.onDemandRules
                        .append(OnDemandRule(name: "New Rule"))
                }
            }
        }
        .navigationTitle(self.server.name)
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(
            server: .constant(
                .init(
                    name: "My Server",
                    configuration: .dnsOverTLS(DoTConfiguration())
                )
            ),
            isOn: .constant(true)
        )
    }
}

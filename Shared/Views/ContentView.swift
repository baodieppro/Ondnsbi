//
//  ContentView.swift
//  DNSecure
//
//  Created by Kenta Kubo on 7/1/20.
//

import NetworkExtension
import SwiftUI

struct ContentView {
    @Environment(\.scenePhase) var scenePhase
    @Binding var servers: Resolvers
    @Binding var usedID: String?
    @State var isEnabled = false
    @State var selection: Int?
    @State var alertIsPresented = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    @State var guideIsPresented = false

    func addNewDoTServer() {
        self.servers.append(
            .init(
                name: "New",
                configuration: .dnsOverTLS(DoTConfiguration())
            )
        )
        self.selection = self.servers.count - 1
    }

    func addNewDoHServer() {
        self.servers.append(
            .init(
                name: "New",
                configuration: .dnsOverHTTPS(DoHConfiguration())
            )
        )
        self.selection = self.servers.count - 1
    }

    func removeServers(at indexSet: IndexSet) {
        if let current = self.selection, indexSet.contains(where: { $0 <= current }) {
            // FIXME: This is a workaround not to crash on deletion.
            self.selection = -1
        }
        if indexSet.map({ self.servers[$0].id.uuidString }).contains(self.usedID) {
            self.removeSettings()
        }
        // FIXME: This is a workaround not to crash on deletion.
        // Wait for closing DetailView.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            self.servers.remove(atOffsets: indexSet)
        }
    }

    func moveServers(from src: IndexSet, to dst: Int) {
        // TODO: Change self.selection if needed
        self.servers.move(fromOffsets: src, toOffset: dst)
    }

    func updateStatus() {
        #if !targetEnvironment(simulator)
            let manager = NEDNSSettingsManager.shared()
            manager.loadFromPreferences {
                if let err = $0 {
                    logger.error("\(err.localizedDescription)")
                    self.alert("Load Error", err.localizedDescription)
                } else {
                    self.isEnabled = manager.isEnabled
                }
            }
        #endif
    }

    func saveSettings(of server: Resolver) {
        if self.usedID != server.id.uuidString {
            self.usedID = server.id.uuidString
        }

        #if !targetEnvironment(simulator)
            let manager = NEDNSSettingsManager.shared()
            manager.dnsSettings = server.configuration.toDNSSettings()
            manager.onDemandRules = server.onDemandRules.toNEOnDemandRules()
            manager.saveToPreferences { saveError in
                if let saveError = saveError as NSError? {
                    guard saveError.domain != "NEConfigurationErrorDomain"
                            || saveError.code != 9 else {
                        // Nothing was changed
                        return
                    }
                    logger.error("\(saveError.localizedDescription)")
                    self.alert("Save Error", saveError.localizedDescription)
                    self.removeSettings()
                    return
                }
                logger.debug("DNS settings was saved")
            }
        #endif
    }

    func removeSettings() {
        self.usedID = nil

        #if !targetEnvironment(simulator)
            let manager = NEDNSSettingsManager.shared()
            guard manager.dnsSettings != nil else {
                // Already removed
                return
            }
            manager.removeFromPreferences { removeError in
                self.updateStatus()
                if let removeError = removeError {
                    logger.error("\(removeError.localizedDescription)")
                    self.alert("Remove Error", removeError.localizedDescription)
                    return
                }
                logger.debug("DNS settings was removed")
            }
        #endif
    }

    func alert(_ title: String, _ message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.alertIsPresented = true
    }
}

extension ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    "Instructions",
                    destination: HowToActivateView(isSheet: false),
                    tag: -1,
                    selection: self.$selection
                )
                Section(header: Text("Servers")) {
                    ForEach(0..<self.servers.count, id: \.self) { i in
                        NavigationLink(
                            destination: DetailView(
                                server: self.$servers[i],
                                isOn: .init(
                                    get: {
                                        self.usedID == self.servers[i].id.uuidString
                                    },
                                    set: {
                                        if $0 {
                                            self.saveSettings(of: self.servers[i])
                                        } else {
                                            self.removeSettings()
                                        }
                                    }
                                )
                            ),
                            tag: i,
                            selection: self.$selection
                        ) {
                            VStack(alignment: .leading) {
                                Text(self.servers[i].name)
                                Text(self.servers[i].configuration.description)
                                    .foregroundColor(.secondary)
                            }
                            if self.usedID == self.servers[i].id.uuidString {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .onDelete(perform: self.removeServers)
                    .onMove(perform: self.moveServers)
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle(Bundle.main.displayName!)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("DNS-over-TLS", action: self.addNewDoTServer)
                        Button("DNS-over-HTTPS", action: self.addNewDoHServer)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .status) {
                    VStack {
                        HStack {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundColor(self.isEnabled ? .green : .secondary)
                            Text(self.isEnabled ? "Active" : "Inactive")
                        }
                        if !self.isEnabled {
                            Button("How to Activate") {
                                self.guideIsPresented = true
                            }
                            .sheet(isPresented: self.$guideIsPresented) {
                                HowToActivateView(isSheet: true)
                            }
                        }
                    }
                }
            }
            .alert(isPresented: self.$alertIsPresented) {
                Alert(
                    title: Text(self.alertTitle),
                    message: Text(self.alertMessage)
                )
            }

            if !self.isEnabled {
                HowToActivateView(isSheet: false)
            } else {
                Text("Select a server on the sidebar")
                    .navigationBarHidden(true)
            }
        }
        .onChange(of: self.scenePhase) { phase in
            if phase == .active {
                self.updateStatus()
            } else if phase == .background {
                // FIXME: This is a workaround for self.$severs[i].
                // That cannot save settings as soon as it is modified.
                guard let id = self.usedID,
                      let uuid = UUID(uuidString: id),
                      let server = self.servers.find(by: uuid) else {
                    return
                }
                self.saveSettings(of: server)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(servers: .constant([]), usedID: .constant(nil))
    }
}

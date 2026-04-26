import SwiftUI

struct RoomsView: View {
    @State private var rooms: [Room] = []
    @State private var showingCreate = false
    @State private var showingJoin = false

    var body: some View {
        NavigationStack {
            Group {
                if rooms.isEmpty {
                    emptyState
                } else {
                    List(rooms) { room in
                        NavigationLink(value: room) {
                            roomRow(room)
                        }
                    }
                }
            }
            .navigationTitle("방")
            .navigationDestination(for: Room.self) { room in
                Text("Feed for \(room.name)")
                // TODO(sprint-1): RoomDetailView with feed
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("참여", systemImage: "person.crop.circle.badge.plus") {
                        showingJoin = true
                    }
                    Button("새 방", systemImage: "plus.circle") {
                        showingCreate = true
                    }
                }
            }
            .sheet(isPresented: $showingCreate) { CreateRoomSheet() }
            .sheet(isPresented: $showingJoin) { JoinRoomSheet() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("아직 방이 없어요")
                .font(.headline)
            Text("새 방을 만들거나 친구의 초대 코드를 입력하세요")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func roomRow(_ room: Room) -> some View {
        VStack(alignment: .leading) {
            Text(room.name).font(.headline)
            Text("\(room.memberCount)명 · 코드 \(room.inviteCode)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CreateRoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("방 이름", text: $name)
            }
            .navigationTitle("새 방")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("만들기") {
                        // TODO(sprint-1): POST /rooms { name } → invite_code
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

private struct JoinRoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""

    var body: some View {
        NavigationStack {
            Form {
                let field = TextField("초대 코드 (6자리)", text: $code)
                    .autocorrectionDisabled()
                #if os(iOS)
                field.textInputAutocapitalization(.characters)
                #else
                field
                #endif
            }
            .navigationTitle("방 참여")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("참여") {
                        // TODO(sprint-1): POST /rooms/:code/join
                        dismiss()
                    }
                    .disabled(code.count != 6)
                }
            }
        }
    }
}

#Preview {
    RoomsView()
}

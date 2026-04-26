//
//  RoomsView.swift
//  VerticalLog
//

import SwiftUI

struct RoomsView: View {
    @State private var viewModel = RoomsViewModel()
    @State private var showingCreate = false
    @State private var showingJoin = false
    @State private var inviteCodeToShare: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("방")
                .navigationDestination(for: Room.self) { room in
                    Text("Feed for \(room.name)")
                    // TODO(sprint-3.3): RoomDetailView with feed
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            showingJoin = true
                        } label: {
                            Label("참여", systemImage: "person.crop.circle.badge.plus")
                        }
                        Button {
                            showingCreate = true
                        } label: {
                            Label("새 방", systemImage: "plus.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingCreate) {
                    CreateRoomSheet(viewModel: viewModel) { newCode in
                        inviteCodeToShare = newCode
                    }
                }
                .sheet(isPresented: $showingJoin) {
                    JoinRoomSheet(viewModel: viewModel)
                }
                .sheet(item: Binding(
                    get: { inviteCodeToShare.map(InviteCodeWrapper.init) },
                    set: { inviteCodeToShare = $0?.value }
                )) { wrapper in
                    InviteCodeShareSheet(code: wrapper.value)
                }
                .refreshable { await viewModel.refresh() }
                .task { await viewModel.load() }
                .alert(
                    "오류",
                    isPresented: Binding(
                        get: { viewModel.errorMessage != nil },
                        set: { if !$0 { viewModel.errorMessage = nil } }
                    ),
                    actions: { Button("확인") { viewModel.errorMessage = nil } },
                    message: { Text(viewModel.errorMessage ?? "") }
                )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let rooms) where rooms.isEmpty:
            emptyState
        case .loaded(let rooms):
            List(rooms) { room in
                NavigationLink(value: room) { roomRow(room) }
                    .swipeActions(edge: .trailing) {
                        Button {
                            inviteCodeToShare = room.inviteCode
                        } label: {
                            Label("코드 공유", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
            }
            .listStyle(.plain)
        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("다시 시도") {
                    Task { await viewModel.refresh() }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func roomRow(_ room: Room) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(room.name).font(.headline)
            Text("\(room.memberCount)명 · 코드 \(room.inviteCode)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create

private struct CreateRoomSheet: View {
    let viewModel: RoomsViewModel
    let onCreated: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("방 이름", text: $name)
                        .disabled(isSubmitting)
                } footer: {
                    Text("4~12명 친구 그룹용. 만들면 6자리 초대 코드가 나와요.")
                }
            }
            .navigationTitle("새 방")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("만들기") {
                        submit()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting { ProgressView().controlSize(.large) }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            if let room = await viewModel.create(name: name.trimmingCharacters(in: .whitespaces)) {
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                    onCreated(room.inviteCode)
                }
            } else {
                await MainActor.run { isSubmitting = false }
            }
        }
    }
}

// MARK: - Join

private struct JoinRoomSheet: View {
    let viewModel: RoomsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("초대 코드 (6자리)", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.title3, design: .monospaced))
                        .disabled(isSubmitting)
                } footer: {
                    Text("친구가 보낸 6자리 영숫자 코드를 입력하세요.")
                }
            }
            .navigationTitle("방 참여")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("참여") {
                        submit()
                    }
                    .disabled(code.count != 6 || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting { ProgressView().controlSize(.large) }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            let result = await viewModel.join(code: code)
            await MainActor.run {
                isSubmitting = false
                if result != nil { dismiss() }
            }
        }
    }
}

// MARK: - Invite code share

private struct InviteCodeWrapper: Identifiable {
    let id = UUID()
    let value: String
}

private struct InviteCodeShareSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Text("초대 코드")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(code)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .padding(.vertical, 8)

                Button {
                    UIPasteboard.general.string = code
                } label: {
                    Label("복사", systemImage: "doc.on.doc")
                        .padding(.horizontal, 16).padding(.vertical, 8)
                }
                .buttonStyle(.bordered)

                ShareLink(
                    item: shareMessage,
                    subject: Text("vertical-log 초대"),
                    message: Text(shareMessage)
                ) {
                    Label("친구에게 공유", systemImage: "square.and.arrow.up")
                        .padding(.horizontal, 16).padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("방이 만들어졌어요")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var shareMessage: String {
        """
        vertical-log에 초대했어요. 코드: \(code)
        앱에서 '방 참여' → 코드 입력
        """
    }
}

#Preview {
    RoomsView()
}

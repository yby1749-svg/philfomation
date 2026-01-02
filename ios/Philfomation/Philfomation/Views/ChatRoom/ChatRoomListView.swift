//
//  ChatRoomListView.swift
//  Philfomation
//

import SwiftUI

struct ChatRoomListView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var showCreateRoom = false

    var body: some View {
        VStack(spacing: 0) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(
                        title: "전체",
                        isSelected: viewModel.selectedRoomCategory == nil
                    ) {
                        viewModel.setRoomCategory(nil)
                    }

                    ForEach(ChatRoomCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: viewModel.selectedRoomCategory == category
                        ) {
                            viewModel.setRoomCategory(category)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            // Room List
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.chatRooms.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "단톡방이 없습니다",
                    message: "새로운 단톡방을 만들어보세요"
                )
                Spacer()
            } else {
                List(viewModel.chatRooms) { room in
                    NavigationLink(destination: ChatRoomView(room: room)) {
                        ChatRoomListRow(room: room)
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateRoom = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showCreateRoom) {
            CreateChatRoomView()
        }
        .task {
            await viewModel.fetchChatRooms()
        }
        .refreshable {
            await viewModel.fetchChatRooms()
        }
    }
}

struct ChatRoomListRow: View {
    let room: ChatRoom

    var body: some View {
        HStack(spacing: 12) {
            // Room Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "2563EB").opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: room.category.icon)
                    .font(.title2)
                    .foregroundStyle(Color(hex: "2563EB"))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(room.name)
                        .font(.headline)

                    Spacer()

                    if let time = room.lastMessageTime {
                        Text(formatDate(time))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    if let lastMessage = room.lastMessage {
                        Text(lastMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(room.memberCount)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "a h:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
}

struct CreateChatRoomView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedCategory: ChatRoomCategory = .general
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("톡방 이름") {
                    TextField("톡방 이름을 입력하세요", text: $name)
                }

                Section("설명 (선택)") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                Section("카테고리") {
                    Picker("카테고리", selection: $selectedCategory) {
                        ForEach(ChatRoomCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle("단톡방 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("만들기") {
                        createRoom()
                    }
                    .disabled(name.isEmpty || isCreating)
                }
            }
            .overlay {
                if isCreating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("생성 중...")
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                }
            }
        }
    }

    private func createRoom() {
        isCreating = true

        Task {
            let _ = await viewModel.createChatRoom(
                name: name,
                description: description.isEmpty ? nil : description,
                category: selectedCategory
            )

            await MainActor.run {
                isCreating = false
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatRoomListView()
            .environmentObject(ChatViewModel())
    }
}

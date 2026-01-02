//
//  SearchHistoryView.swift
//  Philfomation
//

import SwiftUI

struct SearchHistoryView: View {
    let searchType: SearchType
    let onSelect: (String) -> Void

    @ObservedObject private var historyManager = SearchHistoryManager.shared
    @State private var showClearAlert = false

    private var history: [String] {
        historyManager.getHistory(for: searchType)
    }

    var body: some View {
        if !history.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("최근 검색")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        showClearAlert = true
                    } label: {
                        Text("전체 삭제")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                FlowLayout(spacing: 8) {
                    ForEach(history, id: \.self) { query in
                        SearchHistoryChip(
                            query: query,
                            onTap: {
                                onSelect(query)
                            },
                            onDelete: {
                                withAnimation {
                                    historyManager.removeSearch(query, type: searchType)
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .alert("검색 기록 삭제", isPresented: $showClearAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    withAnimation {
                        historyManager.clearHistory(type: searchType)
                    }
                }
            } message: {
                Text("모든 검색 기록을 삭제하시겠습니까?")
            }
        }
    }
}

struct SearchHistoryChip: View {
    let query: String
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onTap) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                    Text(query)
                        .font(.subheadline)
                }
            }
            .foregroundStyle(.primary)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

// MARK: - Flow Layout for chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            height = currentY + lineHeight
        }
    }
}

#Preview {
    SearchHistoryView(searchType: .business) { query in
        print("Selected: \(query)")
    }
}

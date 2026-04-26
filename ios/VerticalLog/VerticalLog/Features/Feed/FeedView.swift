//
//  FeedView.swift
//  VerticalLog
//

import SwiftUI

struct FeedView: View {
    @State private var clips: [Clip] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                if clips.isEmpty {
                    ContentUnavailableView(
                        "아직 클립이 없어요",
                        systemImage: "square.stack",
                        description: Text("방을 만들거나 참여하면 친구들 일상이 여기 쌓여요.")
                    )
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(clips) { clip in
                            ClipCard(clip: clip)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("피드")
        }
    }
}

private struct ClipCard: View {
    let clip: Clip

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // TODO(sprint-1): AVPlayer-backed video preview, autoplay on visible
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.2))
                .aspectRatio(9.0/16.0, contentMode: .fit)
                .overlay(
                    Image(systemName: "play.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.7))
                )

            Text(clip.authorDisplayName)
                .font(.subheadline.weight(.semibold))
            Text(clip.capturedAt.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    FeedView()
}

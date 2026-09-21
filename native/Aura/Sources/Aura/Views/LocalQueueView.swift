import SwiftUI

public struct LocalQueueView: View {
    @EnvironmentObject var music: MusicController
    @Binding var isPresented: Bool

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Заголовок
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .foregroundStyle(Theme.accent)
                                .font(.system(size: 16, weight: .semibold))
                            Text(L10n.current == .ru ? "Очередь воспроизведения" : "Playback Queue")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        Text(queueSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            music.openFiles()
                        } label: {
                            Label(L10n.current == .ru ? "Добавить" : "Add Files", systemImage: "plus")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.cardBorder))
                        }
                        .buttonStyle(.plain)

                        if !music.localQueue.isEmpty {
                            Button {
                                music.clearQueue()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.red.opacity(0.8))
                                    .padding(6)
                                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .help(L10n.current == .ru ? "Очистить очередь" : "Clear Queue")
                        }

                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)

                Divider().opacity(0.3)

                // Список треков
                if music.localQueue.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(Theme.accent.opacity(0.4))

                        Text(L10n.current == .ru ? "Очередь пуста" : "Queue is Empty")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)

                        Text(L10n.current == .ru ? "Перетащите аудиофайлы в окно или нажмите «Добавить»" : "Drag audio files into the window or click 'Add Files'")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)

                        Button {
                            music.openFiles()
                        } label: {
                            Text(L10n.current == .ru ? "Выбрать файлы" : "Choose Files")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(music.localQueue.enumerated()), id: \.element.id) { index, item in
                                let isCurrent = (index == music.localFileIndex)
                                HStack(spacing: 12) {
                                    // Индекс / статус воспроизведения
                                    ZStack {
                                        if isCurrent && music.playing {
                                            HStack(spacing: 2) {
                                                ForEach(0..<3) { b in
                                                    RoundedRectangle(cornerRadius: 1)
                                                        .fill(Theme.green)
                                                        .frame(width: 2, height: CGFloat(8 + (b * 4)))
                                                }
                                            }
                                        } else {
                                            Text("\(index + 1)")
                                                .font(.system(size: 11, weight: .medium).monospacedDigit())
                                                .foregroundStyle(isCurrent ? Theme.accent : Theme.textTertiary)
                                        }
                                    }
                                    .frame(width: 24)

                                    // Название и артист
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.system(size: 12, weight: isCurrent ? .bold : .medium))
                                            .foregroundStyle(isCurrent ? Theme.accent : Theme.textPrimary)
                                            .lineLimit(1)

                                        Text(item.artist)
                                            .font(.system(size: 10))
                                            .foregroundStyle(Theme.textSecondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    // Длительность
                                    if item.duration > 0 {
                                        Text(timestamp(item.duration))
                                            .font(.system(size: 10).monospacedDigit())
                                            .foregroundStyle(Theme.textTertiary)
                                    }

                                    // Удаление трека
                                    Button {
                                        music.removeFromQueue(at: index)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Theme.textTertiary)
                                            .padding(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    isCurrent ? Theme.accent.opacity(0.12) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    music.playQueueTrack(at: index)
                                }
                            }
                        }
                        .padding(14)
                    }
                }
            }
        }
        .frame(width: 480, height: 440)
    }

    private var queueSubtitle: String {
        let count = music.localQueue.count
        let suffix = L10n.current == .ru ? (count == 1 ? "трек" : (count < 5 ? "трека" : "треков")) : (count == 1 ? "track" : "tracks")
        return "\(count) \(suffix)"
    }

    private func timestamp(_ seconds: Double) -> String {
        let s = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

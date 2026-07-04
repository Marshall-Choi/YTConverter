import SwiftUI

struct SongEntry: Identifiable {
    let id = UUID()
    var url: String = ""
    var title: String = ""
    var artist: String = ""
}

struct ContentView: View {
    @StateObject private var vm = DownloadViewModel()
    @State private var entries: [SongEntry] = [SongEntry()]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── 헤더 ──────────────────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: "music.note")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("YouTube → Apple Music")
                        .font(.title2).bold()
                    Text("MP3 변환 · 볼륨 정규화(-16 LUFS) · 메타데이터 태깅")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: addEntry) {
                    Label("곡 추가", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.blue)
                .disabled(vm.isRunning)
            }
            .padding([.horizontal, .top], 24)
            .padding(.bottom, 14)

            Divider().padding(.horizontal, 24)

            // ── 곡 목록 ───────────────────────────────────────────────────
            ScrollView {
                VStack(spacing: 10) {
                    ForEach($entries) { $entry in
                        EntryRow(entry: $entry, canDelete: entries.count > 1) {
                            entries.removeAll { $0.id == entry.id }
                        }
                        .disabled(vm.isRunning)
                    }
                }
                .padding(20)
            }

            Divider().padding(.horizontal, 24)

            // ── 하단 버튼 + 상태 ──────────────────────────────────────────
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button(action: { vm.startDownload(entries: entries) }) {
                        Label(vm.isRunning ? "처리 중…" : "다운로드",
                              systemImage: "arrow.down.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(vm.isRunning)

                    Button(action: {
                        entries = [SongEntry()]
                        vm.clearAll()
                    }) {
                        Label("초기화", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(vm.isRunning)

                    Spacer()

                    if vm.isRunning { ProgressView().scaleEffect(0.8) }

                    if !vm.statusText.isEmpty {
                        Text(vm.statusText)
                            .font(.caption)
                            .foregroundStyle(vm.statusColor)
                    }
                }

                if vm.isRunning {
                    ProgressView(value: vm.progress, total: 1.0).tint(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            // ── 로그 ──────────────────────────────────────────────────────
            Divider().padding(.horizontal, 24)

            HStack {
                Label("로그", systemImage: "terminal").font(.headline)
                Spacer()
                Button { vm.clearLog() } label: {
                    Image(systemName: "xmark.circle").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 4)

            ScrollViewReader { proxy in
                ScrollView {
                    Text(vm.logText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .id("bottom")
                        .textSelection(.enabled)
                }
                .frame(minHeight: 160)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .onChange(of: vm.logText) { _ in
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }
        }
        .frame(minWidth: 560, minHeight: 520)
    }

    private func addEntry() {
        entries.append(SongEntry())
    }
}

// MARK: - 곡 한 줄 입력 행

struct EntryRow: View {
    @Binding var entry: SongEntry
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                TextField("YouTube URL", text: $entry.url)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                    .opacity(0) // 정렬용 spacer

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("제목").font(.caption2).foregroundStyle(.secondary)
                        TextField("비워두면 YouTube 제목 사용", text: $entry.title)
                            .textFieldStyle(.roundedBorder)
                            .font(.callout)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("가수").font(.caption2).foregroundStyle(.secondary)
                        TextField("비워두면 YouTube 가수 사용", text: $entry.artist)
                            .textFieldStyle(.roundedBorder)
                            .font(.callout)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}

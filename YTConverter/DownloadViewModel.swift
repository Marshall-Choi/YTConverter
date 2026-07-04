import SwiftUI

@MainActor
class DownloadViewModel: ObservableObject {
    @Published var logText: String = ""
    @Published var isRunning: Bool = false
    @Published var statusText: String = ""
    @Published var statusColor: Color = .secondary
    @Published var progress: Double = 0

    // MARK: - Public actions

    func startDownload(entries: [SongEntry]) {
        let valid = entries.filter { !$0.url.trimmingCharacters(in: .whitespaces).isEmpty
                                     && $0.url.hasPrefix("http") }
        guard !valid.isEmpty else {
            appendLog("⚠️  URL을 입력해 주세요.\n")
            statusText = "URL 없음"; statusColor = .orange
            return
        }

        isRunning = true
        progress = 0
        statusText = "준비 중…"; statusColor = .blue

        Task.detached { [weak self] in
            guard let self else { return }
            var allOK = true
            for (i, entry) in valid.enumerated() {
                await self.log("\n▶ [\(i+1)/\(valid.count)] \(entry.url)\n")
                await MainActor.run {
                    self.statusText = "\(i+1) / \(valid.count) 처리 중…"
                    self.progress = Double(i) / Double(valid.count)
                }
                let ok = await self.downloadAndNormalize(
                    url:    entry.url.trimmingCharacters(in: .whitespaces),
                    title:  entry.title.trimmingCharacters(in: .whitespaces),
                    artist: entry.artist.trimmingCharacters(in: .whitespaces)
                )
                if !ok { allOK = false }
            }
            await MainActor.run {
                self.isRunning = false
                self.progress = 1
                if allOK {
                    self.statusText = "✅ 완료! Apple Music 확인하세요"
                    self.statusColor = .green
                    self.appendLog("\n🎉 모든 처리 완료!\n")
                } else {
                    self.statusText = "⚠️ 일부 실패 — 로그 확인"
                    self.statusColor = .red
                    self.appendLog("\n⚠️  일부 처리 실패.\n")
                }
            }
        }
    }

    func clearAll() { logText = ""; statusText = "" }
    func clearLog()  { logText = "" }

    // MARK: - Pipeline

    private func downloadAndNormalize(url: String, title: String, artist: String) async -> Bool {
        guard let ytdlp  = findBin("yt-dlp")  else { await log("❌ yt-dlp 없음. brew install yt-dlp\n");  return false }
        guard let ffmpeg = findBin("ffmpeg")  else { await log("❌ ffmpeg 없음. brew install ffmpeg\n");   return false }

        let home    = FileManager.default.homeDirectoryForCurrentUser.path
        let tempDir = home + "/Desktop"
        let destDir = home + "/Music/Music/Media.localized/Automatically Add to Music.localized"

        // ── Step 1: 다운로드 ─────────────────────────────────────────────
        await log("  [1/3] 다운로드 중…\n")
        let ffmpegDir = URL(fileURLWithPath: ffmpeg).deletingLastPathComponent().path

        let (dlOut, dlOK) = await run(ytdlp, args: [
            "--remote-components", "ejs:github",
            "--ffmpeg-location", ffmpegDir,
            "-x", "--audio-format", "mp3", "--audio-quality", "0",
            "--no-embed-metadata",
            "-o", "%(title)s.%(ext)s",
            "--paths", "home:\(tempDir)",
            "--print", "after_move:filepath",
            url,
        ])
        guard dlOK else { await log("❌ 다운로드 실패\n"); return false }

        let dlPath = dlOut
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .last { $0.hasSuffix(".mp3") } ?? ""

        guard !dlPath.isEmpty, FileManager.default.fileExists(atPath: dlPath) else {
            await log("❌ 다운로드 파일을 찾을 수 없음\n"); return false
        }
        await log("  파일: \(URL(fileURLWithPath: dlPath).lastPathComponent)\n")

        // ── Step 2: 1패스 음량 분석 ──────────────────────────────────────
        await log("  [2/3] 음량 분석 중…\n")
        let (analysisOut, _) = await run(ffmpeg, args: [
            "-i", dlPath,
            "-af", "loudnorm=I=-14:TP=-1:LRA=11:print_format=json",
            "-f", "null", "-",
        ])
        guard let m = parseLoudnorm(analysisOut) else {
            await log("❌ 음량 분석 실패\n"); return false
        }
        await log("  측정 → I:\(m.i) LUFS  LRA:\(m.lra)  TP:\(m.tp)\n")

        // ── Step 3: 2패스 linear 정규화 + 메타데이터 태깅 ───────────────
        await log("  [3/3] 정규화·태깅 중…\n")

        let outName = URL(fileURLWithPath: dlPath).lastPathComponent
        let outPath = destDir + "/" + outName

        let filter = [
            "loudnorm=I=-14:TP=-1:LRA=11:linear=true",
            "measured_I=\(m.i)", "measured_LRA=\(m.lra)",
            "measured_TP=\(m.tp)", "measured_thresh=\(m.thresh)",
            "offset=\(m.offset)",
        ].joined(separator: ":")

        // -map_metadata -1 로 모든 메타데이터 초기화 후 제목·가수만 삽입
        var args: [String] = ["-i", dlPath, "-af", filter,
                              "-codec:a", "libmp3lame", "-qscale:a", "0",
                              "-map_metadata", "-1"]
        if !title.isEmpty  { args += ["-metadata", "title=\(title)"] }
        if !artist.isEmpty { args += ["-metadata", "artist=\(artist)"] }
        args += ["-y", outPath]

        let (_, normOK) = await run(ffmpeg, args: args)
        try? FileManager.default.removeItem(atPath: dlPath)

        if normOK { await log("✅ 완료 → \(outName)\n") }
        else       { await log("❌ 정규화 실패\n") }
        return normOK
    }

    // MARK: - Helpers

    private func findBin(_ name: String) -> String? {
        ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"]
            .map { "\($0)/\(name)" }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func run(_ exec: String, args: [String]) async -> (String, Bool) {
        await withCheckedContinuation { cont in
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: exec)
            proc.arguments = args
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError  = pipe
            var collected = ""
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
                collected += text
                Task { @MainActor [weak self] in self?.appendLog(text) }
            }
            proc.terminationHandler = { p in
                pipe.fileHandleForReading.readabilityHandler = nil
                cont.resume(returning: (collected, p.terminationStatus == 0))
            }
            do    { try proc.run() }
            catch { cont.resume(returning: ("", false)) }
        }
    }

    private func parseLoudnorm(_ text: String) -> LoudnormMeasured? {
        guard let s = text.range(of: "{"),
              let e = text.range(of: "}", options: .backwards) else { return nil }
        let json = String(text[s.lowerBound...e.upperBound])
        guard let data = json.data(using: .utf8),
              let obj  = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return nil }
        return LoudnormMeasured(
            i:      obj["input_i"]       ?? "-70",
            lra:    obj["input_lra"]     ?? "0",
            tp:     obj["input_tp"]      ?? "-1",
            thresh: obj["input_thresh"]  ?? "-70",
            offset: obj["target_offset"] ?? "0"
        )
    }

    private func log(_ text: String) async {
        await MainActor.run { appendLog(text) }
    }

    private func appendLog(_ text: String) {
        logText += text
        if logText.count > 60_000 { logText = String(logText.suffix(50_000)) }
    }
}

struct LoudnormMeasured { let i, lra, tp, thresh, offset: String }

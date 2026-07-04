import subprocess
import threading
import queue
import shutil


def find_ytdlp():
    path = shutil.which("yt-dlp")
    if path:
        return path
    # Common Homebrew / pip locations
    for candidate in ["/opt/homebrew/bin/yt-dlp", "/usr/local/bin/yt-dlp"]:
        if shutil.which(candidate):
            return candidate
    return "yt-dlp"


def download_urls(urls: list[str], log_queue: queue.Queue, done_callback):
    """
    Run yt-dlp for each URL sequentially in a background thread.
    Puts log lines into log_queue as strings.
    Calls done_callback(success: bool) when finished.
    """

    def run():
        ytdlp = find_ytdlp()
        all_ok = True

        for url in urls:
            url = url.strip()
            if not url:
                continue

            log_queue.put(f"\n▶ 다운로드 시작: {url}\n")

            cmd = [
                ytdlp,
                "--remote-components", "ejs:github",
                "-x",
                "--audio-format", "mp3",
                "--audio-quality", "0",
                "--postprocessor-args", "ffmpeg:-filter:a loudnorm=I=-14:TP=-1:LRA=11",
                "-o", "%(title)s.%(ext)s",
                "--paths", "temp:~/Desktop",
                "--paths", "home:~/Music/Music/Media.localized/Automatically Add to Music.localized",
                url,
            ]

            try:
                proc = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                )
                for line in proc.stdout:
                    log_queue.put(line)
                proc.wait()
                if proc.returncode != 0:
                    all_ok = False
                    log_queue.put(f"⚠️  오류 발생 (종료 코드 {proc.returncode}): {url}\n")
                else:
                    log_queue.put(f"✅ 완료: {url}\n")
            except FileNotFoundError:
                log_queue.put(
                    "❌ yt-dlp를 찾을 수 없습니다. 설치 후 다시 시도하세요.\n"
                    "   pip install yt-dlp  또는  brew install yt-dlp\n"
                )
                all_ok = False
                break
            except Exception as e:
                log_queue.put(f"❌ 예외 발생: {e}\n")
                all_ok = False

        log_queue.put(None)  # sentinel: done
        done_callback(all_ok)

    t = threading.Thread(target=run, daemon=True)
    t.start()

import queue
import tkinter as tk
from tkinter import scrolledtext, ttk

from downloader import download_urls


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("YouTube → Apple Music")
        self.geometry("700x560")
        self.minsize(500, 420)
        self.resizable(True, True)

        self._log_queue: queue.Queue = queue.Queue()
        self._running = False

        self._build_ui()
        self._poll_log()

    def _build_ui(self):
        # ── 상단 여백 ──
        pad = {"padx": 20, "pady": 6}

        # ── 제목 ──
        tk.Label(
            self, text="🎵  YouTube → Apple Music 변환기", font=("System", 16, "bold")
        ).pack(anchor="w", padx=20, pady=(16, 4))

        tk.Label(
            self,
            text="MP3 변환 + 볼륨 정규화(loudnorm) 후 Apple Music에 자동 추가",
            font=("System", 11),
            fg="gray",
        ).pack(anchor="w", padx=20, pady=(0, 12))

        ttk.Separator(self).pack(fill="x", padx=20, pady=(0, 12))

        # ── URL 입력 ──
        tk.Label(
            self,
            text="YouTube URL  (여러 개면 줄 바꿔서 입력)",
            font=("System", 12, "bold"),
        ).pack(anchor="w", **pad)

        self.url_text = tk.Text(
            self, height=5, font=("Menlo", 12), relief="solid", bd=1, wrap="none"
        )
        self.url_text.pack(fill="x", padx=20, pady=(0, 4))

        # ── 버튼 ──
        btn_frame = tk.Frame(self)
        btn_frame.pack(fill="x", padx=20, pady=(4, 8))

        self.dl_btn = tk.Button(
            btn_frame,
            text="⬇  다운로드",
            font=("System", 13, "bold"),
            bg="#007AFF",
            fg="white",
            activebackground="#005ecb",
            activeforeground="white",
            relief="flat",
            padx=18,
            pady=8,
            cursor="hand2",
            command=self._start_download,
        )
        self.dl_btn.pack(side="left")

        tk.Button(
            btn_frame,
            text="🗑  초기화",
            font=("System", 13),
            relief="flat",
            padx=18,
            pady=8,
            cursor="hand2",
            command=self._clear_all,
        ).pack(side="left", padx=(10, 0))

        # ── 진행 표시 ──
        self.progress_var = tk.StringVar(value="")
        self.progress_label = tk.Label(
            self, textvariable=self.progress_var, font=("System", 11), fg="#007AFF"
        )
        self.progress_label.pack(anchor="w", padx=20)

        self.progress = ttk.Progressbar(self, mode="indeterminate")
        # 처음엔 숨겨둠

        # ── 로그 ──
        ttk.Separator(self).pack(fill="x", padx=20, pady=(4, 0))

        tk.Label(self, text="로그", font=("System", 12, "bold")).pack(
            anchor="w", padx=20, pady=(8, 2)
        )

        self.log = scrolledtext.ScrolledText(
            self,
            font=("Menlo", 11),
            relief="solid",
            bd=1,
            state="disabled",
            wrap="word",
            height=12,
        )
        self.log.pack(fill="both", expand=True, padx=20, pady=(0, 16))

        self.log.tag_config("ok", foreground="#1a7f37")
        self.log.tag_config("err", foreground="#cf222e")
        self.log.tag_config("info", foreground="#0550ae")
        self.log.tag_config("plain")

    # ── 다운로드 ──────────────────────────────────────────────────────────────

    def _start_download(self):
        if self._running:
            return

        urls = [
            u.strip() for u in self.url_text.get("1.0", "end").splitlines() if u.strip()
        ]
        if not urls:
            self._append("⚠️  URL을 입력해 주세요.\n", "err")
            return

        self._running = True
        self.dl_btn.configure(state="disabled", text="다운로드 중…")
        self.progress.pack(fill="x", padx=20, pady=(0, 4))
        self.progress.start(10)
        self.progress_var.set(f"0 / {len(urls)} 처리 중…")

        download_urls(urls, self._log_queue, self._on_done)

    def _on_done(self, success: bool):
        self.after(0, self._finish_ui, success)

    def _finish_ui(self, success: bool):
        self.progress.stop()
        self.progress.pack_forget()
        self.dl_btn.configure(state="normal", text="⬇  다운로드")
        self._running = False
        if success:
            self.progress_var.set("✅ 완료! Apple Music을 확인하세요.")
            self._append(
                "\n🎉 모든 다운로드가 완료되었습니다! Apple Music을 확인하세요.\n", "ok"
            )
        else:
            self.progress_var.set("⚠️ 일부 실패 — 로그를 확인하세요.")
            self._append(
                "\n⚠️  일부 다운로드에 실패했습니다. 위 로그를 확인하세요.\n", "err"
            )

    def _clear_all(self):
        self.url_text.delete("1.0", "end")
        self.log.configure(state="normal")
        self.log.delete("1.0", "end")
        self.log.configure(state="disabled")
        self.progress_var.set("")

    # ── 로그 폴링 ─────────────────────────────────────────────────────────────

    def _poll_log(self):
        try:
            while True:
                line = self._log_queue.get_nowait()
                if line is None:
                    break
                self._append(line, self._tag(line))
        except queue.Empty:
            pass
        self.after(80, self._poll_log)

    @staticmethod
    def _tag(line: str) -> str:
        lo = line.lower()
        if "✅" in line or "[ffmpeg]" in lo:
            return "ok"
        if "❌" in line or "error" in lo or "⚠️" in line:
            return "err"
        if "▶" in line or "[download]" in lo or "[youtube]" in lo:
            return "info"
        return "plain"

    def _append(self, text: str, tag: str = "plain"):
        self.log.configure(state="normal")
        self.log.insert("end", text, tag)
        self.log.see("end")
        self.log.configure(state="disabled")


if __name__ == "__main__":
    app = App()
    app.mainloop()

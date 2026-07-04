# YouTube → Apple Music 변환기

YouTube 링크를 붙여넣으면 MP3로 변환 후 볼륨 정규화(loudnorm)를 적용하고
Apple Music 보관함에 자동으로 추가하는 macOS 앱입니다.

## 사전 준비

```bash
# yt-dlp 설치 (아직 없다면)
brew install yt-dlp

# ffmpeg 설치 (아직 없다면)
brew install ffmpeg
```

> tkinter는 macOS 시스템 Python(`/usr/bin/python3`)에 기본 포함되어 있어  
> 별도 설치 없이 `run.sh`로 실행 가능합니다.

## 실행

```bash
cd ~/Desktop/youtube_converter
bash run.sh
```

또는 Finder에서 `run.sh`를 우클릭 → "터미널로 열기"

## 사용법

1. URL 입력창에 YouTube 링크를 붙여넣습니다.
2. 여러 곡은 줄 바꿔서 입력하세요.
3. **⬇ 다운로드** 버튼을 클릭합니다.
4. 로그 창에서 진행 상황을 확인합니다.
5. 완료되면 Apple Music 앱을 열면 곡이 추가되어 있습니다.

## 처리 과정

- 오디오 추출: `-x --audio-format mp3 --audio-quality 0`
- 볼륨 정규화: `loudnorm=I=-14:TP=-1:LRA=11` (Spotify/Apple Music 기준)
- 임시 파일: `~/Desktop` (처리 후 자동 삭제)
- 최종 저장: `~/Music/Music/Media.localized/Automatically Add to Music.localized`

## 파일 구조

```
youtube_converter/
├── app.py          # GUI (tkinter)
├── downloader.py   # yt-dlp subprocess 래퍼
├── run.sh          # 실행 스크립트
└── README.md
```

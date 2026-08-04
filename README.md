# YTConverter

YouTube 링크를 붙여넣으면 MP3로 변환, 볼륨 정규화(-14 LUFS), 제목·가수 메타데이터 태깅 후 Apple Music 보관함에 자동 추가하는 macOS 앱입니다.

## 사전 준비

```bash
brew install yt-dlp ffmpeg
```

## 실행

```bash
open ~/Library/Developer/Xcode/DerivedData/YTConverter-*/Build/Products/Debug/YTConverter.app
```

또는 Xcode에서 `YTConverter.xcodeproj` 열고 **⌘R**

## Applications 폴더에 설치 (한 번만)

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/YTConverter-*/Build/Products/Debug/YTConverter.app /Applications/
```

이후에는 Spotlight(⌘Space)에서 `YTConverter` 검색으로 바로 실행 가능

## 사용법

1. YouTube URL 입력
2. 제목·가수 입력 (비워두면 YouTube 정보 사용)
3. **다운로드** 클릭
4. 완료되면 Apple Music 보관함에 자동 추가됨

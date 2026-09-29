# YTConverter

YouTube 링크를 붙여넣으면 MP3로 변환, 볼륨 정규화(-14 LUFS), 제목·가수 메타데이터 태깅 후 Apple Music 보관함에 자동 추가하는 macOS 앱입니다.

## 사전 준비

```bash
brew install yt-dlp ffmpeg
```

YouTube가 403 등으로 막히면 **Chrome**에서 youtube.com에 로그인해 두면 앱이 Chrome 쿠키로 우회합니다. (Safari 쿠키는 macOS 보안상 앱에서 읽지 못하는 경우가 많습니다.)

## 빌드·설치

프로젝트 루트에서 한 번 실행하면 빌드 후 **`/Applications/YTConverter.app` 하나만** 설치됩니다. (예전 DerivedData 경로의 복사본은 제거되어 Finder/Spotlight에 앱이 두 개 보이지 않습니다.)

```bash
./scripts/build-and-install.sh
```

Xcode에서 개발할 때는 **⌘R** 로 실행해도 되지만, Spotlight로 실행할 앱은 위 스크립트로 `/Applications`에 맞춰 두는 것을 권장합니다.

## 사용법

1. YouTube URL 입력
2. 제목·가수 입력 (비워두면 YouTube 정보 사용)
3. **다운로드** 클릭
4. 완료되면 Apple Music 보관함에 자동 추가됨

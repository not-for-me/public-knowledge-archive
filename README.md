# Woojin's Public Knowledge Archive

> Second Brain에서 증류된 공개 지식 저장소입니다.
>
> 주제: 소프트웨어 엔지니어링, AI, 데이터, 시스템 설계, 독서 노트
>
> 원본은 개인 Obsidian Vault(Second Brain)에서 관리됩니다.

---

## 📚 LLM Wiki

공개 가능한 지식을 Concepts / Comparisons / Templates 형태로 정리합니다.
개인 Second Brain → public 이 저장소로 증류하는 구조입니다.

## 🛠️ SDLC Harness (`sdlc-kit/`)

AI 코딩 어시스턴트(Claude Code, Codex)를 위한 SDLC 하네스입니다.
6개의 전문 서브 에이전트 + 9개 SDLC 도메인 모듈로 구성된 2-Tier lazy 로딩 시스템입니다.

### 설치

```bash
# git clone
git clone https://github.com/not-for-me/public-knowledge-archive.git
bash public-knowledge-archive/sdlc-kit/scripts/install.sh

# 또는 curl-pipe (git clone 없이)
curl -sL https://raw.githubusercontent.com/not-for-me/public-knowledge-archive/main/sdlc-kit/scripts/install.sh | bash
```

### 구성

| 디렉토리 | 내용 |
|----------|------|
| `sdlc-kit/AGENTS.md` | 36줄 디스패치 허브 (항상 로드) |
| `sdlc-kit/agents/` | 6개 전문 에이전트 (`@mention`시 lazy 로드) |
| `sdlc-kit/modules/` | 9개 SDLC 도메인 상세 문서 |
| `sdlc-kit/rules/` | 2개 상시 규칙 (클린코드, Git 관례) |
| `sdlc-kit/scripts/install.sh` | 머신 설치 스크립트 (symlink + @import) |
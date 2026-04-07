# Environment & Filesystem Rules

## Filesystem / Runtime Policy

- 寫入權限以「當前 runtime 實測結果」為準，不以固定磁碟路徑假設。
- 若工作目錄不可寫，改寫入 `output/` 或使用者指定可寫目錄。
- 涉及 Web Root 相對路徑時，先明確說明路徑基準再落檔。

## WSL / Windows Filesystem 限制

> 專案位於 WSL DrvFs 掛載的 Windows NTFS 磁碟，以下規範強制適用。

- **git 狀態查詢**：禁用 `git status --short --ignore-submodules`，
  改用 `git status --short`
  （`--ignore-submodules` 在 DrvFs 觸發大量 inotify，導致指令卡住）

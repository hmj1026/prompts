# doc-reviewer 本地規則（zdpos）

dhpk `doc-reviewer` 審查時，若本檔存在就載入。在 checklist 之外，再套用下列規則。

## 維運 playbook 的實證

範圍：`docs/operations/playbooks/**`，包含 docs repo `/home/paul/projects/zdpos-217-docs/docs/operations/playbooks/**`。

- 每個「預期」都要能追到實證。實證是「實測日期＋環境」（例如「2026-10-28 本機 php:8.4-fpm 實測」），或同一節裡跑得出該結果的探針命令。找不到的列 MEDIUM，修改建議寫「補實測，或標『推測』」。
- 描述主機現況的句子（目錄內容、symlink 指向、規則涵蓋範圍、ini 值）要有查證日期，或指向 `zdpos-environment` skill 的 `references/dev-web-topology.md` 探針。沒有的列 MEDIUM。
- 宣稱某條規則「會保護／會擋住」某路徑時，核對規則的 regex 是否真的命中那個路徑。例如 `^/upload/` 只命中根目錄，不涵蓋 `/{site}/upload/`。不符的列 HIGH。

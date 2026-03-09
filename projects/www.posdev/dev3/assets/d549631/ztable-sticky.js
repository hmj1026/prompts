/**
 * 動態抓取 thead 欄位名稱產生下拉選單，讓使用者可選擇要「固定到哪一欄」
 */
class ZdnStickyTable {
    constructor(tableEl) {
        this.table = tableEl;
        this.root = tableEl.closest('.zdn-table');
        this.columns = this._getHeaderTitles();
        this.panel = null;
        this.prevCount = 0; // 上一次固定欄位數
        this.colWidths = []; // 儲存欄位寬度

        this._createControlPanel();
        this._bindEvents();
    }

    /** 取得 table **/
    getTable() {
        return this.root.querySelector('.zdn-table-inner');
    }

    /** 取得 thead 欄位標題文字 */
    _getHeaderTitles() {
        const headers = Array.from(this.table.querySelectorAll('thead th'));
        return headers.map(th => th.textContent.trim() || '(未命名欄位)');
    }

    /** 清除所有 sticky 狀態與樣式 */
    clearSticky() {
        const stickyCells = this.getTable().querySelectorAll('.is-sticky');
        stickyCells.forEach(el => {
            el.classList.remove('is-sticky');
            el.style.left = '';
            el.style.zIndex = '';
        });
    }

    /** 計算欄位寬度，只計算表頭一次 */
    _computeColWidths(count) {
        const headerCells = Array.from(this.getTable().querySelectorAll('thead th')).slice(0, count);
        this.colWidths = headerCells.map(th => th.offsetWidth);
    }

    /** 設定要固定到第 count 欄 */
    freezeColumns(count, enforce = false) {
        const oldCount = this.prevCount;
        this.prevCount = count;

        // 無變化直接跳過
        if (!enforce && oldCount === count) return;

        this._computeColWidths(count);

        // 為避免 race condition：先同步清除再重新套用
        this.clearSticky();

        const rows = Array.from(this.getTable().querySelectorAll('tr'));

        requestAnimationFrame(() => {
            rows.forEach(row => {
                let leftOffset = 0;
                const cells = row.children;
                for (let i = 0; i < count; i++) {
                    const cell = cells[i];
                    if (!cell) break;
                    cell.classList.add('is-sticky');
                    cell.style.left = leftOffset + 'px';
                    cell.style.zIndex = row.parentElement.tagName === 'THEAD' ? 5 : 4;
                    leftOffset += this.colWidths[i];
                }
            });
        });
    }

    /** 建立控制介面（從 thead 欄位生成） */
    _createControlPanel() {
        const container = document.createElement('div');
        container.className = 'zdn-sticky-panel';
        container.style.cssText = `
      display:flex;
      align-items:center;
      gap:6px;      
      color:#fff;
      padding:6px 10px;
      border-radius:6px;
      font-size:13px;
      margin:6px 0;
    `;

        const select = document.createElement('select');
        select.innerHTML = `<option value="0">固定欄位至</option>`;
        this.columns.forEach((title, i) => {
            const opt = document.createElement('option');
            opt.value = i + 1;
            opt.textContent = `${i + 1}. ${title}`;
            select.appendChild(opt);
        });

        // container.appendChild(label);
        container.appendChild(select);
        $('#zdn-table-sticky-panel').prepend(container);
        this.panel = select;
    }

    /** 綁定選單事件與 resize */
    _bindEvents() {
        this.panel.addEventListener('change', () => {
            const count = parseInt(this.panel.value, 10);
            this.freezeColumns(count);
        });

        window.addEventListener('resize', () => {
            const count = parseInt(this.panel.value, 10);
            this.freezeColumns(count);
        });
    }
}

/* === 初始化所有表格 === */
document.addEventListener('DOMContentLoaded', () => {
    const zdnStickyTable = new ZdnStickyTable(document.querySelector('.zdn-table-inner'));
    document.body.addEventListener('RefreshZdnfreezeColumn', () => {
        if (!!zdnStickyTable.prevCount) {
            zdnStickyTable.freezeColumns(zdnStickyTable.prevCount, true);
        }
    });
});

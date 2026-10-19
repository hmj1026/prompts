#!/usr/bin/env node
/**
 * validate_headless.js (zdpos-doc-studio 統一無頭瀏覽器互動與視覺驗收門禁)
 * 同時支援「協作者技術手冊 (docs/collaborators/<slug>/index.html)」與
 * 「QA 手動測試手冊 (docs/qa/<module>/QA-<slug>-manual.html)」。
 *
 * 驗證項目：
 * 1. 頁面載入零 Console Error / 未捕獲 PageError
 * 2. 初始零狀態 (0 個 checked radio、進度條 0%)
 * 3. Mermaid 圖表 100% 預渲染為 <svg>、純白畫布 (#ffffff)、零語法錯誤
 * 4. Mermaid <foreignObject> 盒模型零文字裁切 (div 寬高不得超出 foreignObject)
 * 5. Radio 互動：點選 Pass -> 切換 Fail -> 再次點擊取消選取 (Toggle Uncheck) -> 單題重置
 * 6. 匯出檢核紀錄視窗 (TSV 與 Markdown 即時同步) 與清空重填確認視窗
 * 7. Mermaid 縮放工具列與全螢幕互動燈箱 (#mermaid-lightbox-modal 開啟、保留有效 ID、非全黑填色、關閉)
 */

const fs = require('fs');
const path = require('path');

let playwright;
try {
  playwright = require('playwright');
} catch (e) {
  try {
    const projectRoot = path.resolve(__dirname, '../../../../');
    const resolved = require.resolve('playwright', { paths: [projectRoot, process.cwd()] });
    playwright = require(resolved);
  } catch (err) {
    console.warn('⚠️ [SKIP] 未找到 playwright 套件，略過無頭瀏覽器驗證。');
    process.exit(0);
  }
}

const { chromium } = playwright;

async function verifyHtmlFile(filePath, browserInstance) {
  const absPath = path.resolve(filePath);
  if (!fs.existsSync(absPath)) {
    console.error(`❌ 檔案不存在: ${absPath}`);
    return false;
  }

  let ownBrowser = false;
  let browser = browserInstance;
  if (!browser) {
    browser = await chromium.launch({ headless: true });
    ownBrowser = true;
  }

  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();

  const consoleErrors = [];
  const pageErrors = [];

  page.on('console', msg => {
    if (msg.type() === 'error') {
      const text = msg.text();
      if (!text.includes('favicon.ico') && !text.includes('ERR_FILE_NOT_FOUND')) {
        consoleErrors.push(text);
      }
    }
  });

  page.on('pageerror', err => {
    pageErrors.push(err.message || String(err));
  });

  const errors = [];

  try {
    const fileUrl = 'file://' + absPath;
    await page.goto(fileUrl, { waitUntil: 'domcontentloaded', timeout: 25000 });
    await page.evaluate(() => {
      try { localStorage.clear(); } catch (e) {}
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(120);

    // 1. 檢查初始零狀態、Mermaid 預渲染 SVG 與 foreignObject 零裁切
    const initAudit = await page.evaluate(() => {
      const issues = [];
      const cards = document.querySelectorAll('.tc-card[data-tc-id], details.tc, details.case');
      if (cards.length === 0) {
        issues.push('頁面上找不到任何互動式檢核/測試案例卡片 (.tc-card[data-tc-id] 或 details.tc)');
        return { issues, cardCount: 0, mermaidCount: 0 };
      }

      const checkedRadios = document.querySelectorAll('input[type="radio"]:checked');
      if (checkedRadios.length > 0) {
        issues.push(`初始零狀態違規！未操作前已有 ${checkedRadios.length} 個 radio 處於 checked 狀態。`);
      }

      const progressFill = document.querySelector('#progress-bar-fill, #progress-fill, #barfill');
      const progressText = document.querySelector('#progress-text, #done');
      if (!progressFill || !progressText) {
        issues.push('缺少頂部進度條元素 (#progress-bar-fill / #progress-fill / #progress-text)');
      } else {
        const w = progressFill.style.width;
        if (w && w !== '0%' && w !== '0px') {
          issues.push(`初始進度條寬度不為 0% (實際為: ${w})`);
        }
      }

      const rawPre = document.querySelectorAll('pre.mermaid:not([data-processed="true"])');
      if (rawPre.length > 0) {
        issues.push(`發現 ${rawPre.length} 個未渲染的 <pre class="mermaid"> 純文字區塊！`);
      }

      const mermaidContainers = document.querySelectorAll('.mermaid, .mermaid-diagram');
      mermaidContainers.forEach((el, idx) => {
        const svg = el.tagName.toLowerCase() === 'svg' ? el : el.querySelector('svg');
        if (!svg) {
          issues.push(`Mermaid 容器 #${idx + 1} 內未找到預渲染 <svg> 節點！`);
          return;
        }
        const svgText = svg.textContent || '';
        if (
          svgText.includes('Syntax error in text') ||
          svgText.includes('mermaid version') ||
          svg.querySelector('.error-icon, .error-text')
        ) {
          issues.push(`Mermaid 圖表 #${idx + 1} 發生語法錯誤 (Syntax error in text)！`);
        }
        const rect = svg.getBoundingClientRect();
        if (rect.width < 20 || rect.height < 15) {
          issues.push(`Mermaid 圖表 #${idx + 1} 渲染尺寸異常過小 (${Math.round(rect.width)}x${Math.round(rect.height)})`);
        }
        const host = el.closest('.mermaid-container') || el;
        const bg = window.getComputedStyle(host).backgroundColor;
        if (bg !== 'rgb(255, 255, 255)') {
          issues.push(`Mermaid 圖表 #${idx + 1} 背景色不是純白 #ffffff (實際為 ${bg})`);
        }

        const fos = svg.querySelectorAll('foreignObject');
        for (let f = 0; f < fos.length; f++) {
          const fo = fos[f];
          const div = fo.querySelector('div');
          if (!div || !div.textContent.trim()) continue;
          const foR = fo.getBoundingClientRect();
          const divR = div.getBoundingClientRect();
          if (divR.height > foR.height + 2.5 || divR.width > foR.width + 2.5) {
            issues.push(
              `Mermaid 圖表 #${idx + 1} 節點文字遭裁切 ("${div.textContent.trim().slice(0, 24)}"): div(${Math.round(divR.width)}x${Math.round(divR.height)}) > foreignObject(${Math.round(foR.width)}x${Math.round(foR.height)})`
            );
            break;
          }
        }
      });

      return { issues, cardCount: cards.length, mermaidCount: mermaidContainers.length };
    });

    if (initAudit.issues.length > 0) {
      errors.push(...initAudit.issues);
    }

    // 2. 測試互動行為：Radio 點選 -> 切換 -> 再次點擊取消選取 (Toggle Uncheck) -> 單題重置 -> 匯出 TSV/MD -> 清空重填 -> 全螢幕燈箱
    if (initAudit.cardCount > 0) {
      const interactionIssues = await page.evaluate(async () => {
        const issues = [];
        const firstCard = document.querySelector('.tc-card[data-tc-id], details.tc, details.case');
        if (firstCard.tagName.toLowerCase() === 'details') {
          firstCard.open = true;
        }

        const passRadio = firstCard.querySelector('input[type="radio"][value="Pass"]');
        const failRadio = firstCard.querySelector('input[type="radio"][value="Fail"]');
        const blockedRadio = firstCard.querySelector('input[type="radio"][value="Blocked"]');
        const clearBtn = firstCard.querySelector('[data-reset-tc], .tc-reset-btn, .btn-clear-verdict, .rbtn-clear');
        const pill = firstCard.querySelector('.tc-status-badge, .pill-status, [data-pill]');

        if (!passRadio || !failRadio || !blockedRadio) {
          issues.push('第一張檢核/測試卡片缺少 Pass / Fail / Blocked 單選按鈕');
          return issues;
        }

        // (a) 點選 Pass
        const passLabel = passRadio.closest('label') || passRadio;
        passLabel.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        passLabel.click();
        await new Promise(r => setTimeout(r, 30));
        if (!passRadio.checked) {
          issues.push('點擊 Pass 單選框後，passRadio.checked 未變為 true');
        }
        if (pill && pill.textContent.trim() !== 'Pass') {
          issues.push(`點擊 Pass 後，卡片狀態標籤未更新為 Pass (實際為: ${pill.textContent.trim()})`);
        }

        // (b) 切換點選 Fail
        const failLabel = failRadio.closest('label') || failRadio;
        failLabel.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        failLabel.click();
        await new Promise(r => setTimeout(r, 30));
        if (!failRadio.checked || passRadio.checked) {
          issues.push('切換點擊 Fail 後，單選框互斥狀態異常');
        }

        // (c) 再次點擊已選中之 Fail 測試 Toggle 取消選中
        failLabel.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        failLabel.click();
        await new Promise(r => setTimeout(r, 30));
        if (failRadio.checked) {
          issues.push('再次點擊已選中的 Fail 單選框時，未能取消選取 (Toggle Uncheck 失效)');
        }

        // (d) 點選 Blocked 後按單題重置按鈕
        const blockedLabel = blockedRadio.closest('label') || blockedRadio;
        blockedLabel.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        blockedLabel.click();
        await new Promise(r => setTimeout(r, 30));
        if (!blockedRadio.checked) {
          issues.push('點擊 Blocked 單選框後未選中');
        }
        if (!clearBtn) {
          issues.push('找不到單一檢核項之重置按鈕 ([data-reset-tc] / .btn-clear-verdict)');
        } else {
          clearBtn.click();
          await new Promise(r => setTimeout(r, 30));
          const anyChecked = firstCard.querySelectorAll('input[type="radio"]:checked').length;
          if (anyChecked > 0) {
            issues.push(`點擊單一項目重置按鈕後，仍有 ${anyChecked} 個 radio 處於選中狀態`);
          }
        }

        // (e) 測試匯出視窗 (Export Modal)
        passLabel.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        passLabel.click();
        const noteArea = firstCard.querySelector('.tc-note-input, .result-input, [data-note]');
        if (noteArea) {
          noteArea.value = 'Playwright 自動化驗收備註';
          noteArea.dispatchEvent(new Event('input', { bubbles: true }));
        }
        await new Promise(r => setTimeout(r, 30));

        const exportBtn = document.querySelector('#btn-open-export, #export-btn, #exportBtn');
        const exportModal = document.querySelector('#export-modal, #exportModal');
        const exportTextarea = document.querySelector('#export-output, #export-textarea, #exportText');
        const tabMd = document.querySelector('#tab-btn-md, #tab-md, #tabMd');
        const closeExportBtn = document.querySelector('#close-export-btn, #closeExportBtn, #export-modal-close, #exportModalClose');

        if (!exportBtn || !exportModal || !exportTextarea) {
          issues.push('缺少匯出按鈕或匯出視窗元素');
        } else {
          exportBtn.click();
          await new Promise(r => setTimeout(r, 30));
          if (!exportModal.classList.contains('open') && (exportModal.classList.contains('hidden') || exportModal.classList.contains('hide'))) {
            issues.push('點擊匯出按鈕後，匯出視窗未開啟');
          }
          if (!exportTextarea.value.includes('Pass') || !exportTextarea.value.includes('Playwright 自動化驗收備註')) {
            issues.push('匯出視窗 TSV 內容未即時反映剛點選之 Pass 狀態與備註文字');
          }
          if (tabMd) {
            tabMd.click();
            await new Promise(r => setTimeout(r, 30));
            if (!exportTextarea.value.includes('|') || !exportTextarea.value.includes('Playwright 自動化驗收備註')) {
              issues.push('切換至 Markdown 匯出分頁後，未產生有效之 Markdown 簽核表格');
            }
          }
          if (closeExportBtn) {
            closeExportBtn.click();
            await new Promise(r => setTimeout(r, 30));
          } else if (window.DOC_APP && window.DOC_APP.closeExportModal) {
            window.DOC_APP.closeExportModal();
          }
        }

        // (f) 測試清空全部紀錄按鈕與確認視窗
        const resetBtn = document.querySelector('#btn-open-clear, #reset-all-btn, #resetBtn');
        const resetModal = document.querySelector('#clear-modal, #reset-modal, #resetModal');
        const confirmResetBtn = document.querySelector('#btn-confirm-clear, #confirm-reset-btn, #confirmResetBtn');

        if (!resetBtn || !resetModal || !confirmResetBtn) {
          issues.push('缺少清空重填按鈕或確認視窗元素');
        } else {
          resetBtn.click();
          await new Promise(r => setTimeout(r, 30));
          confirmResetBtn.click();
          await new Promise(r => setTimeout(r, 30));
          const remainingChecked = document.querySelectorAll('.tc-card input[type="radio"]:checked, details.tc input[type="radio"]:checked, details.case input[type="radio"]:checked').length;
          if (remainingChecked > 0) {
            issues.push(`執行確定清空後，頁面上仍有 ${remainingChecked} 個已選中之 radio 未被清除`);
          }
          if (noteArea && noteArea.value !== '') {
            issues.push('執行確定清空後，備註文字框未被清空');
          }
        }

        // (g) 測試 Mermaid 圖表縮放工具列與全螢幕互動燈箱
        const firstMermaid = document.querySelector('.mermaid-container, .mermaid');
        if (firstMermaid && firstMermaid.querySelector('svg')) {
          const fsBtn = firstMermaid.querySelector('button[data-m-act="fullscreen"]');
          const zoomInBtn = firstMermaid.querySelector('button[data-m-act="zoom-in"]');
          const lbModal = document.querySelector('#mermaid-lightbox-modal');
          const lbClose = document.querySelector('#lightbox-close');
          if (!fsBtn || !zoomInBtn || !lbModal || !lbClose) {
            issues.push('Mermaid 圖表缺少互動式縮放工具列按鈕或全螢幕檢視燈箱 (#mermaid-lightbox-modal)');
          } else {
            fsBtn.click();
            await new Promise(r => setTimeout(r, 30));
            if (!lbModal.classList.contains('open')) {
              issues.push('點擊 Mermaid [⛶ 全螢幕檢視] 按鈕後，燈箱未開啟');
            }
            const lbSvg = lbModal.querySelector('#mermaid-lightbox-stage svg');
            if (!lbSvg) {
              issues.push('Mermaid 全螢幕燈箱內未載入克隆之 <svg> 圖表');
            } else {
              if (!lbSvg.id) {
                issues.push('Mermaid 全螢幕燈箱內 <svg> 遺失 id 屬性，將導致內部 <style> 失效變為全黑！');
              }
              const sampleShape = lbSvg.querySelector('.node rect, .cluster rect, .actor');
              if (sampleShape) {
                const fillColor = window.getComputedStyle(sampleShape).fill;
                if (fillColor === 'rgb(0, 0, 0)') {
                  issues.push('Mermaid 全螢幕燈箱內節點發生全黑填色異常 (fill: rgb(0, 0, 0))！');
                }
              }
            }
            lbClose.click();
            await new Promise(r => setTimeout(r, 30));
            if (lbModal.classList.contains('open')) {
              issues.push('點擊 Mermaid 全螢幕燈箱 [✕ 關閉] 後未正常關閉');
            }
          }
        }

        return issues;
      });

      if (interactionIssues.length > 0) {
        errors.push(...interactionIssues);
      }
    }
  } catch (err) {
    errors.push(`頁面載入或互動驗證失敗: ${err.message}`);
  } finally {
    await context.close();
    if (ownBrowser) {
      await browser.close();
    }
  }

  if (consoleErrors.length > 0) {
    errors.push(`捕獲到 ${consoleErrors.length} 個 Console Error: ${consoleErrors.join(' | ')}`);
  }
  if (pageErrors.length > 0) {
    errors.push(`捕獲到 ${pageErrors.length} 個未捕獲 JS PageError: ${pageErrors.join(' | ')}`);
  }

  if (errors.length > 0) {
    console.error(`❌ [Headless 瀏覽器驗證失敗] ${filePath}`);
    errors.forEach(e => console.error(`   - ${e}`));
    return false;
  } else {
    console.log(`✅ [Headless 瀏覽器驗證通過] ${path.relative(process.cwd(), absPath)} (零狀態、Mermaid 防裁切與燈箱、Radio 單選/Toggle 取消、匯出與清空皆 100% 正常)`);
    return true;
  }
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.error('用法: node validate_headless.js <file_or_dir1> [file_or_dir2 ...]');
    process.exit(1);
  }

  const browser = await chromium.launch({ headless: true });
  let allPassed = true;
  try {
    for (const arg of args) {
      const stat = fs.statSync(arg);
      if (stat.isDirectory()) {
        const rootAbs = path.resolve(arg);
        const walk = dir => {
          let results = [];
          for (const f of fs.readdirSync(dir)) {
            const full = path.join(dir, f);
            if (fs.statSync(full).isDirectory()) {
              results = results.concat(walk(full));
            } else if (
              (f === 'index.html' && path.resolve(dir) !== path.resolve('docs/collaborators')) ||
              (f.startsWith('QA-') && f.endsWith('-manual.html'))
            ) {
              results.push(full);
            }
          }
          return results;
        };
        for (const f of walk(rootAbs).sort()) {
          const ok = await verifyHtmlFile(f, browser);
          if (!ok) allPassed = false;
        }
      } else {
        const ok = await verifyHtmlFile(arg, browser);
        if (!ok) allPassed = false;
      }
    }
  } finally {
    await browser.close();
  }

  process.exit(allPassed ? 0 : 1);
}

main();

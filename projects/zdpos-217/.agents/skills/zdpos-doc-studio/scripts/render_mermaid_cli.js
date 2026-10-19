#!/usr/bin/env node
/**
 * render_mermaid_cli.js
 * 透過本機 Playwright 將 Mermaid 程式碼預先渲染為獨立高對比原生 SVG，
 * 實現 QA 手動手冊 100% 離線可用、零 CDN 依賴、即開即顯，徹底杜絕圖表退化為純文字或縮放失真。
 *
 * 用法:
 *   node render_mermaid_cli.js <path_to_mermaid_code_file>
 *   node render_mermaid_cli.js --batch <in_json_path> <out_json_path>
 *   或透過 stdin 管道輸入單一 Mermaid 語法
 */

const path = require('path');
const fs = require('fs');

let playwright;
try {
  playwright = require('playwright');
} catch (e) {
  try {
    const projectRoot = path.resolve(__dirname, '../../../../');
    const resolved = require.resolve('playwright', { paths: [projectRoot, process.cwd()] });
    playwright = require(resolved);
  } catch (err) {
    console.error('❌ 未找到 playwright 套件。');
    process.exit(2);
  }
}

const { chromium } = playwright;

/**
 * 在瀏覽器環境內將多筆或單筆 Mermaid 語法渲染為高對比 SVG
 * @param {string[]} codes
 */
async function renderBatchToSvg(codes) {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

  const localMermaidPath = path.resolve(__dirname, '../resources/mermaid.min.js');
  const basePageHtml = `<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
    body, #container, svg, foreignObject, foreignObject div, foreignObject span {
      margin: 0;
      line-height: 1.4 !important;
      font-size: 14px !important;
      font-family: "Noto Sans TC", "PingFang TC", "Microsoft JhengHei", system-ui, -apple-system, sans-serif !important;
    }
    .nodeLabel:not(:empty), .edgeLabel:not(:empty), .cluster-label span:not(:empty) {
      display: inline-block !important;
      padding: 3px 8px !important;
      line-height: 1.4 !important;
      box-sizing: border-box !important;
    }
  </style></head><body><div id="container"></div></body></html>`;

  if (fs.existsSync(localMermaidPath)) {
    await page.setContent(basePageHtml);
    await page.addScriptTag({ path: localMermaidPath });
  } else {
    await page.setContent(basePageHtml.replace('</head>', '<script src="https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"></script></head>'), { waitUntil: 'load', timeout: 25000 });
  }

  const results = await page.evaluate(async (mermaidList) => {
    mermaid.initialize({
      startOnLoad: false,
      theme: 'base',
      securityLevel: 'loose',
      fontFamily: '"Noto Sans TC", "PingFang TC", "Microsoft JhengHei", system-ui, -apple-system, sans-serif',
      themeVariables: {
        background: '#ffffff',
        primaryColor: '#eff6ff',
        primaryTextColor: '#0f172a',
        primaryBorderColor: '#2563eb',
        lineColor: '#334155',
        secondaryColor: '#f0fdf4',
        secondaryTextColor: '#0f172a',
        secondaryBorderColor: '#16a34a',
        tertiaryColor: '#fffbeb',
        tertiaryTextColor: '#0f172a',
        tertiaryBorderColor: '#d97706',
        clusterBkg: '#f8fafc',
        clusterBorder: '#475569',
        titleColor: '#0f172a',
        edgeLabelBackground: '#ffffff',
        actorBkg: '#eff6ff',
        actorBorder: '#2563eb',
        actorTextColor: '#0f172a',
        actorLineColor: '#334155',
        signalColor: '#0f172a',
        signalTextColor: '#0f172a',
        labelBoxBkgColor: '#f8fafc',
        labelBoxBorderColor: '#475569',
        labelTextColor: '#0f172a',
        loopTextColor: '#0f172a',
        noteBkgColor: '#fef9c3',
        noteTextColor: '#0f172a',
        noteBorderColor: '#ca8a04',
        fontSize: '14px'
      },
      flowchart: { useMaxWidth: true, htmlLabels: true, curve: 'basis', padding: 16, nodeSpacing: 45, rankSpacing: 55 },
      sequence: { useMaxWidth: true, wrap: true, messageMargin: 36, boxMargin: 10 }
    });

    const liveContainer = document.getElementById('container');
    const out = [];
    for (let i = 0; i < mermaidList.length; i++) {
      const mermaidText = mermaidList[i];
      try {
        const id = 'mermaid_svg_' + i + '_' + Math.random().toString(36).slice(2, 8);
        const { svg } = await mermaid.render(id, mermaidText);

        // 掛載至真實 DOM 以校正 foreignObject 盒模型並設定最佳高對比顯示尺寸
        liveContainer.innerHTML = svg;
        const svgEl = liveContainer.querySelector('svg');
        if (svgEl) {
          const styleEl = svgEl.querySelector('style');
          if (styleEl) {
            styleEl.textContent +=
              ` #${id} foreignObject { overflow: visible !important; }` +
              ` #${id} foreignObject div, #${id} foreignObject span, #${id} .nodeLabel, #${id} .edgeLabel, #${id} .cluster-label { line-height: 1.35 !important; font-size: 14px !important; box-sizing: border-box !important; }`;
          }

          const fos = svgEl.querySelectorAll('foreignObject');
          for (let f = 0; f < fos.length; f++) {
            const fo = fos[f];
            fo.setAttribute('overflow', 'visible');
            fo.style.overflow = 'visible';
            const div = fo.querySelector('div');
            if (!div) continue;
            const foW = parseFloat(fo.getAttribute('width') || '0');
            const foH = parseFloat(fo.getAttribute('height') || '0');
            const scrollW = Math.ceil(div.scrollWidth || 0);
            const scrollH = Math.ceil(div.scrollHeight || 0);
            if (foW > 0 && scrollW > foW) {
              const newW = scrollW + 8;
              const dw = newW - foW;
              fo.setAttribute('width', String(newW));
              const labelG = fo.closest('g.label');
              if (labelG && labelG.getAttribute('transform')) {
                const m = labelG.getAttribute('transform').match(/translate\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)/);
                if (m) {
                  labelG.setAttribute('transform', `translate(${parseFloat(m[1]) - dw / 2}, ${parseFloat(m[2])})`);
                }
              }
              const nodeG = fo.closest('g.node');
              const rect = nodeG ? nodeG.querySelector('rect.label-container') : null;
              if (rect) {
                const rw = parseFloat(rect.getAttribute('width') || '0');
                const rx = parseFloat(rect.getAttribute('x') || '0');
                if (rw > 0 && rw < newW + 16) {
                  const nextRw = newW + 16;
                  rect.setAttribute('width', String(nextRw));
                  rect.setAttribute('x', String(rx - (nextRw - rw) / 2));
                }
              }
            }
            if (foH > 0 && scrollH > foH) {
              const newH = scrollH + 4;
              const dh = newH - foH;
              fo.setAttribute('height', String(newH));
              const labelG = fo.closest('g.label');
              if (labelG && labelG.getAttribute('transform')) {
                const m = labelG.getAttribute('transform').match(/translate\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)/);
                if (m) {
                  labelG.setAttribute('transform', `translate(${parseFloat(m[1])}, ${parseFloat(m[2]) - dh / 2})`);
                }
              }
              const nodeG = fo.closest('g.node');
              const rect = nodeG ? nodeG.querySelector('rect.label-container') : null;
              if (rect) {
                const rh = parseFloat(rect.getAttribute('height') || '0');
                const ry = parseFloat(rect.getAttribute('y') || '0');
                if (rh > 0 && rh < newH + 14) {
                  const nextRh = newH + 14;
                  rect.setAttribute('height', String(nextRh));
                  rect.setAttribute('y', String(ry - (nextRh - rh) / 2));
                }
              }
            }
          }

          const vb = svgEl.getAttribute('viewBox');
          if (vb) {
            const parts = vb.trim().split(/[\s,]+/).map(Number);
            if (parts.length === 4 && !isNaN(parts[2]) && parts[2] > 0) {
              const natWidth = Math.round(parts[2]);
              const natHeight = Math.round(parts[3] || 0);
              svgEl.setAttribute('data-natural-width', String(natWidth));
              if (natHeight > 0) {
                svgEl.setAttribute('data-natural-height', String(natHeight));
              }
              svgEl.style.maxWidth = Math.max(natWidth, 320) + 'px';
              svgEl.style.width = '100%';
              svgEl.style.height = 'auto';
              if (natWidth > 860) {
                svgEl.style.minWidth = Math.round(natWidth * 0.82) + 'px';
              } else {
                svgEl.style.minWidth = '0';
              }
            }
          }
          out.push({ success: true, svg: liveContainer.innerHTML });
        } else {
          out.push({ success: true, svg });
        }
      } catch (e) {
        out.push({ success: false, error: e && e.message ? e.message : String(e) });
      }
    }
    return out;
  }, codes);

  await browser.close();
  return results;
}

async function main() {
  const args = process.argv.slice(2);
  if (args[0] === '--batch' && args[1]) {
    const batchData = JSON.parse(fs.readFileSync(args[1], 'utf-8'));
    const results = await renderBatchToSvg(batchData);
    const jsonOut = JSON.stringify(results);
    if (args[2]) {
      fs.writeFileSync(args[2], jsonOut, 'utf-8');
    } else {
      fs.writeFileSync(1, jsonOut, 'utf-8');
    }
    return;
  }

  let inputCode = '';
  const inputFile = args[0];

  if (inputFile && fs.existsSync(inputFile)) {
    inputCode = fs.readFileSync(inputFile, 'utf-8');
  } else {
    inputCode = fs.readFileSync(0, 'utf-8');
  }

  inputCode = inputCode.trim();
  if (!inputCode) {
    console.error('❌ 輸入之 Mermaid 語法為空。');
    process.exitCode = 1;
    return;
  }

  const [res] = await renderBatchToSvg([inputCode]);
  if (res && res.success) {
    fs.writeFileSync(1, res.svg, 'utf-8');
  } else {
    console.error('❌ Mermaid 渲染失敗:', res ? res.error : '未知錯誤');
    process.exitCode = 1;
  }
}

main();

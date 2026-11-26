/**
 * POS 前台 QA 攔截器：瀏覽器內的請求過濾，送出前擋下不在允許範圍內的請求。
 * 用途：vm1 發票輸出是正式上傳佇列，QA 期間不可開票、折讓、補印發票，也不可作廢未核准的單。
 * 瀏覽器由 pos-guard.sh 以 eval 注入（可重複執行）；Node 由 pos-guard.test.js 載入 decide() 測試。
 *
 * 判斷順序（decide）：
 *   1. 讀不到內容的請求擋下。
 *   2. 路由含 delReceipt／delOrder：走作廢核准檢查（含 GET、?r=、Yii path 參數、大小寫、尾斜線）。
 *   3. 路由含 checkOut：一律擋（actionCheckOut 的 invoice_flag 寫死 true，del_flag 預設為作廢）。
 *   4. 非 GET、沒有 ajax 參數（或 login-form）且路由在明列清單內：放行。
 *   5. 帶 ajax 參數：依 doAjax 動作判斷（允許清單、get* 前綴、checkOut 的 invoice_flag、作廢核准）。
 *   6. 其餘非 GET（沒有 ajax 參數的 POST 等）：預設擋下。GET 頁面載入放行。
 *
 * 隔離站放行（isolated-ok）：只限 ISOLATED_SITES 內、發票寫隔離目錄且用 OO 測試字軌的站。由 pos-guard.sh isolated-ok 依主控核准
 * 檔登記；登記後該站的 splitBill* 動作（不含 splitBillWriteOff）、ajax checkOut（含開票）、清帳（cleardebt、cleardebt_complement）、
 * handleAllowance 放行；折讓事件（MakeAllowances、VoidedAllowances）仍需單號核准。一般作廢核准、/pos/checkOut 路由、發票類頁面導覽照原規則。頁面重載後攔截器狀態重建，須重新登記。
 *
 * 作廢核准：以單號登記，只涵蓋一般作廢（event 為空）。送出一次即消耗，同單號再送須重新核准。
 * 折讓事件（MakeAllowances、VoidedAllowances）與任何未知 event 一律擋，UAT 開折讓須另取使用者核准，不在本工具範圍。
 *
 * get* 前綴放行，但不保證全為純讀：getSalesTemp 會清桌並寫 data_table，getSaleNo 會清 sales_temp 的鎖欄。
 * 兩者不涉及發票與作廢，所以放行；其餘 get* 未逐一查證。
 *
 * 限制（攔截器只涵蓋目前頁面與同源 iframe 內的 XHR、fetch、sendBeacon、window.open、表單送出）：
 *   - window.open 開出的新視窗、整頁導覽（連結、location 指派）、重載後的空窗不在保護內。
 *   - 登入到第一次 pos-guard.sh 之間沒有保護。
 *   - 這是流程約束：核准檔與 ack 的使用規範靠流程遵守，程式不驗證呼叫者身分。
 */
(() => {
  'use strict';

  // doAjax 動作（PosController::doAjax）。新增放行前先讀該 case，確認不開票、不寫佇列。
  const ALLOWED = new Set([
    'ItemSpecSelectMode', 'LockEnterSales', 'addItem', 'autoRelateRemark', 'binTable', 'cards', 'cashBypassCheck',
    'checkCustomerNo', 'checkLock', 'checkLock_new', 'checkNeedPickupDate', 'checkReservation',
    'checkout_uplimit', 'cus_name_2nd', 'customer', 'customer2', 'customerMobile', 'customerPoint',
    'customer_new', 'customer_noa', 'customers', 'isExpired', 'item_amount_digit', 'items',
    'loadTableSeatsOrder', 'lockTable', 'openTransactionRecords', 'payments', 'pointExchangeAmount',
    'pos_image_preview_seconds', 'priceType', 'printTheReceipt', 'saveReceipt', 'saveReceipt_new',
    'schItemByInput', 'search_commission_receipts', 'serviceType', 'show_remark_img',
    'specsale_project_get', 'specsale_project_run', 'specsale_project_run2', 'specsale_switch',
    // 續單自動觸發；會依對帳結果更新拆帳狀態，但不開票
    'splitBillStatus',
    // 桌況 iframe（TableSeatsController::actionAjax）：checklock 純讀；ordering 只寫桌位與暫存單的鎖欄
    'checklock', 'ordering',
    'storeType', 'takeAwayServiceCheck', 'toCashSwitch', 'unlockTable',
    // 統編查公司抬頭：只呼叫財政部稅籍 API（FiaTaxTitleApiService），不開票、不寫單據
    'lookupTaxTitle',
  ]);
  // get* 前綴放行；見檔頭說明（getSalesTemp、getSaleNo 不是純讀）。
  const READ_PREFIX = /^get/;
  // 隔離站：發票 XML 寫隔離目錄（/var/glob-storage/invoices-sb84/）且字軌為 OO，見 docs repo release-26.11.8-php84-canary.md §2。
  // 新增站前須讀回該站 Glob.php 的 INVOICE_BASE_PATH 與字軌，確認不寫正式上傳佇列。
  // sb56：碼基 zdpos_218_sb，INVOICE_BASE_PATH=/var/glob-storage/invoices-sb218/（2026-11-26 讀回），DB 與 sb84 同為 zdpos_sb84（OO 字軌）。
  const ISOLATED_SITES = new Set(['sb84', 'sb56']);
  const ISOLATED_ACTION = /^splitbill(?!writeoff$)[a-z]+$/i;
  // 隔離站額外放行：清帳（含補清）與折讓處理。折讓事件仍經 delReceipt，須單號核准（void-ok）。
  const ISOLATED_EXTRA = new Set(['cleardebt', 'cleardebt_complement', 'handleallowance']);
  const ALLOWANCE_EVENTS = new Set(['MakeAllowances', 'VoidedAllowances']);
  const VOID_ACTION = /^(delreceipt|delorder)$/i;
  const VOID_ROUTES = new Set(['delreceipt', 'delorder']);
  // 非 GET 且沒有 ajax 參數時唯一放行的路由（取最後兩段，小寫）。逐一對照 v26.11.7.1：
  //   site/login：登入表單（SiteController::actionLogin）
  //   pos/get3PartyPaymentList、pos/getTotalPaymentList、pos/getTicketList：付款方式清單，只查 data_paytype
  //   pos/getRedeemType：兌換設定查詢，不寫單據
  //   tableSeats/scanOrderProcess：掃碼收單輪詢（OrderService::scanOrderProcess），會更新暫存單與列印旗標，不開票、不作廢
  const POST_ROUTES = new Set(['site/login', 'pos/get3partypaymentlist', 'pos/gettotalpaymentlist', 'pos/getticketlist', 'pos/getredeemtype', 'tableseats/scanorderprocess']);
  // window.open 與表單送出額外擋：發票、折讓、eiic 類頁面
  const NAV_BLOCKED = /invoice|allowance|eiic/i;

  const isReadMethod = (method) => method === 'GET' || method === 'HEAD';

  /** @returns {string} 空字串＝放行；否則為擋下原因（開頭是 action 或路徑名稱） */
  const decide = (request, approvals, isolated = '') => {
    const { method, path, action, data, unreadable } = request;
    if (unreadable) return path + ': unreadable body';
    const name = request.routeName;
    const onIsolated = ISOLATED_SITES.has(isolated) && request.site === isolated;

    if (request.segments.some((s) => VOID_ROUTES.has(s))) return voidRoute(request, approvals, onIsolated);
    if (request.segments.includes('checkout')) return name + ': checkOut route is always blocked';
    if (isReadMethod(method)) return '';
    // login-form 是 Yii 登入表單的 ajax 驗證，不是 doAjax 動作
    if ((!action || action === 'login-form') && POST_ROUTES.has(request.routeKey)) return '';
    if (!action) return name + ': non-ajax ' + method + ' not allowed';

    if (action.toLowerCase() === 'checkout') return onIsolated ? isolatedCheckOut(action, data) : checkOutRule(action, data);
    if (VOID_ACTION.test(action)) return voidDecision(action, voidOrderNo(data), data ? [data.event] : [], approvals, onIsolated);
    if (onIsolated && (ISOLATED_ACTION.test(action) || ISOLATED_EXTRA.has(action.toLowerCase()))) return '';
    return ALLOWED.has(action) || READ_PREFIX.test(action) ? '' : action + ': action not allowed';
  };

  /** 隔離站的 checkOut：允許開票，但 payload 必須可讀。 */
  const isolatedCheckOut = (action, data) =>
    (!data || typeof data.list !== 'object' || data.list === null ? action + ': payload unreadable' : '');

  const checkOutRule = (action, data) => {
    if (!data || typeof data.list !== 'object' || data.list === null) return action + ': payload unreadable';
    if (data.list.invoice_flag !== false) return action + ': invoice_flag=' + data.list.invoice_flag;
    return data.list.isHandInvoice ? action + ': isHandInvoice' : '';
  };

  const voidOrderNo = (data) => (data && typeof data.salno === 'string' ? [data.salno] : []);

  /** 非 ajax 的 delReceipt／delOrder 路由：salno 與 event 取自 query、body、Yii path 參數。 */
  const voidRoute = (request, approvals, onIsolated = false) => {
    const pairs = request.params;
    const key = (k) => pairs.filter(([name]) => name === k).map(([, v]) => v);
    const arrayKeys = pairs.filter(([name]) => /^(salno|event)\[/.test(name));
    const events = key('event').concat(arrayKeys.length ? ['[]'] : []);
    return voidDecision(request.routeName, key('salno'), events, approvals, onIsolated);
  };

  /** 作廢的共同規則：event 必須空、salno 唯一且已核准；放行即消耗該核准。 */
  const voidDecision = (name, salnos, events, approvals, onIsolated = false) => {
    const event = events.find((e) => e !== undefined && e !== null && e !== '');
    const isolatedAllowance = onIsolated && events.length === 1 && ALLOWANCE_EVENTS.has(event);
    if (event !== undefined && !isolatedAllowance) return name + ': allowance or unknown event blocked (' + event + ')';
    const distinct = Array.from(new Set(salnos));
    if (distinct.length !== 1 || distinct[0] === '') return name + ': void needs exactly one salno';
    const index = approvals.indexOf(distinct[0]);
    if (index < 0) return name + ': void not approved ' + distinct[0];
    approvals.splice(index, 1);
    return '';
  };

  /** window.open：作廢、checkOut 路由與發票類頁面一律擋下（開出的新視窗不在保護內，不走核准）。 */
  const navDecide = (url, base) => {
    const { segments, path } = routeOf(url, base);
    if (segments.some((s) => VOID_ROUTES.has(s) || s === 'checkout')) return 'blocked-route ' + path;
    return NAV_BLOCKED.test(path) ? 'blocked-page ' + path : '';
  };

  const decodeAll = (text) => {
    try { return decodeURIComponent(text); } catch (e) { return text; }
  };
  const splitPath = (text) => decodeAll(text).split(/[\\/]+/).filter(Boolean);

  /** 路由來源：URL 的 path，以及 ?r=（Yii get 格式）。segments 為兩者的小寫合併，供作廢與 checkOut 比對。 */
  const routeOf = (url, base) => {
    let pathname = String(url || '');
    let search = '';
    try {
      const parsed = new URL(pathname, base);
      pathname = parsed.pathname;
      search = parsed.search;
    } catch (e) { /* 保留原字串比對 */ }
    const query = new URLSearchParams(search);
    const pathSegments = splitPath(pathname);
    const routeSegments = query.has('r') ? splitPath(query.get('r')) : pathSegments;
    return {
      path: pathname,
      query,
      pathSegments,
      routeSegments,
      segments: pathSegments.concat(splitPath(query.get('r') || '')).map((s) => s.toLowerCase()),
    };
  };

  /** Yii path 格式：/pos/delReceipt/salno/0200000004 → [['salno', '0200000004']] */
  const pathPairs = (pathSegments) => {
    const at = pathSegments.findIndex((s) => VOID_ROUTES.has(s.toLowerCase()));
    if (at < 0) return [];
    const rest = pathSegments.slice(at + 1);
    const pairs = [];
    for (let i = 0; i + 1 < rest.length; i += 2) pairs.push([rest[i], rest[i + 1]]);
    return pairs;
  };

  /** 不用 instanceof：iframe 的 URLSearchParams／FormData 屬於另一個 realm。讀不到內容時回 null。 */
  const toParams = (body) => {
    if (body === undefined || body === null) return new URLSearchParams('');
    if (typeof body === 'string') return new URLSearchParams(body);
    return typeof body.get === 'function' ? body : null;
  };

  const entriesOf = (params) => {
    if (typeof params.entries !== 'function') return [];
    return Array.from(params.entries()).map(([k, v]) => [String(k), typeof v === 'string' ? v : '[object]']);
  };

  /** 解析失敗的 data 以 undefined 表示，讓 decide 以「讀不到內容」擋下。 */
  const parseRequest = (method, url, body, base) => {
    const verb = String(method || 'GET').toUpperCase();
    const route = routeOf(url, base);
    const params = toParams(body);
    const routeKey = route.routeSegments.slice(-2).join('/').toLowerCase();
    const routeName = route.routeSegments.slice(-2).join('/') || route.path;
    const site = (route.pathSegments[0] || '').toLowerCase();
    const common = { method: verb, path: route.path, segments: route.segments, routeKey, routeName, site };
    if (params === null) return { ...common, action: '', data: undefined, params: [], unreadable: true };
    let data;
    try { data = JSON.parse(params.get('data') || 'null'); } catch (e) { data = undefined; }
    const all = entriesOf(route.query).concat(entriesOf(params), pathPairs(route.pathSegments));
    return { ...common, action: params.get('ajax') || '', data, params: all, unreadable: false };
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { decide, parseRequest, navDecide, ALLOWED, ISOLATED_SITES };
    return undefined;
  }

  const state = window.__posGuard || (window.__posGuard = { blocked: [], log: [], voidOK: [], isolated: '' });
  const block = (reason) => { state.blocked.push(reason); return reason; };
  const mark = (fn) => { fn.__posGuard = true; return fn; };
  const OPAQUE = { size: 0 };

  /** 在指定視窗安裝攔截；桌況等 iframe 有自己的 XMLHttpRequest，須逐一安裝。 */
  const install = (win) => {
    const gate = (method, url, body) => {
      const request = parseRequest(method, url, body, win.location.href);
      if (request.action) state.log.push(request.action);
      const reason = decide(request, state.voidOK, state.isolated || '');
      return reason ? block(reason) : '';
    };
    const X = win.XMLHttpRequest.prototype;
    if (!X.send.__posGuard) {
      const open = X.open;
      const send = X.send;
      X.open = function (method, url) { this.__posGuardReq = [method, url]; return open.apply(this, arguments); };
      X.send = mark(function (body) {
        const req = this.__posGuardReq || ['POST', ''];
        const reason = gate(req[0], req[1], body);
        if (reason) throw new Error('POS_GUARD ' + reason);
        return send.apply(this, arguments);
      });
    }
    if (!win.fetch.__posGuard) {
      const native = win.fetch;
      win.fetch = mark(function (input, init) {
        const isRequest = !!input && typeof input === 'object' && typeof input.clone === 'function' && typeof input.url === 'string';
        const url = isRequest ? input.url : input;
        const method = (init && init.method) || (isRequest && input.method) || 'GET';
        const args = arguments;
        const run = (body) => {
          const reason = gate(method, url, body);
          return reason ? Promise.reject(new Error('POS_GUARD ' + reason)) : native.apply(win, args);
        };
        const hasInitBody = !!init && init.body !== undefined && init.body !== null;
        if (isRequest && !hasInitBody && !isReadMethod(String(method).toUpperCase())) {
          // Request 的 body 是串流：複製後讀文字；讀不到就以不透明內容交給 decide 擋下
          return Promise.resolve().then(() => input.clone().text()).then(run, () => run(OPAQUE));
        }
        return run(init && init.body);
      });
    }
    const nav = win.navigator;
    if (!nav.sendBeacon.__posGuard) {
      const beacon = nav.sendBeacon.bind(nav);
      nav.sendBeacon = mark((url, body) => (gate('POST', url, body) ? false : beacon(url, body)));
    }
    if (!win.open.__posGuard) {
      const nativeOpen = win.open;
      win.open = mark(function (url) {
        const reason = url ? navDecide(String(url), win.location.href) : '';
        if (reason) { block(reason); return null; }
        return nativeOpen.apply(win, arguments);
      });
    }
    /** 表單送出：method、action、欄位取自表單本身與 submitter 的 formaction／formmethod。 */
    const formReason = (form, submitter) => {
      const attr = (el, name) => (el && el.getAttribute ? el.getAttribute(name) : null);
      const action = attr(submitter, 'formaction') !== null ? attr(submitter, 'formaction') : attr(form, 'action');
      const url = action === null ? win.location.href : action;
      const page = routeOf(url, win.location.href).path;
      if (NAV_BLOCKED.test(page)) return block('blocked-page ' + page);
      return gate(attr(submitter, 'formmethod') || attr(form, 'method') || 'GET', url, new win.FormData(form));
    };
    const F = win.HTMLFormElement.prototype;
    if (!F.submit.__posGuard) {
      const submit = F.submit;
      F.submit = mark(function () {
        const reason = formReason(this, null);
        if (reason) throw new Error('POS_GUARD ' + reason);
        return submit.apply(this, arguments);
      });
    }
    if (!win.__posGuardSubmit) {
      // 涵蓋 requestSubmit() 與按鈕、Enter 觸發的送出（這些不經 form.submit）
      win.addEventListener('submit', (event) => {
        if (!formReason(event.target, event.submitter)) return;
        event.preventDefault();
        event.stopImmediatePropagation();
      }, true);
      win.__posGuardSubmit = true;
    }
    return [X.send, win.fetch, nav.sendBeacon, win.open, F.submit].every((fn) => fn.__posGuard === true) && win.__posGuardSubmit === true;
  };

  /** 目前視窗與所有同源 iframe；跨源 iframe 讀不到，也無法共用 POS 的登入 session。 */
  const frames = [window];
  let skipped = 0;
  for (let n = 0; n < frames.length; n += 1) {
    for (const el of frames[n].document.querySelectorAll('iframe')) {
      let inner = null;
      try { inner = el.contentWindow && el.contentWindow.document ? el.contentWindow : null; } catch (e) { skipped += 1; }
      if (inner) frames.push(inner);
    }
  }
  const armed = frames.map(install).every(Boolean);

  const pos = window.POS;
  return JSON.stringify({
    armed,
    frames: frames.length,
    crossOriginFrames: skipped,
    blocked: state.blocked,
    pendingVoidApprovals: state.voidOK.length,
    isolated: state.isolated || '',
    log: state.log.slice(-30),
    invoice_flag: pos && pos.list ? pos.list.invoice_flag : null,
    sale: (document.getElementById('sale') || {}).innerText || null,
  });
})();

'use strict';
// 執行：node --test <skill>/scripts/pos-guard.test.js
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const vm = require('node:vm');
const { spawnSync } = require('node:child_process');
const { decide, parseRequest, navDecide, ALLOWED, ISOLATED_SITES } = require('./pos-guard.js');

const BASE = 'https://cpos.zdn.tw/demo218/pos/index';
const NO = '0200000004';
const form = (fields) => new URLSearchParams(fields).toString();
const post = (action, data) => parseRequest('POST', BASE, form({ ajax: action, data: JSON.stringify(data) }), BASE);
// 注意：decide 會消耗 approvals（作廢核准送出一次即用掉），所以每個案例給新陣列。
const verdict = (action, data, approved = []) => decide(post(action, data), approved);
const direct = (method, url, body, approved = []) => decide(parseRequest(method, url, body, BASE), approved);

test('checkOut 只在 invoice_flag 為 false 且非手開時放行', () => {
  assert.strictEqual(verdict('checkOut', { list: { invoice_flag: false } }), '');
  for (const list of [{ invoice_flag: true }, { invoice_flag: 1 }, { invoice_flag: 'false' }, {}, { invoice_flag: false, isHandInvoice: true }]) {
    assert.notStrictEqual(verdict('checkOut', { list }), '');
  }
  for (const data of [{}, null, { list: null }]) assert.notStrictEqual(verdict('checkOut', data), '');
});

test('checkOut 不分大小寫都受 invoice_flag 規則管', () => {
  for (const action of ['checkout', 'CHECKOUT', 'CheckOut']) {
    assert.notStrictEqual(verdict(action, { list: { invoice_flag: true } }), '', action);
    assert.notStrictEqual(verdict(action, {}), '', action);
  }
});

test('checkOut 的 data 不是 JSON 時擋下', () => {
  const request = parseRequest('POST', BASE, 'ajax=checkOut&data=%7Bbad', BASE);
  assert.notStrictEqual(decide(request, []), '');
});

test('會開票、補印發票、折讓、抽佣寫入、拆帳、清帳的動作一律擋下', () => {
  const denied = ['create_invoice_xml', 'reprintInvoiceReceipt', 'RePrint', 'RePrintKitchen', 'cash_lower_limit_save',
    'cash_lower_limit_save_aaaaaa', 'reprint_commission', 'rebuild_commission_receipt', 'commission_input',
    'commission_show', 'handleAllowance', 'cleardebt', 'cleardebt_complement', 'splitBillStart', 'splitBillChildCheckout',
    'payByLinePay', 'addDeposit', 'delWebOrder', 'delUOrder', 'saveReceipt_order', 'prepaidSaveReceipt', 'consign',
    'unknownFutureAction'];
  for (const action of denied) assert.notStrictEqual(verdict(action, {}), '', action);
});

test('擋下原因帶可辨識的名稱（action 或路徑）', () => {
  assert.match(verdict('checkOut', { list: { invoice_flag: true } }), /checkOut/);
  assert.match(verdict('create_invoice_xml', {}), /create_invoice_xml/);
  assert.match(verdict('delReceipt', { salno: NO }), /delReceipt/);
  assert.match(direct('POST', '/demo218/pos/checkOut', form({ a: 1 })), /checkOut/i);
  assert.match(direct('POST', '/demo218/CreditCard/insertRecord', form({ a: 1 })), /CreditCard\/insertRecord/);
});

test('ajax 作廢：未核准擋下，核准後放行一次，第二次擋下（delReceipt／delOrder）', () => {
  for (const action of ['delReceipt', 'delOrder']) {
    assert.notStrictEqual(verdict(action, { salno: NO }), '', action);
    const approvals = [NO];
    assert.strictEqual(decide(post(action, { salno: NO }), approvals), '', action);
    assert.deepStrictEqual(approvals, [], '放行後核准被消耗');
    assert.notStrictEqual(decide(post(action, { salno: NO }), approvals), '', action + ' 第二次');
    assert.notStrictEqual(verdict(action, { salno: '0200000005' }, [NO]), '', action);
    assert.notStrictEqual(verdict(action, {}, ['']), '', action);
  }
});

test('核准只對單號有效：一號核准一次，不影響其他單號', () => {
  const approvals = [NO, '0200000005'];
  assert.strictEqual(decide(post('delReceipt', { salno: '0200000005' }), approvals), '');
  assert.deepStrictEqual(approvals, [NO]);
});

test('ajax 作廢只認 salno，且 salno 必須是字串', () => {
  assert.notStrictEqual(verdict('delReceipt', { sales_no: NO }, [NO]), '');
  assert.notStrictEqual(verdict('delReceipt', { salno: [NO] }, [NO]), '');
  assert.notStrictEqual(verdict('delReceipt', { salno: 200000004 }, [NO]), '');
});

test('折讓事件一律擋，即使單號已核准；未知 event 預設擋；擋下時不消耗核准', () => {
  for (const event of ['MakeAllowances', 'VoidedAllowances', 'SomethingNew', 'voidedallowances', 1, true]) {
    for (const action of ['delReceipt', 'delOrder']) {
      const approvals = [NO];
      const reason = decide(post(action, { salno: NO, event }), approvals);
      assert.notStrictEqual(reason, '', action + ' ' + event);
      assert.deepStrictEqual(approvals, [NO], '擋下不消耗');
    }
  }
  assert.match(verdict('delReceipt', { salno: NO, event: 'MakeAllowances' }, [NO]), /MakeAllowances/);
});

test('作廢的 event 為空值、null 或未帶時視為一般作廢', () => {
  for (const event of [undefined, null, '']) {
    assert.strictEqual(verdict('delReceipt', { salno: NO, event }, [NO]), '', String(event));
  }
});

test('非 ajax POST /pos/delReceipt：未核准擋下，核准後放行一次', () => {
  const url = 'https://cpos.zdn.tw/demo218/pos/delReceipt';
  assert.notStrictEqual(direct('POST', url, form({ salno: NO, deposit: 0, point: 0 })), '');
  assert.notStrictEqual(direct('POST', url, form({ deposit: 0 }), [NO]), '');
  const approvals = [NO];
  assert.strictEqual(direct('POST', url, form({ salno: NO, deposit: 0, point: 0, store_no: '02' }), approvals), '');
  assert.deepStrictEqual(approvals, []);
  assert.notStrictEqual(direct('POST', url, form({ salno: NO }), approvals), '');
});

test('非 ajax delReceipt／delOrder：路徑變化（大小寫、尾斜線、完整 URL、?r=、編碼、Yii path 參數、GET）同一判斷', () => {
  const variants = [
    ['POST', '/demo218/pos/delReceipt', form({ salno: NO })],
    ['POST', '/demo218/pos/delReceipt/', form({ salno: NO })],
    ['POST', '/demo218/pos/DELRECEIPT', form({ salno: NO })],
    ['POST', '/demo218/pos/delreceipt', form({ salno: NO })],
    ['POST', '/demo218/pos/%64elReceipt', form({ salno: NO })],
    ['POST', '//cpos.zdn.tw/demo218/pos//delReceipt', form({ salno: NO })],
    ['POST', 'https://cpos.zdn.tw/demo218/index.php/pos/delReceipt', form({ salno: NO })],
    ['POST', '/demo218/index.php?r=pos/delReceipt', form({ salno: NO })],
    ['POST', '/demo218/pos/delOrder', form({ salno: NO })],
    ['POST', '/demo218/pos/delReceipt/salno/' + NO, ''],
    ['POST', '/demo218/pos/delReceipt?salno=' + NO, ''],
    ['GET', '/demo218/pos/delReceipt?salno=' + NO, null],
    ['GET', '/demo218/pos/delReceipt/salno/' + NO, null],
    ['GET', '/demo218/index.php?r=pos/delReceipt&salno=' + NO, null],
    ['GET', '/demo218/pos/delOrder?salno=' + NO, null],
    ['PUT', '/demo218/pos/delReceipt', form({ salno: NO })],
  ];
  for (const [method, url, body] of variants) {
    assert.notStrictEqual(direct(method, url, body), '', 'unapproved ' + method + ' ' + url);
    const approvals = [NO];
    assert.strictEqual(direct(method, url, body, approvals), '', 'approved ' + method + ' ' + url);
    assert.deepStrictEqual(approvals, [], 'consumed ' + url);
  }
});

test('非 ajax 作廢：折讓 event、衝突或陣列的 salno 一律擋', () => {
  const url = '/demo218/pos/delReceipt';
  const bad = [
    form({ salno: NO, event: 'MakeAllowances' }),
    form({ salno: NO, event: 'VoidedAllowances' }),
    form({ salno: NO, event: 'x' }),
    form({ 'event[]': 'x', salno: NO }),
    'salno=0200000005&salno=' + NO,
    'salno=' + NO + '&salno=0200000005',
    form({ 'salno[]': NO }),
    '',
  ];
  for (const body of bad) assert.notStrictEqual(direct('POST', url, body, [NO]), '', body);
  assert.notStrictEqual(direct('POST', url + '?salno=0200000005', form({ salno: NO }), [NO]), '', 'query 與 body 衝突');
  assert.strictEqual(direct('POST', url + '?salno=' + NO, form({ salno: NO }), [NO]), '', '相同值不算衝突');
});

test('非 ajax 作廢的 salno 讀不到時擋下', () => {
  assert.notStrictEqual(direct('POST', '/demo218/pos/delReceipt', { size: 1 }, [NO]), '');
});

test('/pos/checkOut 路徑一律擋（伺服端 invoice_flag 寫死 true、del_flag 預設為作廢）', () => {
  const urls = ['/demo218/pos/checkOut', '/demo218/pos/CHECKOUT', '/demo218/pos/checkout/', '/demo218/index.php?r=pos/checkOut',
    'https://cpos.zdn.tw/demo218/pos/checkOut?sales_no=' + NO];
  for (const url of urls) {
    assert.notStrictEqual(direct('POST', url, form({ sales_no: NO, invoice_flag: 'false' })), '', url);
    assert.notStrictEqual(direct('POST', url, form({ ajax: 'checkOut', data: JSON.stringify({ list: { invoice_flag: false } }) })), '', url);
    assert.notStrictEqual(direct('GET', url, null), '', url);
  }
});

test('saleorderCheckout 銷貨憑單頁放行（只渲染，不開票）', () => {
  for (const url of ['/demo218/pos/saleorderCheckout/salno/' + NO, '/demo218/pos/SaleorderCheckout/salno/' + NO + '?reprint=1',
    'https://cpos.zdn.tw/demo218/pos/saleorderCheckout/salno/' + NO]) {
    assert.strictEqual(direct('GET', url, null), '', url);
    assert.strictEqual(navDecide(url, BASE), '', url);
  }
});

test('window.open 類導覽：作廢、checkOut 與發票類頁面擋下', () => {
  for (const url of ['/demo218/pos/checkOut', '/demo218/pos/delReceipt?salno=' + NO, '/demo218/pos/delOrder',
    '/demo218/maintain/invoice', '/demo218/record/allowance', '/demo218/x/eiic']) {
    assert.notStrictEqual(navDecide(url, BASE), '', url);
  }
  assert.strictEqual(navDecide('/demo218/pos/saleorder/salno/' + NO, BASE), '');
});

test('允許清單與讀取類動作放行', () => {
  for (const action of ['saveReceipt', 'saveReceipt_new', 'printTheReceipt', 'lockTable', 'getInvoiceNum', 'get_commission_data', 'getSaleNo', 'getSalesTemp']) {
    assert.strictEqual(verdict(action, {}), '', action);
  }
  assert.ok(!ALLOWED.has('checkOut'));
});

test('沒有 ajax 參數的 POST 預設擋下，只放行明列的登入與純讀路徑', () => {
  const blocked = ['/demo218/pos/tableSeats', '/demo218/pos/someFutureWrite', '/demo218/CreditCard/insertRecord',
    '/demo218/CreditCard/genCommand', '/demo218/maintain/invoice', '/demo218/pos/index',
    '/demo218/pos/saleorderCheckout/salno/' + NO];
  for (const url of blocked) assert.notStrictEqual(direct('POST', url, form({ a: 1 })), '', url);
  const allowed = ['/demo218/site/login', '/demo218/pos/get3PartyPaymentList', '/demo218/pos/getTotalPaymentList',
    '/demo218/pos/getTicketList', '/demo218/pos/getRedeemType', '/demo218/pos/GET3PARTYPAYMENTLIST?state=1'];
  for (const url of allowed) assert.strictEqual(direct('POST', url, form({ state: 1 })), '', url);
  assert.strictEqual(direct('POST', '/demo218/site/login', form({ 'LoginForm[username]': 'x', ajax: 'login-form' })), '');
  assert.strictEqual(direct('POST', '/demo218/pos/getRedeemType', ''), '');
});

test('允許路徑不能借 ?r= 轉到其他動作', () => {
  assert.notStrictEqual(direct('POST', '/demo218/pos/getTicketList?r=pos/delReceipt', form({ salno: NO }), []), '');
  assert.notStrictEqual(direct('POST', '/demo218/index.php?r=pos/someWrite', form({ a: 1 })), '');
});

test('GET 頁面載入照常放行', () => {
  for (const url of ['/demo218/pos/index', '/demo218/site/login', '/demo218/maintain/invoice', '/demo218/pos/saleorder/salno/' + NO,
    '/demo218/tableSeats/index', '/demo218/record/sales', '/demo218/js/zpos.js?123']) {
    assert.strictEqual(direct('GET', url, null), '', url);
  }
});

test('其他 realm 的參數物件照樣解析；讀不到的內容擋下', () => {
  const foreign = vm.runInNewContext("new Map([['ajax', 'create_invoice_xml'], ['data', '{}']])");
  assert.notStrictEqual(decide(parseRequest('POST', BASE, foreign, BASE), []), '');
  const opaque = { size: 10 };
  assert.notStrictEqual(decide(parseRequest('POST', BASE, opaque, BASE), []), '');
  assert.strictEqual(decide(parseRequest('GET', BASE, null, BASE), []), '');
});

const state = (stdin) => spawnSync('python3', ['-I', path.join(__dirname, 'pos-guard-state.py')], { input: stdin }).status;

test('武裝判斷只認 armed === true', () => {
  const wrap = (o) => JSON.stringify(JSON.stringify(o));
  assert.strictEqual(state(wrap({ armed: true, blocked: [], invoice_flag: false })), 0);
  assert.strictEqual(state(wrap({ armed: false, blocked: [], invoice_flag: true })), 9);
  assert.strictEqual(state(wrap({ armed: 'true', blocked: [] })), 9);
  assert.strictEqual(state('not json'), 9);
  assert.strictEqual(state(''), 9);
  assert.strictEqual(state(wrap({ armed: true, blocked: ['invoice_flag=true'] })), 10);
});

// ---- shell 腳本：以假的 agent-browser 取代瀏覽器，可重複執行 ----

const madeDirs = [];
test.after(() => madeDirs.forEach((dir) => fs.rmSync(dir, { recursive: true, force: true })));

const makeFakeBin = () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'pos-guard-test-'));
  madeDirs.push(dir);
  const log = path.join(dir, 'calls.log');
  const bin = path.join(dir, 'agent-browser');
  fs.writeFileSync(bin, '#!/usr/bin/env bash\nprintf \'%s\\n\' "$*" >> "$FAKE_LOG"\necho \'{"armed":true,"blocked":[]}\'\n', { mode: 0o755 });
  return { dir, log, env: { ...process.env, PATH: dir + path.delimiter + process.env.PATH, FAKE_LOG: log } };
};
const calls = (fake) => (fs.existsSync(fake.log) ? fs.readFileSync(fake.log, 'utf8') : '');
const guardSh = path.join(__dirname, 'pos-guard.sh');
const abSh = path.join(__dirname, 'pos-ab.sh');

test('void-ok 拒絕非 10 碼單號與未核准單號', () => {
  const fake = makeFakeBin();
  const run = (no, env = {}) => spawnSync('bash', [guardSh, 'no-such-session', 'void-ok', no], { env: { ...fake.env, ...env } }).status;
  assert.strictEqual(run("1');alert(1);//"), 2);
  assert.strictEqual(run('123'), 2);
  assert.strictEqual(run(NO), 8);
  assert.strictEqual(run(NO, { POS_GUARD_APPROVED: '/dev/null' }), 8);
  assert.strictEqual(calls(fake), '', '被拒絕時沒有對瀏覽器下任何指令');
});

test('void-ok 接受 CRLF 與 LF 的核准檔，並只登記該單號', () => {
  for (const eol of ['\r\n', '\n']) {
    const fake = makeFakeBin();
    const file = path.join(fake.dir, 'approved.txt');
    fs.writeFileSync(file, '0200000009' + eol + NO + eol);
    const r = spawnSync('bash', [guardSh, 's1', 'void-ok', NO], { env: { ...fake.env, POS_GUARD_APPROVED: file }, encoding: 'utf8' });
    assert.strictEqual(r.status, 0, JSON.stringify(eol) + r.stderr);
    assert.match(calls(fake), new RegExp("voidOK\\.push\\('" + NO + "'\\)"));
    assert.doesNotMatch(calls(fake), /0200000009/);
  }
  const fake = makeFakeBin();
  const file = path.join(fake.dir, 'approved.txt');
  fs.writeFileSync(file, '0200000009\r\n');
  const r = spawnSync('bash', [guardSh, 's1', 'void-ok', NO], { env: { ...fake.env, POS_GUARD_APPROVED: file } });
  assert.strictEqual(r.status, 8);
});

test('click 的 WHICH 只接受 first 或 last，其他值報錯且不操作瀏覽器', () => {
  const fake = makeFakeBin();
  for (const which of ['middle', 'FIRST', '', "x'; alert(1); '"]) {
    const r = spawnSync('bash', [abSh, 's1', 'click', '確定', which], { env: fake.env, encoding: 'utf8' });
    assert.strictEqual(r.status, 2, JSON.stringify(which));
    assert.match(r.stderr, /first|last/);
  }
  assert.strictEqual(calls(fake), '');
  for (const which of ['first', 'last']) {
    const r = spawnSync('bash', [abSh, 's1', 'click', '確定', which], { env: fake.env });
    assert.strictEqual(r.status, 0, which);
  }
  assert.match(calls(fake), /'last' === 'last'/);
  assert.match(calls(fake), /'first' === 'last'/);
  const none = spawnSync('bash', [abSh, 's1', 'click', '確定'], { env: fake.env });
  assert.strictEqual(none.status, 0, '省略 WHICH 預設 first');
});

test('掃碼收單輪詢放行；明列路由不可夾帶 doAjax 動作', () => {
  const at = (url, fields) => decide(parseRequest('POST', url, form(fields), BASE), []);
  assert.strictEqual(at('/demo218/tableSeats/scanOrderProcess', {}), '');
  assert.notStrictEqual(at('/demo218/tableSeats/receiveScanOrderItem', {}), '');
  assert.notStrictEqual(at('/demo218/pos/index/x/site/login', { ajax: 'create_invoice_xml', data: '{}' }), '');
  assert.notStrictEqual(at('/demo218/pos/getTicketList', { ajax: 'create_invoice_xml', data: '{}' }), '');
});

test('桌況 iframe 的鎖桌動作與掃碼加品項放行；未查證的寫入動作仍擋', () => {
  const seats = (action) => decide(parseRequest('POST', 'ajax', form({ ajax: action, data: '{}' }), 'https://cpos.zdn.tw/demo218/tableSeats/index'), []);
  for (const action of ['checklock', 'ordering']) assert.strictEqual(seats(action), '', action);
  for (const action of ['addItem', 'cards']) assert.strictEqual(decide(post(action, { no: '1' }), []), '', action);
  for (const action of ['chgTable', 'clearTable', 'updateSelling', 'openCasher', 'verifyButtonPassword']) {
    assert.notStrictEqual(decide(post(action, {}), []), '', action);
  }
});

const SB84 = 'https://cpos.zdn.tw/sb84/pos/index';
const sbPost = (action, data, isolated, base = SB84) =>
  decide(parseRequest('POST', base, form({ ajax: action, data: JSON.stringify(data) }), base), [], isolated);

test('隔離站登記後放行 splitBill* 與開票的 checkOut，未登記時照常擋', () => {
  for (const action of ['splitBillPrepareSource', 'splitBillStart', 'splitBillAllocate', 'splitBillChildCheckout', 'splitBillCancel']) {
    assert.strictEqual(sbPost(action, {}, 'sb84'), '', action);
    assert.notStrictEqual(sbPost(action, {}, ''), '', action);
  }
  assert.strictEqual(sbPost('checkOut', { list: { invoice_flag: true } }, 'sb84'), '');
  assert.notStrictEqual(sbPost('checkOut', { list: { invoice_flag: true } }, ''), '');
  assert.notStrictEqual(sbPost('checkOut', {}, 'sb84'), '');
});

test('隔離站放行只限 ISOLATED_SITES 且請求在同一站', () => {
  assert.notStrictEqual(sbPost('splitBillStart', {}, 'sb84', BASE), '');
  assert.notStrictEqual(sbPost('splitBillStart', {}, 'demo218', BASE), '');
  assert.notStrictEqual(sbPost('checkOut', { list: { invoice_flag: true } }, 'demo218', BASE), '');
  assert.ok(!ISOLATED_SITES.has('demo218'));
});

test('隔離站放行清帳；折讓事件需單號核准，未知 event 仍擋', () => {
  for (const action of ['cleardebt', 'cleardebt_complement', 'handleAllowance', 'chgTable', 'CarrierConfirm']) {
    assert.strictEqual(sbPost(action, {}, 'sb84'), '', action);
    assert.notStrictEqual(sbPost(action, {}, ''), '', action);
  }
  const allow = (event, approved) => decide(parseRequest('POST', SB84, form({ ajax: 'delReceipt', data: JSON.stringify({ salno: NO, event }) }), SB84), approved, 'sb84');
  assert.strictEqual(allow('MakeAllowances', [NO]), '');
  assert.notStrictEqual(allow('MakeAllowances', []), '');
  assert.notStrictEqual(allow('UnknownEvent', [NO]), '');
  assert.notStrictEqual(decide(parseRequest('POST', BASE, form({ ajax: 'delReceipt', data: JSON.stringify({ salno: NO, event: 'MakeAllowances' }) }), BASE), [NO], 'sb84'), '');
});

test('隔離站放行刷卡指令產生與回應解析路由；其他站與其餘 CreditCard/* 仍擋', () => {
  const at = (url, isolated) => decide(parseRequest('POST', url, form({ type: 'esun600', value: '1' }), SB84), [], isolated);
  for (const route of ['CreditCard/genCommand', 'creditCard/analysisRes']) {
    assert.strictEqual(at('/sb84/' + route, 'sb84'), '', route);
    assert.notStrictEqual(at('/sb84/' + route, ''), '', route);
    assert.notStrictEqual(decide(parseRequest('POST', '/demo218/' + route, form({ a: 1 }), BASE), [], 'sb84'), '', route);
  }
  assert.notStrictEqual(at('/sb84/CreditCard/insertRecord', 'sb84'), '');
});

test('隔離站仍擋認損、未核准作廢與 /pos/checkOut 路由', () => {
  assert.notStrictEqual(sbPost('splitBillWriteOff', {}, 'sb84'), '');
  assert.notStrictEqual(sbPost('delReceipt', { salno: NO }, 'sb84'), '');
  assert.notStrictEqual(sbPost('create_invoice_xml', {}, 'sb84'), '');
  assert.notStrictEqual(decide(parseRequest('POST', '/sb84/pos/checkOut', form({ a: 1 }), SB84), [], 'sb84'), '');
  assert.notStrictEqual(navDecide('/sb84/invoice/index', SB84), '');
});

test('isolated-ok 拒絕未設定核准檔、清單外的站與不合法站名', () => {
  const sh = path.join(__dirname, 'pos-guard.sh');
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'pos-guard-iso-'));
  const list = path.join(dir, 'isolated.txt');
  fs.writeFileSync(list, 'sb84\r\n');
  const run = (args, env) => spawnSync('bash', [sh, 's', 'isolated-ok', ...args], { env: { ...process.env, ...env }, encoding: 'utf8' });
  assert.strictEqual(run(['sb84'], { POS_GUARD_ISOLATED: '' }).status, 8);
  assert.strictEqual(run(['demo218'], { POS_GUARD_ISOLATED: list }).status, 8);
  assert.strictEqual(run(['SB84;x'], { POS_GUARD_ISOLATED: list }).status, 2);
  fs.rmSync(dir, { recursive: true, force: true });
});

test('統編抬頭查詢放行（只查稅籍 API，不開票）', () => {
  assert.strictEqual(verdict('lookupTaxTitle', { tax_id: '12345671' }), '');
});

// Pruebas de la API de Carrota (node:test, sin dependencias).
// Lanza el servidor en un puerto aleatorio con una base temporal.
//
//   node --test test/

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const path = require('node:path');
const os = require('node:os');
const fs = require('node:fs');

let child;
let base;

const j = (res) => res.json();
const get = (url) => fetch(`${base}${url}`, { signal: AbortSignal.timeout(5000) });
const send = (url, opts = {}) =>
  fetch(`${base}${url}`, {
    method: opts.method || 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: opts.body === undefined ? undefined : JSON.stringify(opts.body),
    signal: AbortSignal.timeout(5000),
  });

before(async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'carrota-test-'));
  child = spawn(process.execPath, [path.join(__dirname, '..', 'server.js')], {
    env: { ...process.env, PORT: '0', DB_PATH: path.join(dir, 'test.db') },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  child.stderr.on('data', (d) => process.stderr.write(`[server] ${d}`));
  base = await new Promise((resolve, reject) => {
    let out = '';
    const timer = setTimeout(() => reject(new Error('server did not start')), 8000);
    child.stdout.on('data', (d) => {
      out += d;
      const m = out.match(/LISTENING (\d+)/);
      if (m) {
        clearTimeout(timer);
        resolve(`http://127.0.0.1:${m[1]}`);
      }
    });
    child.on('exit', (c) => {
      clearTimeout(timer);
      reject(new Error(`server exited with ${c}`));
    });
  });
});

after(() => {
  if (child) child.kill();
});

test('health', async () => {
  const res = await get('/api/health');
  assert.equal(res.status, 200);
  const body = await j(res);
  assert.equal(body.ok, true);
});

test('feed devuelve los videos con datos', async () => {
  const body = await (await get('/api/feed')).json();
  assert.equal(body.videos.length, 6);
  const first = body.videos[0];
  for (const k of ['productId', 'name', 'price', 'stock', 'caption', 'hashtags', 'likes', 'comments', 'liked', 'saved']) {
    assert.ok(k in first, `falta ${k}`);
  }
});

test('like alterna y valida video inexistente', async () => {
  const before = await (await get('/api/feed')).json();
  const v = before.videos.find((x) => x.productId === 'aguacate');
  const r1 = await (await send('/api/videos/aguacate/like')).json();
  assert.equal(r1.liked, true);
  assert.equal(r1.likes, v.likes + 1);
  const r2 = await (await send('/api/videos/aguacate/like')).json();
  assert.equal(r2.liked, false);
  assert.equal(r2.likes, v.likes);
  const res = await send('/api/videos/no-existe/like');
  assert.equal(res.status, 404);
});

test('save alterna', async () => {
  const r1 = await (await send('/api/videos/aguacate/save')).json();
  assert.equal(r1.saved, true);
  const r2 = await (await send('/api/videos/aguacate/save')).json();
  assert.equal(r2.saved, false);
  assert.equal((await send('/api/videos/no-existe/save')).status, 404);
});

test('comentarios: listar, agregar, validar', async () => {
  const seed = await (await get('/api/videos/aguacate/comments')).json();
  assert.ok(seed.comments.length >= 2);
  const added = await (await send('/api/videos/aguacate/comments', { body: { text: 'Prueba 🥑' } })).json();
  assert.equal(added.comment.author, 'Jorge');
  assert.equal(added.comment.text, 'Prueba 🥑');
  const list = await (await get('/api/videos/aguacate/comments')).json();
  assert.equal(list.comments.length, seed.comments.length + 1);
  assert.equal(list.comments[0].text, 'Prueba 🥑');
  assert.equal((await send('/api/videos/no-existe/comments', { body: { text: 'x' } })).status, 404);
  assert.equal((await send('/api/videos/aguacate/comments', { body: { text: '  ' } })).status, 400);
});

test('carrito: agregar, fusionar, límite de stock, editar, limpiar', async () => {
  await send('/api/cart', { body: { productId: 'tomate', qty: 3 } });
  await send('/api/cart', { body: { productId: 'tomate', qty: 2 } });
  let cart = await (await get('/api/cart')).json();
  assert.equal(cart.count, 5);
  assert.equal(cart.items.find((i) => i.productId === 'tomate').qty, 5);
  assert.equal(cart.total, 5 * 30);

  // el alias product_id (cliente Flutter) funciona igual
  await send('/api/cart', { body: { product_id: 'lechuga', qty: 1 } });
  cart = await (await get('/api/cart')).json();
  assert.equal(cart.items.find((i) => i.productId === 'lechuga').qty, 1);
  await send('/api/cart/lechuga', { method: 'DELETE' });

  // no puede exceder el stock (42 tomates)
  await send('/api/cart', { body: { productId: 'tomate', qty: 999 } });
  cart = await (await get('/api/cart')).json();
  assert.equal(cart.items.find((i) => i.productId === 'tomate').qty, 42);

  await send('/api/cart/tomate', { method: 'PUT', body: { qty: 2 } });
  cart = await (await get('/api/cart')).json();
  assert.equal(cart.count, 2);

  assert.equal((await send('/api/cart', { body: { productId: 'no-existe' } })).status, 400);
  assert.equal((await send('/api/cart/no-existe', { method: 'PUT', body: { qty: 1 } })).status, 404);

  await send('/api/cart/tomate', { method: 'DELETE' });
  cart = await (await get('/api/cart')).json();
  assert.equal(cart.count, 0);
});

test('venta con líneas: descuenta stock, aparece en la lista', async () => {
  const stockBefore = (await (await get('/api/products/tomate')).json()).product.stock;
  const res = await send('/api/sales', {
    body: { lines: [{ product_id: 'tomate', qty: 2 }, { productId: 'lechuga', qty: 1 }], payment: 'efectivo' },
  });
  assert.equal(res.status, 200);
  const { sale } = await res.json();
  assert.equal(sale.total, 2 * 30 + 28);
  assert.equal(sale.payment, 'efectivo');
  const stockAfter = (await (await get('/api/products/tomate')).json()).product.stock;
  assert.equal(stockAfter, stockBefore - 2);

  const list = await (await get('/api/sales')).json();
  const found = list.sales.find((s) => s.id === sale.id);
  assert.ok(found, 'venta no aparece en la lista');
  assert.equal(found.lines.length, 2);
});

test('venta con producto desconocido → 400', async () => {
  const res = await send('/api/sales', { body: { lines: [{ product_id: 'chayote', qty: 1 }] } });
  assert.equal(res.status, 400);
});

test('venta desde carrito vacío → 400', async () => {
  assert.equal((await send('/api/sales')).status, 400);
});

test('venta desde carrito: registra y vacía el carrito', async () => {
  await send('/api/cart', { body: { productId: 'espinaca', qty: 2 } });
  const res = await send('/api/sales', { body: { payment: 'tarjeta', authCode: '123456' } });
  assert.equal(res.status, 200);
  const { sale } = await res.json();
  assert.equal(sale.total, 2 * 28);
  assert.equal(sale.authCode, '123456');
  const cart = await (await get('/api/cart')).json();
  assert.equal(cart.count, 0);
});

test('deshacer venta restaura stock', async () => {
  const before = (await (await get('/api/products/mermelada')).json()).product.stock;
  const { sale } = await (await send('/api/sales', { body: { lines: [{ product_id: 'mermelada', qty: 1 }] } })).json();
  const mid = (await (await get('/api/products/mermelada')).json()).product.stock;
  assert.equal(mid, before - 1);
  const res = await send(`/api/sales/${sale.id}`, { method: 'DELETE' });
  assert.equal(res.status, 200);
  const after = (await (await get('/api/products/mermelada')).json()).product.stock;
  assert.equal(after, before);
  assert.equal((await send('/api/sales/no-existe', { method: 'DELETE' })).status, 404);
});

test('entrega: suma stock y crea eventos', async () => {
  const before = (await (await get('/api/products/zanahoria')).json()).product.stock;
  const res = await send('/api/deliveries', {
    body: { supplier: 'Milpa Verde', total: 360, lines: [{ product_id: 'zanahoria', qty: 10 }] },
  });
  assert.equal(res.status, 200);
  const { delivery } = await res.json();
  assert.equal(delivery.supplier, 'Milpa Verde');
  const after = (await (await get('/api/products/zanahoria')).json()).product.stock;
  assert.equal(after, before + 10);
  assert.equal((await send('/api/deliveries', { body: { lines: [{ product_id: 'x', qty: 1 }] } })).status, 400);
});

test('productos: listar, por id, por barcode, crear, editar, ajustar stock', async () => {
  const list = await (await get('/api/products')).json();
  assert.equal(list.products.length, 8);

  const byId = await (await get('/api/products/tomate')).json();
  assert.equal(byId.product.price, 30);

  const byBar = await (await get('/api/products/barcode/7501055300017')).json();
  assert.equal(byBar.product.id, 'tomate');
  assert.equal((await get('/api/products/barcode/000')).status, 404);
  assert.equal((await get('/api/products/nope')).status, 404);

  const created = await (await send('/api/products', {
    body: { id: 'jicama', name: 'Jícama', unit: 'kg', price: 18, stock: 5, emoji: '🥔', barcode: '999' },
  })).json();
  assert.equal(created.product.id, 'jicama');
  assert.equal((await send('/api/products', { body: { id: 'jicama', name: 'x' } })).status, 409);

  const upd = await (await send('/api/products/jicama', { method: 'PUT', body: { price: 20, stock: 7 } })).json();
  assert.equal(upd.product.price, 20);
  assert.equal(upd.product.stock, 7);

  const adj = await (await send('/api/products/jicama/stock', { body: { delta: -2 } })).json();
  assert.equal(adj.product.stock, 5);
  const adjUp = await (await send('/api/products/jicama/stock', { body: { delta: 3 } })).json();
  assert.equal(adjUp.product.stock, 8);
});

test('resumen refleja las ventas del día', async () => {
  const before = (await (await get('/api/summary')).json()).summary;
  const { sale } = await (await send('/api/sales', {
    body: { lines: [{ product_id: 'limon', qty: 2 }], payment: 'transferencia' },
  })).json();
  const { summary: s } = await (await get('/api/summary')).json();
  assert.equal(s.salesTotal - before.salesTotal, sale.total);
  assert.equal(s.salesCount - before.salesCount, 1);
  assert.equal(s.byPayment.transferencia - before.byPayment.transferencia, sale.total);
  const top = s.topProducts.find((t) => t.productId === 'limon');
  assert.ok(top && top.qty >= 2);
  assert.ok(s.inventoryValue > 0);
});

test('insights detectan stock bajo (lechuga y cilantro)', async () => {
  const { insights: list } = await (await get('/api/insights')).json();
  const lechuga = list.find((i) => i.productId === 'lechuga');
  assert.ok(lechuga, 'lechuga debería estar en insights');
  assert.equal(lechuga.urgency, 'low');
  assert.match(lechuga.reason, /Quedan \d+ pieza/);
  const cilantro = list.find((i) => i.productId === 'cilantro');
  assert.ok(cilantro);
});

test('compra sugerida se genera desde insights', async () => {
  const { items } = await (await get('/api/shopping')).json();
  assert.ok(items.length >= 2);
  for (const i of items) {
    assert.ok(i.productId && i.qty > 0 && i.reason);
  }
});

test('lumo sin API key responde power:false (fallback a parser local)', async () => {
  const res = await send('/api/lumo', { body: { text: '¿cómo va el negocio?' } });
  assert.equal(res.status, 200);
  const body = await j(res);
  assert.equal(body.power, false);
  assert.equal(body.reply, null);
});

test('cierre registra snapshot y eventos', async () => {
  const res = await send('/api/closing', { body: { note: 'Todo en orden' } });
  assert.equal(res.status, 200);
  const { close } = await res.json();
  assert.ok(close.total >= 0);
  assert.equal(close.note, 'Todo en orden');
  const closes = await (await get('/api/closes')).json();
  assert.ok(closes.closes.some((c) => c.id === close.id));
});

test('eventos: timeline y memoria', async () => {
  const tl = await (await get('/api/events?type=tl')).json();
  assert.ok(tl.events.length >= 5);
  assert.ok(tl.events.every((e) => 'time' in e && 'title' in e));

  const mem = await (await get('/api/events?type=mem')).json();
  assert.ok(mem.events.length >= 4);
  const hoy = mem.events.find((e) => e.group === 'Hoy');
  assert.ok(hoy, 'debe haber eventos de hoy');
  const patron = mem.events.find((e) => e.kind === 'Patrón observado');
  assert.ok(patron && patron.group === 'Patrón observado');
  const hace2 = mem.events.find((e) => e.when === 'hace 2 días');
  assert.ok(hace2, 'evento de hace 2 días');
});

test('business expone métricas del negocio', async () => {
  const { business: b } = await (await get('/api/business')).json();
  assert.equal(b.name, 'Carrota');
  assert.equal(b.currency, 'MXN');
  assert.equal(b.productCount, 9); // 8 seed + jícama
  assert.ok(b.inventoryValue > 0);
});

test('ruta desconocida → 404 y JSON inválido → 400', async () => {
  assert.equal((await get('/api/nada')).status, 404);
  const res = await fetch(`${base}/api/sales`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{no es json',
    signal: AbortSignal.timeout(5000),
  });
  assert.equal(res.status, 400);
});

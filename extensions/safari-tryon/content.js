(function () {
  function isProductPage() {
    const u = location.href;
    const host = location.host;
    if (/zara\.com/.test(host)) return /-p\d+\.html/.test(u) || /product/.test(u);
    if (/hm\.com/.test(host)) return /product/.test(u);
    if (/mango\.com/.test(host)) return /\/p\/\d+/.test(u);
    return false;
  }

  function injectButton() {
    if (document.getElementById('tryon-btn')) return;
    const btn = document.createElement('button');
    btn.id = 'tryon-btn';
    btn.textContent = 'Try on in TryOn';
    Object.assign(btn.style, {
      position: 'fixed', bottom: '16px', right: '16px',
      zIndex: '2147483647', padding: '12px 16px',
      background: '#111', color:'#fff', borderRadius:'999px',
      border: '1px solid rgba(255,255,255,.25)', fontFamily: 'system-ui'
    });
    btn.onclick = () => {
      const u = encodeURIComponent(location.href);
      const brand = /zara/.test(location.host) ? 'zara' : (/hm/.test(location.host) ? 'hm' : 'mango');
      window.location.href = `https://tryon.example/try?u=${u}&brand=${brand}`;
    };
    document.body.appendChild(btn);
  }

  if (isProductPage()) injectButton();
})();

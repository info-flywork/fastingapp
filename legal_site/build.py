"""MochiFast yasal sayfaları (fly-work.com/mochifast/...) üretir.

Çıktı: legal_site/mochifast/{privacy-policy,terms,cookies,csae}/index.html
Her sayfa tek dosya (CSS/JS gömülü), Türkçe + İngilizce, çerez/depolama yok.
Çalıştır: python3 legal_site/build.py
"""

from pathlib import Path

from content import PAGES  # noqa: E402  (aynı klasör)

ROOT = Path(__file__).parent / "mochifast"
YEAR = "2026"
UPDATED = {"tr": "Son güncelleme: 27 Ekim 2026", "en": "Last updated: October 27, 2026"}
NAV = [
    ("privacy-policy", {"tr": "Gizlilik", "en": "Privacy"}),
    ("terms", {"tr": "Kullanım Koşulları", "en": "Terms"}),
    ("cookies", {"tr": "Çerezler", "en": "Cookies"}),
    ("csae", {"tr": "Çocuk Güvenliği", "en": "Child Safety"}),
]

TEMPLATE = """<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title_tr} · MochiFast</title>
<meta name="description" content="{desc}">
<meta name="robots" content="index,follow">
<style>
:root {{
  --green: #76AB6E; --green-soft: #C8DBC5; --green-bg: #F2F7F1;
  --text: #09090B; --muted: #55555E; --line: #E6E9E5; --bg: #FFFFFF;
}}
* {{ box-sizing: border-box; }}
html {{ -webkit-text-size-adjust: 100%; }}
body {{ margin: 0; background: var(--bg); color: var(--text);
  font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; }}
header {{ background: linear-gradient(180deg, var(--green-soft), var(--green-bg)); border-bottom: 1px solid var(--line); }}
.wrap {{ max-width: 820px; margin: 0 auto; padding: 0 20px; }}
.top {{ display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 18px 0 6px; }}
.brand {{ font-weight: 800; font-size: 22px; letter-spacing: -.3px; text-decoration: none; color: var(--text); }}
.brand span {{ color: var(--green); }}
.lang {{ display: inline-flex; border: 1px solid var(--line); border-radius: 999px; overflow: hidden; background: #fff; }}
.lang button {{ border: 0; background: transparent; padding: 6px 14px; font: inherit; font-size: 14px; cursor: pointer; color: var(--muted); }}
.lang button[aria-pressed="true"] {{ background: var(--green); color: #fff; }}
nav.pages {{ display: flex; flex-wrap: wrap; gap: 6px 16px; padding: 6px 0 16px; font-size: 14px; }}
nav.pages a {{ color: var(--muted); text-decoration: none; }}
nav.pages a.active {{ color: var(--text); font-weight: 600; border-bottom: 2px solid var(--green); }}
main {{ padding: 28px 0 48px; }}
h1 {{ font-size: 30px; line-height: 1.2; margin: 0 0 6px; letter-spacing: -.4px; }}
.updated {{ color: var(--muted); font-size: 14px; margin: 0 0 24px; }}
h2 {{ font-size: 20px; margin: 34px 0 8px; padding-top: 6px; border-top: 1px solid var(--line); }}
h3 {{ font-size: 16px; margin: 20px 0 4px; }}
p, li {{ color: #1c1c21; }}
ul {{ padding-left: 22px; }}
li {{ margin: 4px 0; }}
a {{ color: #4f8a47; }}
.note {{ background: var(--green-bg); border: 1px solid var(--green-soft); border-radius: 14px; padding: 14px 16px; margin: 16px 0; }}
.warn {{ background: #FFF6EE; border: 1px solid #F3D3BB; border-radius: 14px; padding: 14px 16px; margin: 16px 0; }}
table {{ width: 100%; border-collapse: collapse; margin: 12px 0; font-size: 15px; }}
th, td {{ text-align: left; vertical-align: top; padding: 9px 10px; border-bottom: 1px solid var(--line); }}
th {{ background: var(--green-bg); font-weight: 600; }}
.table {{ overflow-x: auto; }}
footer {{ border-top: 1px solid var(--line); color: var(--muted); font-size: 14px; padding: 22px 0 36px; }}
[data-lang] {{ display: none; }}
html[lang="tr"] [data-lang="tr"], html[lang="en"] [data-lang="en"] {{ display: block; }}
@media (max-width: 560px) {{ h1 {{ font-size: 25px; }} body {{ font-size: 15.5px; }} }}
</style>
</head>
<body>
<header>
  <div class="wrap">
    <div class="top">
      <a class="brand" href="../privacy-policy/">Mochi<span>Fast</span></a>
      <div class="lang" role="group" aria-label="Language">
        <button type="button" data-set="tr" aria-pressed="true">Türkçe</button>
        <button type="button" data-set="en" aria-pressed="false">English</button>
      </div>
    </div>
    <nav class="pages">{nav}</nav>
  </div>
</header>
<main class="wrap">
  <section data-lang="tr">
    <h1>{title_tr}</h1>
    <p class="updated">{updated_tr}</p>
{body_tr}
  </section>
  <section data-lang="en">
    <h1>{title_en}</h1>
    <p class="updated">{updated_en}</p>
{body_en}
  </section>
</main>
<footer>
  <div class="wrap">
    <span data-lang="tr">© {year} MochiFast · Fly Work. Tüm hakları saklıdır. İletişim: <a href="mailto:info@fly-work.com">info@fly-work.com</a></span>
    <span data-lang="en">© {year} MochiFast · Fly Work. All rights reserved. Contact: <a href="mailto:info@fly-work.com">info@fly-work.com</a></span>
  </div>
</footer>
<script>
/* Dil: ?lang=en / #en ya da tarayıcı dili. Çerez veya yerel depolama kullanılmaz. */
(function () {{
  var q = new URLSearchParams(location.search).get('lang') || location.hash.replace('#', '');
  var nav = (navigator.language || 'tr').slice(0, 2).toLowerCase();
  var lang = (q === 'tr' || q === 'en') ? q : (nav === 'tr' ? 'tr' : 'en');
  function set(l) {{
    document.documentElement.lang = l;
    document.querySelectorAll('.lang button').forEach(function (b) {{
      b.setAttribute('aria-pressed', String(b.dataset.set === l));
    }});
    document.querySelectorAll('nav.pages a').forEach(function (a) {{
      a.textContent = a.dataset[l];
      a.href = a.getAttribute('href').split('?')[0] + '?lang=' + l;
    }});
    var t = document.querySelector('section[data-lang="' + l + '"] h1');
    if (t) document.title = t.textContent + ' · MochiFast';
  }}
  document.querySelectorAll('.lang button').forEach(function (b) {{
    b.addEventListener('click', function () {{ set(b.dataset.set); }});
  }});
  set(lang);
}})();
</script>
</body>
</html>
"""


def build():
    for slug, page in PAGES.items():
        active = ' class="active"'
        nav = "".join(
            f'<a href="../{s}/" data-tr="{t["tr"]}" data-en="{t["en"]}"'
            f'{active if s == slug else ""}>{t["tr"]}</a>'
            for s, t in NAV
        )
        html = TEMPLATE.format(
            title_tr=page["title"]["tr"],
            title_en=page["title"]["en"],
            desc=page["desc"],
            nav=nav,
            updated_tr=UPDATED["tr"],
            updated_en=UPDATED["en"],
            body_tr=page["body"]["tr"],
            body_en=page["body"]["en"],
            year=YEAR,
        )
        out = ROOT / slug / "index.html"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(html, encoding="utf-8")
        print("written", out)


if __name__ == "__main__":
    build()

export function validatePosts(posts) {
  if (!Array.isArray(posts) || posts.length > 200) throw new Error('Formato articoli non valido (massimo 200).');
  const slugs = new Set();
  for (const p of posts) {
    if (!p || typeof p !== 'object') throw new Error('Articolo non valido.');
    for (const [key, max] of Object.entries({title:180,slug:120,category:80,excerpt:700,image:32,date:10,status:12})) {
      if (typeof p[key] !== 'string' || !p[key].trim() || p[key].length > max) throw new Error(`Campo ${key} mancante o troppo lungo.`);
    }
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(p.slug) || slugs.has(p.slug)) throw new Error('Gli indirizzi degli articoli devono essere validi e univoci.');
    slugs.add(p.slug);
    if (!/^\d+$/.test(p.image)) throw new Error('Seleziona una copertina del catalogo.');
    if (!['draft','published'].includes(p.status)) throw new Error('Stato non valido.');
    if (!/^\d{4}-\d{2}-\d{2}$/.test(p.date) || !Number.isFinite(Date.parse(p.date)) || new Date(p.date).toISOString().slice(0,10)!==p.date) throw new Error('Data non valida.');
    if (!Array.isArray(p.sections) || p.sections.length < 1 || p.sections.length > 40) throw new Error('Inserisci da 1 a 40 sezioni.');
    for(const s of p.sections) if(!s || typeof s.heading!=='string'||!s.heading.trim()||s.heading.length>200||typeof s.text!=='string'||!s.text.trim()||s.text.length>20000) throw new Error('Completa titolo e testo di ogni sezione.');
  }
  return posts.map(p=>Object.fromEntries(['title','slug','category','excerpt','image','date','status','sections'].map(k=>[k,k==='sections'?p.sections.map(s=>({heading:s.heading,text:s.text})):p[k]])));
}

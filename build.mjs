import {readFile,writeFile} from 'node:fs/promises';
const products=JSON.parse(await readFile(new URL('products.json',import.meta.url),'utf8'));
const escape=s=>s.replaceAll('&','&amp;').replaceAll('"','&quot;').replaceAll('<','&lt;');
const cards=products.map(([id,title,category,description],i)=>`<article class="product" data-category="${escape(category)}"><a class="product-image" href="https://www.etsy.com/listing/${id}" aria-label="${escape(title)} — view on Etsy"><img src="assets/${id}.jpg" alt="${escape(title)} printable product preview" width="340" height="270" loading="lazy"></a><h3><a href="https://www.etsy.com/listing/${id}">${escape(title)}</a></h3><p>${escape(description)}</p><a class="buy" href="https://www.etsy.com/listing/${id}" aria-label="View ${escape(title)} on Etsy">View on Etsy <span aria-hidden="true">↗</span></a></article>`).join('\n');
const filters=['All',...new Set(products.map(p=>p[2]))].map(c=>`<button type="button" data-filter="${escape(c)}" aria-pressed="${c==='All'}">${escape(c)}</button>`).join('');
const html=await readFile(new URL('template.html',import.meta.url),'utf8');
await writeFile(new URL('index.html',import.meta.url),html.replace('<!-- FILTERS -->',filters).replace('<!-- PRODUCTS -->',cards));
console.log(`Built ${products.length} products.`);

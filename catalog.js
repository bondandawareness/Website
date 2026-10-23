const cards=[...document.querySelectorAll('.product')];
const filters=[...document.querySelectorAll('[data-filter]')];
const more=document.querySelector('#show-more');
const status=document.querySelector('#catalog-status');
let category='All',expanded=false;
function update(){const matches=cards.filter(c=>category==='All'||c.dataset.category===category);cards.forEach(c=>c.hidden=true);matches.slice(0,expanded?matches.length:6).forEach(c=>c.hidden=false);status.textContent=`Showing ${Math.min(matches.length,expanded?matches.length:6)} of ${matches.length} digital downloads`;more.hidden=matches.length<=6||expanded;filters.forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.filter===category)));}
filters.forEach(b=>b.addEventListener('click',()=>{category=b.dataset.filter;expanded=false;update();}));
more.addEventListener('click',()=>{expanded=true;update();cards.filter(c=>!c.hidden)[6]?.querySelector('a')?.focus({preventScroll:true});});
update();

# Bond & Awareness

Static showcase for the existing Etsy shop. No checkout or customer database is hosted here.

## Update

- Edit `template.html` for page content and `styles.css` for styling.
- Update `products.json` for product IDs, editorial titles, categories and descriptions. Each entry's last field records its source Etsy thumbnail path.
- Product photos are stored locally in `assets/<listing-id>.jpg`.
- Run `npm run build` (Node.js, no dependencies) to regenerate `index.html`. Commit both source and generated HTML.
- `catalog.js` adds category filters and progressive display. Without JavaScript, all 22 products remain visible.

## Vercel

Import the GitHub repository using the Other framework preset. The included `vercel.json` builds the static page. Preserve the existing domain configuration. Deploy the redesign branch to a preview before merging into the production branch.

## Content

Catalog transcribed from the public Etsy shop on 2026-10-23. Product titles on this site are shortened editorial labels; the Etsy listing contains the full product details. Prices are intentionally left on Etsy, which is the source of truth for prices, availability, languages, policies and downloads. Catalog updates are manual.

Original logo and social URLs retained from the existing site. Original shop link corrected to `https://www.etsy.com/shop/BondAndAwareness`.

# Medical Timeline — local app

Runs a private SQLite/FTS medical-record timeline locally. It includes real search/filter/add-record endpoints and an optional Scrapling-powered URL extractor.

## Run

```bash
python app.py
```

Default: `http://127.0.0.1:119` (your requested `:0119` interpreted as TCP port **119**).

To use another port:

```bash
PORT=8119 python app.py
```

## Scrapling

The app dynamically imports Scrapling when present and supports `Fetcher`, `StealthyFetcher`, and `DynamicFetcher`. Install on the machine where you run this app:

```bash
pip install "scrapling[all]"
scrapling install
```

If Scrapling is unavailable, `/api/scrape` falls back to a plain HTTP fetch (no login bypass).

## Gmail / Drive

The seed database was compiled from the Gmail and Google Drive connector searches performed in this chat. ChatGPT connector OAuth tokens are not exposed to this local process, so a local program cannot silently reuse that login. For a full local resync, add your own Google OAuth client credentials and implement a local sync against Gmail/Drive APIs, or export connector search results to JSON and POST records to `/api/records`.

## API

- `GET /api/health`
- `GET /api/records?q=...&category=All`
- `POST /api/records` JSON record
- `POST /api/scrape` `{ "url":"https://...", "mode":"fetcher|stealthy|dynamic", "save":false }`

The scraper does not bypass authentication or scrape private Google pages without an authenticated browser/session you explicitly provide on your own machine.

const VERSION = "8ddb2386293975a33e50c723df94283a890195af";
const PRECACHE = ["releases/8ddb2386293975a33e50c723df94283a890195af/index.apple-touch-icon.png", "releases/8ddb2386293975a33e50c723df94283a890195af/index.audio.position.worklet.js", "releases/8ddb2386293975a33e50c723df94283a890195af/index.audio.worklet.js", "releases/8ddb2386293975a33e50c723df94283a890195af/index.html", "releases/8ddb2386293975a33e50c723df94283a890195af/index.icon.png", "releases/8ddb2386293975a33e50c723df94283a890195af/index.js", "releases/8ddb2386293975a33e50c723df94283a890195af/index.pck", "releases/8ddb2386293975a33e50c723df94283a890195af/index.png", "releases/8ddb2386293975a33e50c723df94283a890195af/index.wasm", "releases/8ddb2386293975a33e50c723df94283a890195af/pwa-client.js", "manifest.webmanifest", "icons/icon-192.png", "icons/icon-512.png", "icons/icon-maskable-512.png", "icons/apple-touch-icon.png"];
const scope = new URL(self.registration.scope);
const cachePrefix = `skybound:${scope.pathname}:`;
const cacheName = cachePrefix + VERSION;
const shell = new URL(`releases/${VERSION}/index.html`, scope).href;

self.addEventListener("install", (event) => {
    event.waitUntil((async () => {
        const cache = await caches.open(cacheName);
        // Activate only after the entire playable release is available.
        await cache.addAll(PRECACHE.map((path) => new URL(path, scope).href));
        await self.skipWaiting();
    })());
});

self.addEventListener("activate", (event) => {
    event.waitUntil((async () => {
        // Keep one earlier release for tabs that still have that game running.
        const previous = (await caches.keys())
            .filter((name) => name.startsWith(cachePrefix) && name !== cacheName);
        await Promise.all(previous.slice(0, -1).map((name) => caches.delete(name)));
        await self.clients.claim();
    })());
});

self.addEventListener("message", (event) => {
    if (event.data === "SKYBOUND_VERSION") {
        event.source?.postMessage({ skyboundVersion: VERSION });
    }
});

self.addEventListener("fetch", (event) => {
    const request = event.request;
    const url = new URL(request.url);
    if (request.method !== "GET" || url.origin !== scope.origin ||
        !url.pathname.startsWith(scope.pathname)) {
        return;
    }
    if (request.mode === "navigate" &&
        (url.pathname === scope.pathname || url.pathname === scope.pathname + "index.html")) {
        event.respondWith((async () => {
            const cache = await caches.open(cacheName);
            return (await cache.match(shell)) || fetch(request);
        })());
    } else if (url.pathname.startsWith(scope.pathname + "releases/") ||
               url.pathname.startsWith(scope.pathname + "icons/") ||
               url.pathname === scope.pathname + "manifest.webmanifest") {
        event.respondWith((async () => {
            const cache = await caches.open(cacheName);
            return (await cache.match(request)) ||
                (await caches.match(request)) || fetch(request);
        })());
    }
});

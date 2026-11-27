const VERSION = "61f659cae43caf0be80d6c5b13c6ccaa144108ed";
const PRECACHE = ["releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/index.apple-touch-icon.png", "releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/index.audio.position.worklet.js", "releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/index.audio.worklet.js", "releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/index.html", "releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/index.icon.png", "releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/index.js", "releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/index.pck", "releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/index.png", "releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/index.wasm", "releases/61f659cae43caf0be80d6c5b13c6ccaa144108ed/pwa-client.js", "manifest.webmanifest", "icons/icon-192.png", "icons/icon-512.png", "icons/icon-maskable-512.png", "icons/apple-touch-icon.png"];
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

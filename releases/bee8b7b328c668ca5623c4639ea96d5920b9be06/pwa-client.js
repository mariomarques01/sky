(() => {
    if (!("serviceWorker" in navigator)) return;

    const serviceWorker = navigator.serviceWorker;
    const pageVersion = document.querySelector('meta[name="skybound-version"]').content;
    let reloading = false;

    function requestVersion() {
        serviceWorker.controller?.postMessage("SKYBOUND_VERSION");
    }

    serviceWorker.addEventListener("message", (event) => {
        const version = event.data?.skyboundVersion;
        if (event.source === serviceWorker.controller && version && version !== pageVersion && !reloading) {
            reloading = true;
            window.location.reload();
        }
    });
    serviceWorker.addEventListener("controllerchange", requestVersion);

    const workerUrl = new URL("../../service-worker.js", document.baseURI);
    serviceWorker.register(workerUrl, { updateViaCache: "none" }).then((registration) => {
        requestVersion();

        function checkForUpdate() {
            if (navigator.onLine) registration.update().catch(() => {});
        }

        window.addEventListener("online", checkForUpdate);
        document.addEventListener("visibilitychange", () => {
            if (!document.hidden) checkForUpdate();
        });
        window.setInterval(checkForUpdate, 60000);
    }).catch((error) => {
        console.warn("Skybound: não foi possível preparar o modo offline.", error);
    });
})();

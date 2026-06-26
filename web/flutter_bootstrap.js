{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    // Force loading CanvasKit from local files instead of the Google CDN
    canvasKitBaseUrl: "canvaskit/"
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  }
});

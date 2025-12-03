document.addEventListener('DOMContentLoaded', function () {
    if (window.mediumZoom) {
        // Zoom ALL common image formats + inline SVGs
        window.mediumZoom(
            '.doc img[src$=".svg"], \
             .doc img[src$=".png"], \
             .doc img[src$=".jpg"], \
             .doc img[src$=".jpeg"], \
             .doc img[src$=".gif"], \
             .doc svg',
            {
                background: 'rgba(0, 0, 0, 0.7)',
                margin: 24
            }
        );
    }
});

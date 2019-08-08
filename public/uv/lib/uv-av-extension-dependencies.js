define(function () {
    // https://developer.mozilla.org/en-US/Apps/Fundamentals/Audio_and_video_delivery/Live_streaming_web_audio_and_video
    // Dash is supported everywhere except safari
    // function isSafari() {
    //     // https://stackoverflow.com/questions/7944460/detect-safari-browser?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
    //     var isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    //     console.log('isSafari', isSafari);
    //     return isSafari;
    // }
    function isFormatAvailable(formats, format) {
        var isAvailable = formats.includes(format);
        //console.log('isFormatAvailable', format, isAvailable);
        return isAvailable;
    }
    function isHLSFormatAvailable(formats) {
        return isFormatAvailable(formats, 'application/vnd.apple.mpegurl') || isFormatAvailable(formats, 'vnd.apple.mpegurl');
    }
    function isMpegDashFormatAvailable(formats) {
        return isFormatAvailable(formats, 'application/dash+xml');
    }
    function canPlayHls() {
        return true;
    }
    return function (formats) {
        var alwaysRequired = ['TreeComponent', 'AVComponent', 'MetadataComponent', 'jquery-ui.min', 'jquery.ui.touch-punch.min', 'jquery.binarytransport', 'waveform-data'];
        if (isHLSFormatAvailable(formats) && canPlayHls()) {
            console.log('load HLS');
            return {
                sync: alwaysRequired.concat(['hls.min'])
            };
        }
        else if (isMpegDashFormatAvailable(formats)) {
            console.log('load mpeg dash');
            return {
                sync: alwaysRequired.concat(['dash.all.min'])
            };
        }
        else {
            console.log('adaptive streaming not available');
            return {
                sync: alwaysRequired
            };
        }
    };
});

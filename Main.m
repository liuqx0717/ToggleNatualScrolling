#import "Retry.h"
#import "ProcUtil.h"
#import "UiUtil.h"


static int
toggleNaturalScrolling(void)
{
    int ret = 0;

    openSystemSettingsTrackpad();

    pid_t pid = getSystemSettingsPid(3 /* maxWaitSec */);
    if (!pid) {
        NSLog(@"Failed to get System Settings pid");
        return 1;
    }

    AXUIElementRef window = getMainWindow(pid, 3 /* maxWaitSec */);
    if (!window) {
        NSLog(@"Failed to get main window");
        return 1;
    }

    AXUIElementRef scrollZoom = getChildElementByAttrString(window,
        // Modify the label string if using a different language.
        kAXDescription, @"Scroll & Zoom", 
        3 /* maxWaitSec */);
    if (!scrollZoom) {
        NSLog(@"Failed to get Scroll & Zoom tab");
        ret = 1;
        goto releaseWindow;
    }

    AXUIElementRef naturalScroll = nil;
    RETRY_BEGIN() {
        if (!clickElement(scrollZoom, 0 /* delaySec */)) {
            NSLog(@"Failed to click Scroll & Zoom tab");
            ret = 1;
            goto releaseScrollZoom;
        }
        naturalScroll = getChildElementByAttrString(window,
            kAXIdentifierAttribute, @"NaturalScrollingToggle",
            0 /* maxWaitSec */);
    } RETRY_END(!naturalScroll, 3 /* maxWaitSec */)
    if (!naturalScroll) {
        NSLog(@"Failed to get natural scrolling toggle");
        ret = 1;
        goto releaseScrollZoom;
    }

    if (!clickElement(naturalScroll, 0.1 /* delaySec */)) {
        NSLog(@"Failed to click natural scrolling");
        ret = 1;
        goto releaseNaturalScroll;
    }

    closeWindow(window, 1 /* delaySec */);

releaseNaturalScroll:
    CFRelease(naturalScroll);
releaseScrollZoom:
    CFRelease(scrollZoom);
releaseWindow:
    CFRelease(window);
    return ret;
}


int
main(int         argc,
     const char *argv[])
{
    int ret = 0;

    @autoreleasepool {
        ret = toggleNaturalScrolling();
    }

    return ret;
}

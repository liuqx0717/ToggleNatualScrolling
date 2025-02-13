#import "ProcUtil.h"

#import "Retry.h"

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>


bool
openSystemSettingsTrackpad(void)
{
    // Navigate directly to the "Mouse" tab (deep linking).
    // You need to navigate to Trackpad manually if this link does not work.
    NSString *url = @"x-apple.systempreferences:com.apple.Trackpad-Settings.extension";
    return [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}


pid_t
getSystemSettingsPid(double maxWaitSec)
{
    NSString *id = @"com.apple.systempreferences";
    NSArray *apps = nil;

    RETRY_BEGIN() {
        apps = [NSRunningApplication
                runningApplicationsWithBundleIdentifier:id];
    } RETRY_END(apps.count == 0, maxWaitSec)

    if (apps.count == 0) {
        return 0;
    }

    NSRunningApplication *app = apps.firstObject;
    return app.processIdentifier;
}

#import "UiUtil.h"

#import "Retry.h"

static NSString *
AXErrorToString(AXError error)
{
    switch (error) {
    case kAXErrorSuccess: return @"Success";
    case kAXErrorFailure: return @"Failure";
    case kAXErrorIllegalArgument: return @"Illegal Argument";
    case kAXErrorInvalidUIElement: return @"Invalid UI Element";
    case kAXErrorInvalidUIElementObserver: return @"Invalid UI Element Observer";
    case kAXErrorCannotComplete: return @"Cannot Complete";
    case kAXErrorAttributeUnsupported: return @"Attribute Unsupported";
    case kAXErrorActionUnsupported: return @"Action Unsupported";
    case kAXErrorNotificationUnsupported: return @"Notification Unsupported";
    case kAXErrorNotImplemented: return @"Not Implemented";
    case kAXErrorNotificationAlreadyRegistered: return @"Notification Already Registered";
    case kAXErrorNotificationNotRegistered: return @"Notification Not Registered";
    case kAXErrorAPIDisabled: return @"API Disabled (Accessibility permissions may be required)";
    case kAXErrorNoValue: return @"No Value";
    case kAXErrorParameterizedAttributeUnsupported: return @"Parameterized Attribute Unsupported";
    case kAXErrorNotEnoughPrecision: return @"Not Enough Precision";
    default: return [NSString stringWithFormat:@"Unknown AXError: %d", error];
    }
}


// On success, the caller should use CFRelease on the return value.
AXUIElementRef
getMainWindow(pid_t  pid,
              double maxWaitSec)
{
    AXUIElementRef app = AXUIElementCreateApplication(pid);
    if (!app) {
        NSLog(@"Failed to get app for pid %u", pid);
        return nil;
    }

    AXUIElementRef window = nil;
    AXError err = kAXErrorSuccess;
    RETRY_BEGIN() {
        err = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute,
                                            (CFTypeRef *)&window);
    } RETRY_END(err != kAXErrorSuccess, maxWaitSec)

    if (err != kAXErrorSuccess) {
        NSLog(@"Failed to get main window: %@", AXErrorToString(err));
    }
    CFRelease(app);
    return window;
}


// Recursively iterate all the child elements (including the 'element'
// parameter itself).
// If it succeeds, return YES.
bool
iterateAllChildElements(AXUIElementRef    element,
                        bool             *stopped,
                        ProcessElementCb  cb,
                        void             *private)
{
    if (!(*cb)(element, private)) {
        *stopped = YES;
        return YES;
    }

    CFArrayRef children = nil;
    AXError err = AXUIElementCopyAttributeValue(element,
                                                kAXChildrenAttribute,
                                                (CFTypeRef *)&children);
    if (err == kAXErrorNoValue) {
        return YES;
    } else if (err != kAXErrorSuccess) {
        NSLog(@"Failed to get child elements: %@", AXErrorToString(err));
        return NO;
    }

    bool success = YES;
    CFIndex count = CFArrayGetCount(children);
    for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef child =
            (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
        success = iterateAllChildElements(child, stopped, cb, private);
        if (!success || *stopped) {
            break;
        }
    }

    // The array owns the child elements.
    CFRelease(children);
    return success;
}


typedef struct GetChildElementByAttrStringCtx {
    CFStringRef     attr;
    NSString       *expectValue;
    AXUIElementRef  result;
} GetChildElementByAttrStringCtx;

static bool
getChildElementByAttrStringCb(AXUIElementRef  element,
                              void           *private)
{
    GetChildElementByAttrStringCtx *ctx = private;
    CFStringRef value = nil;
    AXError err = AXUIElementCopyAttributeValue(element, ctx->attr,
                                                (CFTypeRef *)&value);
    if (err != kAXErrorSuccess) {
        // Ignore failures here.
        return YES;
    }

    if ([(__bridge NSString *)value isEqualToString:ctx->expectValue]) {
        // Now ctx->result has the ownership.
        ctx->result = (AXUIElementRef)CFRetain(element);
        CFRelease(value);
        return NO;
    }

    CFRelease(value);
    return YES;
}

// Recursively iterate all the child elements, return the first element
// whose 'attr' attribute has a string value of 'value'.
// On success, the caller should use CFRelease on the return value.
AXUIElementRef
getChildElementByAttrString(AXUIElementRef  element,
                            CFStringRef     attr,
                            NSString       *value,
                            double          maxWaitSec)
{
    GetChildElementByAttrStringCtx ctx = {
        .attr        = attr,
        .expectValue = value,
    };

    RETRY_BEGIN() {
        bool stopped = NO;
        iterateAllChildElements(element, &stopped,
                                getChildElementByAttrStringCb, &ctx);
    } RETRY_END(!ctx.result, maxWaitSec)

    return ctx.result;
}


// Return YES on success.
bool
clickElement(AXUIElementRef element,
             double         delaySec)
{
    [NSThread sleepForTimeInterval:delaySec];

    AXError err = AXUIElementPerformAction(element, kAXPressAction);
    if (err != kAXErrorSuccess) {
        NSLog(@"Failed to click element: %@", AXErrorToString(err));
        return NO;
    }
    return YES;
}


bool
closeWindow(AXUIElementRef window,
            double         delaySec)
{
    [NSThread sleepForTimeInterval:delaySec];

    AXUIElementRef closeButton = nil;
    AXError err = AXUIElementCopyAttributeValue(window,
        kAXCloseButtonAttribute, (CFTypeRef *)&closeButton);
    if (err != kAXErrorSuccess) {
        NSLog(@"Failed to get close button: %@", AXErrorToString(err));
        return NO;
    }

    err = AXUIElementPerformAction(closeButton, kAXPressAction);
    CFRelease(closeButton);
    if (err != kAXErrorSuccess) {
        NSLog(@"Failed to click close button: %@", AXErrorToString(err));
        return NO;
    }

    return YES;
}


void
printElementAttributes(AXUIElementRef element)
{
    CFArrayRef attributeNames = nil;
    AXError err = AXUIElementCopyAttributeNames(element, &attributeNames);
    if (err != kAXErrorSuccess) {
        NSLog(@"Failed to get attributes: %@", AXErrorToString(err));
        return;
    }

    NSLog(@"---------------------------");
    CFIndex count = CFArrayGetCount(attributeNames);
    for (CFIndex i = 0; i < count; i++) {
        CFStringRef attrName =
            (CFStringRef)CFArrayGetValueAtIndex(attributeNames, i);
        CFTypeRef attrValue = nil;

        err = AXUIElementCopyAttributeValue(element, attrName, &attrValue);
        if (err == kAXErrorSuccess) {
            NSLog(@"%@: %@", attrName, attrValue);
            CFRelease(attrValue);
        } else {
            NSLog(@"%@: Failed: %@", attrName, AXErrorToString(err));
        }
    }
    NSLog(@"---------------------------");

    CFRelease(attributeNames);
}


static bool
printAllChildElementAttrsCb(AXUIElementRef  element,
                            void           *private)
{
    printElementAttributes(element);
    return YES;
}

void
printAllChildElementAttrs(AXUIElementRef  element)
{
    bool stopped = NO;

    iterateAllChildElements(element, &stopped,
                            printAllChildElementAttrsCb, NULL);
}

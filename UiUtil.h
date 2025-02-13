#import <sys/types.h>
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

// Return YES to continue.
typedef bool (*ProcessElementCb)(AXUIElementRef  element,
                                 void           *priv);

AXUIElementRef
getMainWindow(pid_t  pid,
              double maxWaitSec);

bool
iterateAllChildElements(AXUIElementRef    element,
                        bool             *stopped,
                        ProcessElementCb  cb,
                        void             *priv);

AXUIElementRef
getChildElementByAttrString(AXUIElementRef  element,
                            CFStringRef     attr,
                            NSString       *value,
                            double          maxWaitSec);

bool
clickElement(AXUIElementRef element,
             double         delaySec);

bool
closeWindow(AXUIElementRef window,
            double         delaySec);

void
printElementAttributes(AXUIElementRef element);

void
printAllChildElementAttrs(AXUIElementRef element);

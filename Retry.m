#import "Retry.h"

#define RETRY_DELAY_SEC 0.1


// Return whether we should retry. If yes, automatically add some delay.
bool
retryCheckAndWait(bool    retryCond,
                  NSDate *startTime,
                  double  maxWaitSec)
{
    if (!retryCond) {
        return NO;
    }

    double elapsedSec = [[NSDate date] timeIntervalSinceDate:startTime];
    if (elapsedSec >= maxWaitSec) {
        return NO;
    }

    [NSThread sleepForTimeInterval:RETRY_DELAY_SEC];
    return YES;
}
#import <Foundation/Foundation.h>

// The code enclosed by RETRY_BEGIN and RETRY_END must be idempotent.
#define RETRY_BEGIN()                                                     \
    {                                                                     \
        NSDate *__startTime = [NSDate date];                              \
        do

#define RETRY_END(retryCond, maxWaitSec)                                  \
        while (retryCheckAndWait(retryCond, __startTime, maxWaitSec));    \
    }

bool
retryCheckAndWait(bool    retryCond,
                  NSDate *startTime,
                  double  maxWaitSec);

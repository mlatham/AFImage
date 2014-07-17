// Logging macro.
#ifndef AFLog
	#ifdef DEBUG
		#define AFLog(format, ...) NSLog(format, ##__VA_ARGS__)
	#else
		#define AFLog(format, ...) do { } while (0)
	#endif
#endif

// Imports.
#import "AFImageCache.h"
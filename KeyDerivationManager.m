/*Copyright (c) 2010, Zachary Schneirov. All rights reserved.
  Redistribution and use in source and binary forms, with or without modification, are permitted
  provided that the following conditions are met:
   - Redistributions of source code must retain the above copyright notice, this list of conditions
     and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright notice, this list of
	 conditions and the following disclaimer in the documentation and/or other materials provided with
     the distribution.
   - Neither the name of Notational Velocity nor the names of its contributors may be used to endorse
     or promote products derived from this software without specific prior written permission. */


#import "KeyDerivationManager.h"
#import "AttributedPlainText.h"
#import "NotationPrefs.h"
#import "NSData_transformations.h"

@implementation KeyDerivationManager

+ (void)load {
    // The XIB historically referenced KeyDerivationDelaySlider (a custom
    // NSSlider subclass that did log/exp value mapping and forwarded a
    // mouse-up message). The class is gone; the slider in the nib is now
    // a plain NSSlider. Register the substitution so we don't have to
    // re-archive six localized binary nibs.
    [NSKeyedUnarchiver setClass:[NSSlider class]
                   forClassName:@"KeyDerivationDelaySlider"];
}

- (id)initWithNotationPrefs:(NotationPrefs*)prefs {
	notationPrefs = [prefs retain];

	//compute initial test duration for the current iteration number
	crapData = [[@"random crap" dataUsingEncoding:NSASCIIStringEncoding] retain];
	crapSalt = [[NSData randomDataOfLength:256] retain];

	lastHashIterationCount = [notationPrefs hashIterationCount];
	lastHashDuration = [self delayForHashIterations:lastHashIterationCount];

	if (!(self=[self init])) {
		[self release];
		return nil;
	}

	return self;
}

- (void)awakeFromNib {
	// Range is linear-in-log so the user can pick values spanning roughly
	// two orders of magnitude (~0.05 s … 4 s) with even resolution.
	[slider setMinValue:log(0.025)];
	[slider setMaxValue:log(3.5)];
	[slider setNumberOfTickMarks:10];
	[slider setTickMarkPosition:NSTickMarkBelow];
	[slider setAllowsTickMarkValuesOnly:NO];
	[slider setContinuous:YES];

	[self setSliderRealValue:lastHashDuration];
	[self sliderChanged:slider];

	[self updateToolTip];
}

- (id)init {
	if (self=[super init]) {
		if (!view) {
			if (![NSBundle loadNibNamed:@"KeyDerivationManager" owner:self])  {
				NSLog(@"Failed to load KeyDerivationManager.nib");
				NSBeep();
				return nil;
			}
		}

        return self;
	}
    return nil;
}

- (void)dealloc {
	[notationPrefs release];
	[crapData release];
	[crapSalt release];

	[super dealloc];
}

- (NSView*)view {
	return view;
}

- (int)hashIterationCount {
	return lastHashIterationCount;
}

- (void)updateToolTip {
	[slider setToolTip:[NSString stringWithFormat:NSLocalizedString(@"PBKDF2 iterations: %d", nil), lastHashIterationCount]];
}

// The slider stores its value in log space; expose convenience accessors in
// real (seconds) units so the rest of the class can stay in human-friendly
// units.
- (double)sliderRealValue {
	return exp([slider doubleValue]);
}

- (void)setSliderRealValue:(double)realSeconds {
	[slider setDoubleValue:log(realSeconds)];
}

- (IBAction)sliderChanged:(id)sender {
	double duration = [self sliderRealValue];

	[hashDurationField setAttributedStringValue:
		[NSAttributedString timeDelayStringWithNumberOfSeconds:duration]];

	// Continuous slider: the action also fires on mouse-up. Only run the
	// expensive PBKDF2 estimation on that terminal event.
	NSEvent *currentEvent = [[(NSControl *)sender window] currentEvent];
	if ([currentEvent type] == NSEventTypeLeftMouseUp) {
		lastHashIterationCount = [self estimatedIterationsForDuration:duration];

		if (duration > 0.7) [iterationEstimatorProgress startAnimation:nil];
		lastHashDuration = [self delayForHashIterations:lastHashIterationCount];
		if (duration > 0.7) [iterationEstimatorProgress stopAnimation:nil];

		// snap to the corrected position now that we know the real cost
		[self setSliderRealValue:lastHashDuration];

		[self updateToolTip];
	}
}

- (double)delayForHashIterations:(int)count {
	NSDate *before = [NSDate date];
	[crapData derivedKeyOfLength:[notationPrefs keyLengthInBits]/8 salt:crapSalt iterations:count];
	return [[NSDate date] timeIntervalSinceDate:before];
}

- (int)estimatedIterationsForDuration:(double)duration {
	//we could compute several hash durations at varying counts and use polynomial interpolation, but that may be overkill

	int count = (int)((duration * (double)lastHashIterationCount) / (double)lastHashDuration);

	int minCount = MAX(2000, count);
	//on a 1GHz machine, don't make them wait more than a minute
	return MIN(minCount, 9000000);
}

@end

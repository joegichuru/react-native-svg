/**
 * Copyright (c) 2015-present, Horcrux.
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTConvert+RNSVG.h"

#import "RNSVGPainterBrush.h"
#import "RNSVGSolidColorBrush.h"
#import "RNSVGContextBrush.h"
#import <React/RCTLog.h>
#import <React/RCTFont.h>

NSRegularExpression *RNSVGDigitRegEx;

@implementation RCTConvert (RNSVG)

RCT_ENUM_CONVERTER(RNSVGCGFCRule, (@{
                                     @"evenodd": @(kRNSVGCGFCRuleEvenodd),
                                     @"nonzero": @(kRNSVGCGFCRuleNonzero),
                                     }), kRNSVGCGFCRuleNonzero, intValue)

RCT_ENUM_CONVERTER(RNSVGVBMOS, (@{
                                  @"meet": @(kRNSVGVBMOSMeet),
                                  @"slice": @(kRNSVGVBMOSSlice),
                                  @"none": @(kRNSVGVBMOSNone)
                                  }), kRNSVGVBMOSMeet, intValue)

RCT_ENUM_CONVERTER(RNSVGColorMatrixTypes, (@{
                                  @"matrix": @(SVG_FECOLORMATRIX_TYPE_MATRIX),
                                  @"saturate": @(SVG_FECOLORMATRIX_TYPE_SATURATE),
                                  @"hueRotate": @(SVG_FECOLORMATRIX_TYPE_HUEROTATE),
                                  @"luminanceToAlpha": @(SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA)
                                  }), SVG_FECOLORMATRIX_TYPE_UNKNOWN, intValue)

RCT_ENUM_CONVERTER(RNSVGCompositeOperators, (@{
                                               @"over": @(SVG_FECOMPOSITE_OPERATOR_OVER),
                                               @"in": @(SVG_FECOMPOSITE_OPERATOR_IN),
                                               @"out": @(SVG_FECOMPOSITE_OPERATOR_OUT),
                                               @"atop": @(SVG_FECOMPOSITE_OPERATOR_ATOP),
                                               @"xor": @(SVG_FECOMPOSITE_OPERATOR_XOR),
                                               @"arithmetic": @(SVG_FECOMPOSITE_OPERATOR_ARITHMETIC)
                                               }), SVG_FECOMPOSITE_OPERATOR_UNKNOWN, intValue)

RCT_ENUM_CONVERTER(RNSVGEdgeModeValues, (@{
                                           @"duplicate": @(SVG_EDGEMODE_DUPLICATE),
                                           @"wrap": @(SVG_EDGEMODE_WRAP),
                                           @"none": @(SVG_EDGEMODE_NONE),
                                           }), SVG_EDGEMODE_UNKNOWN, intValue)

RCT_ENUM_CONVERTER(RNSVGBlendModeTypes, (@{
                                           @"normal": @(SVG_FEBLEND_MODE_NORMAL),
                                           @"multiply": @(SVG_FEBLEND_MODE_MULTIPLY),
                                           @"screen": @(SVG_FEBLEND_MODE_SCREEN),
                                           @"darken": @(SVG_FEBLEND_MODE_DARKEN),
                                           @"lighten": @(SVG_FEBLEND_MODE_LIGHTEN),
                                           }), SVG_FEBLEND_MODE_UNKNOWN, intValue)

RCT_ENUM_CONVERTER(RNSVGUnits, (@{
                                  @"objectBoundingBox": @(kRNSVGUnitsObjectBoundingBox),
                                  @"userSpaceOnUse": @(kRNSVGUnitsUserSpaceOnUse),
                                  }), kRNSVGUnitsObjectBoundingBox, intValue)

+ (RNSVGBrush *)RNSVGBrush:(id)json
{
    if ([json isKindOfClass:[NSNumber class]]) {
        return [[RNSVGSolidColorBrush alloc] initWithNumber:json];
    }
    if ([json isKindOfClass:[NSString class]]) {
        NSString *value = [self NSString:json];
        if (!RNSVGDigitRegEx) {
            RNSVGDigitRegEx = [NSRegularExpression regularExpressionWithPattern:@"[0-9.-]+" options:NSRegularExpressionCaseInsensitive error:nil];
        }
        NSArray<NSTextCheckingResult*> *_matches = [RNSVGDigitRegEx matchesInString:value options:0 range:NSMakeRange(0, [value length])];
        NSMutableArray<NSNumber*> *output = [NSMutableArray array];
        NSUInteger i = 0;
        [output addObject:[NSNumber numberWithInteger:0]];
        for (NSTextCheckingResult *match in _matches) {
            NSString* strNumber = [value substringWithRange:match.range];
            [output addObject:[NSNumber numberWithDouble:(i++ < 3 ? strNumber.doubleValue / 255 : strNumber.doubleValue)]];
        }
        if ([output count] < 5) {
            [output addObject:[NSNumber numberWithDouble:1]];
        }
        return [[RNSVGSolidColorBrush alloc] initWithArray:output];
    }
    NSArray *arr = [self NSArray:json];
    NSUInteger type = [self NSUInteger:arr.firstObject];

    switch (type) {
        case 0: // solid color
            // These are probably expensive allocations since it's often the same value.
            // We should memoize colors but look ups may be just as expensive.
            return [[RNSVGSolidColorBrush alloc] initWithArray:arr];
        case 1: // brush
            return [[RNSVGPainterBrush alloc] initWithArray:arr];
        case 2: // currentColor
            return [[RNSVGBrush alloc] initWithArray:nil];
        case 3: // context-fill
            return [[RNSVGContextBrush alloc] initFill];
        case 4: // context-stroke
            return [[RNSVGContextBrush alloc] initStroke];
        default:
            RCTLogError(@"Unknown brush type: %zd", (unsigned long)type);
            return nil;
    }
}

+ (RNSVGPathParser *)RNSVGCGPath:(NSString *)d
{
    return [[RNSVGPathParser alloc] initWithPathString: d];
}

+ (RNSVGLength *)RNSVGLength:(id)json
{
    if ([json isKindOfClass:[NSNumber class]]) {
        return [RNSVGLength lengthWithNumber:(CGFloat)[json doubleValue]];
    } else if ([json isKindOfClass:[NSString class]]) {
        NSString *stringValue = (NSString *)json;
        return [RNSVGLength lengthWithString:stringValue];
    } else {
        return [[RNSVGLength alloc] init];
    }
}

+ (NSArray<RNSVGLength *>*)RNSVGLengthArray:(id)json
{
    if ([json isKindOfClass:[NSNumber class]]) {
        RNSVGLength* length = [RNSVGLength lengthWithNumber:(CGFloat)[json doubleValue]];
        return [NSArray arrayWithObject:length];
    } else if ([json isKindOfClass:[NSArray class]]) {
        NSArray *arrayValue = (NSArray*)json;
        NSMutableArray<RNSVGLength*>* lengths = [NSMutableArray arrayWithCapacity:[arrayValue count]];
        for (id obj in arrayValue) {
            [lengths addObject:[self RNSVGLength:obj]];
        }
        return lengths;
    }  else if ([json isKindOfClass:[NSString class]]) {
        NSString *stringValue = (NSString *)json;
        RNSVGLength* length = [RNSVGLength lengthWithString:stringValue];
        return [NSArray arrayWithObject:length];
    } else {
        return nil;
    }
}

+ (CGRect)RNSVGCGRect:(id)json offset:(NSUInteger)offset
{
    NSArray *arr = [self NSArray:json];
    if (arr.count < offset + 4) {
        RCTLogError(@"Too few elements in array (expected at least %zd): %@", (ssize_t)(4 + offset), arr);
        return CGRectZero;
    }
    return (CGRect){
        {[self CGFloat:arr[offset]], [self CGFloat:arr[offset + 1]]},
        {[self CGFloat:arr[offset + 2]], [self CGFloat:arr[offset + 3]]},
    };
}

+ (CGColorRef)RNSVGCGColor:(id)json offset:(NSUInteger)offset
{
    NSArray *arr = [self NSArray:json];
    if (arr.count == offset + 1) {
        return [self CGColor:[arr objectAtIndex:offset]];
    }
    if (arr.count < offset + 4) {
        RCTLogError(@"Too few elements in array (expected at least %zd): %@", (ssize_t)(4 + offset), arr);
        return nil;
    }
    return [self CGColor:[arr subarrayWithRange:(NSRange){offset, 4}]];
}

+ (CGGradientRef)RNSVGCGGradient:(id)json
{
    NSArray *arr = [self NSArray:json];
    NSUInteger count = arr.count / 2;
    NSUInteger values = count * 5;
    NSUInteger offsetIndex = values - count;
    CGFloat colorsAndOffsets[values];
    for (NSUInteger i = 0; i < count; i++) {
        NSUInteger stopIndex = i * 2;
        CGFloat offset = (CGFloat)[arr[stopIndex] doubleValue];
        NSUInteger argb = [self NSUInteger:arr[stopIndex + 1]];

        CGFloat a = ((argb >> 24) & 0xFF) / 255.0;
        CGFloat r = ((argb >> 16) & 0xFF) / 255.0;
        CGFloat g = ((argb >> 8) & 0xFF) / 255.0;
        CGFloat b = (argb & 0xFF) / 255.0;

        NSUInteger colorIndex = i * 4;
        colorsAndOffsets[colorIndex] = r;
        colorsAndOffsets[colorIndex + 1] = g;
        colorsAndOffsets[colorIndex + 2] = b;
        colorsAndOffsets[colorIndex + 3] = a;

        colorsAndOffsets[offsetIndex + i] = fmax(0, fmin(offset, 1));
    }

    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(
                                                                 rgb,
                                                                 colorsAndOffsets,
                                                                 colorsAndOffsets + offsetIndex,
                                                                 count
                                                                 );
    CGColorSpaceRelease(rgb);
    return (CGGradientRef)CFAutorelease(gradient);
}

@end


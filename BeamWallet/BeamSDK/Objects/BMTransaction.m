//
//  BMTransaction.m
//  BeamWallet
//
// 3/5/19.
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "BMTransaction.h"

@implementation BMTransaction

-(NSString*)formattedDate {
    NSDateFormatter *f = [NSDateFormatter new];
    [f setDateFormat:@"dd MMM yyyy  |  HH:mm"];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_createdTime];
    
    return [f stringFromDate:date];
}

@end
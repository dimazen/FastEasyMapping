
#import "FEMDeserializationInfo.h"

@implementation FEMDeserializationInfo

- (instancetype)initWithMapping:(FEMMapping *)mapping
           presentedPrimaryKeys:(NSDictionary <NSNumber *, NSSet<id> *> *)presentedPrimaryKeys
                 representation:(NSArray <id> *)representation {
    self = [super init];
    if (self != nil) {
        self.mapping = mapping;
        self.presentedPrimaryKeys = presentedPrimaryKeys;
        self.representation = representation;
    }
    return self;
}

@end

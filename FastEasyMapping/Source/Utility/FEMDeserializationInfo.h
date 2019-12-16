
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FEMMapping;

@interface FEMDeserializationInfo : NSObject

@property (nonatomic, strong) NSArray <id> *representation;
@property (nonatomic, strong) FEMMapping *mapping;
@property (nonatomic, strong, nullable) NSDictionary <NSNumber *, NSSet<id> *> *presentedPrimaryKeys;

- (instancetype)initWithMapping:(FEMMapping *)mapping
           presentedPrimaryKeys:(nullable NSDictionary <NSNumber *, NSSet<id> *> *)presentedPrimaryKeys
                 representation:(NSArray <id> *)representation;

@end

NS_ASSUME_NONNULL_END

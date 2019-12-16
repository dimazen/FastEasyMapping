
#import "FallbackObjectStore.h"
#import "FEMObjectStore.h"
#import "FEMObjectCache.h"
#import "FEMDeserializationInfo.h"
#import "FEMMapping.h"
#import "FEMRepresentationUtility.h"

@interface FallbackObjectStore ()

@property (nonatomic, strong) FEMObjectCache *messagesCache;
@property (nonatomic, strong) FEMMapping *messageMapping;

@end

@implementation FallbackObjectStore

- (void)beginTransaction:(FEMDeserializationInfo *)info {
    [super beginTransaction:info];
    
    // here we can inspect mapping to see whether it includes messages to handle our special case:
    FEMMapping *mapping = info.mapping;
    
    if (![[[mapping flatten] valueForKey:@"entityName"] containsObject:@"Message"]) {
      // default case, no extra handling is needed.
      return;
    }
    
    // now let's alter Message's mapping to use clientID as the primary key to collect presented clientIDs
    FEMMapping *fallbackMapping = [mapping copy];
    // here we're flattening the hierarchy because it is not clear where exactly our mapping lies.
    for (FEMMapping *mapping in [fallbackMapping flatten]) {
      if ([mapping.entityName isEqual:@"Message"]) {
        // this was previously set to `id` so let's change it to a clientId to grab all primary keys below.
        mapping.primaryKey = @"clientId";
        // we also need to use this mapping later on so let's save it.
        self.messageMapping = mapping;
        break;
      }
    }

    if (self.messageMapping != nil) {
        // Now when all changes are done we can collect primary keys for clientId for a proper prefetch. It won't hurt us, since prefetch is lazy.
        NSDictionary<NSNumber *, NSSet<id> *> *presentedPrimaryKeys = FEMRepresentationCollectPresentedPrimaryKeys(info.representation, fallbackMapping);
        self.messagesCache = [[FEMObjectCache alloc] initWithContext:self.context presentedPrimaryKeys:presentedPrimaryKeys];
    }
}

- (NSError *)commitTransaction {
    self.messagesCache = nil;
    self.messageMapping = nil;
    
    return [super commitTransaction];
}

- (nullable id)objectForPrimaryKey:(id)primaryKey mapping:(FEMMapping *)mapping representation:(id)representation {
    id object = [super objectForPrimaryKey:primaryKey mapping:mapping representation:representation];
    // if either object is not nil or it is not a mapping - let's skip it's handling.
    if (object != nil || ![mapping.entityName isEqual:@"Message"]) {
        return object;
    } else {
      // it is a message, and it is nil, i.e. no object with such id is known to our database
      // so we can try to fetch it by the cliendId
        FEMAttribute *primaryKeyAttribute = self.messageMapping.primaryKeyAttribute;
        if (primaryKeyAttribute) {
            id fallbackPrimaryKey = FEMRepresentationValueForAttribute(representation, primaryKeyAttribute);
            if (fallbackPrimaryKey != nil && fallbackPrimaryKey != [NSNull null]) {
                return [self.messagesCache objectForKey:fallbackPrimaryKey mapping:self.messageMapping];
            }
        }
        
        return nil;
    }
}

- (void)addObject:(id)object forPrimaryKey:(id)primaryKey mapping:(FEMMapping *)mapping representation:(id)representation {
    [super addObject:object forPrimaryKey:primaryKey mapping:mapping representation:representation];
    
    if ([mapping.entityName isEqual:@"Message"]) {
        id fallbackPrimaryKey = [object valueForKey:self.messageMapping.primaryKey];
        if (fallbackPrimaryKey != nil) {
            [self.messagesCache setObject:object forKey:fallbackPrimaryKey mapping:self.messageMapping];
        }
    }
}

@end

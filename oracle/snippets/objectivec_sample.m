#import <Foundation/Foundation.h>
#import "User.h"

// Сервис пользователей
@interface UserService : NSObject <NSCopying>
@property (nonatomic, strong) NSArray<NSString *> *users;
@property (nonatomic, assign, readonly) NSInteger count;
- (instancetype)initWithUsers:(NSArray<NSString *> *)users;
- (NSString *)greetingForUser:(NSString *)name atIndex:(NSUInteger)idx;
@end

@implementation UserService {
    NSMutableDictionary *_cache;
}

@synthesize users = _users;

- (instancetype)initWithUsers:(NSArray<NSString *> *)users {
    self = [super init];
    if (self) {
        _users = [users copy];
        _cache = [@{} mutableCopy];
    }
    return self;
}

- (NSString *)greetingForUser:(NSString *)name atIndex:(NSUInteger)idx {
    NSString *key = [NSString stringWithFormat:@"%lu:%@", (unsigned long)idx, name];
    return _cache[key] ?: [NSString stringWithFormat:@"Привет, %@!", name];
}

+ (void)initialize {
    NSLog(@"init %f", 3.14);
}

@end

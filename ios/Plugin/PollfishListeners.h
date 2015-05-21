#import <Foundation/Foundation.h>
#include "CoronaLua.h"

@interface PollfishListeners : NSObject {
    lua_State*      L;
    CoronaLuaRef    luaRef;
}

-(void) setLuaState: (lua_State*) newState andLuaRef: (CoronaLuaRef) newRef;;
-(void) sendEvent: (NSString*) eventName;

@end
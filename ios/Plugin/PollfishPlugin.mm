#import "PollfishPlugin.h"

#import <Pollfish/Pollfish.h>
#import "PollfishListeners.h"

#import "CoronaRuntime.h"

#include "CoronaAssert.h"
#include "CoronaEvent.h"
#include "CoronaLua.h"
#include "CoronaLibrary.h"

#import "PollfishPlugin.h"


namespace Corona
{
    class pollfishLibrary
    {
        public:
        typedef pollfishLibrary Self;
        
        public:
        static const char kName[];
        static const char kEvent[];
        
        protected:
        pollfishLibrary();
        
        public:
        bool Initialize( CoronaLuaRef listener );
        
        public:
        CoronaLuaRef GetListener() const { return fListener; }
        
        public:
        static int Open( lua_State *L );
        
        protected:
        static int Finalizer( lua_State *L );
        
        public:
        static Self *ToLibrary( lua_State *L );
        
        public:
        static int init( lua_State *L );
        static int initWithRequestUUID( lua_State *L );
        static int show( lua_State *L );
        static int hide( lua_State *L );
        
        private:
        CoronaLuaRef fListener;
    };
    
    // ----------------------------------------------------------------------------
    
    // This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
    const char pollfishLibrary::kName[] = "plugin.pollfish";
    
    // This corresponds to the event name, e.g. [Lua] event.name
    const char pollfishLibrary::kEvent[] = "PluginPollfishEvent";
    
    pollfishLibrary::pollfishLibrary()
    :	fListener( NULL )
    {
    }
    
    bool
    pollfishLibrary::Initialize( CoronaLuaRef listener )
    {
        // Can only initialize listener once
        bool result = ( NULL == fListener );
        
        if ( result )
        {
            fListener = listener;
        }
        
        return result;
    }
    
    int
    pollfishLibrary::Open( lua_State *L )
    {
        // Register __gc callback
        const char kMetatableName[] = __FILE__; // Globally unique string to prevent collision
        CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );
        
        // Functions in library
        const luaL_Reg kVTable[] =
        {
            { "init", init },
            { "show", show },
            { "hide", hide },
            { NULL, NULL }
        };
        
        // Set library as upvalue for each library function
        Self *library = new Self;
        CoronaLuaPushUserdata( L, library, kMetatableName );
        
        luaL_openlib( L, kName, kVTable, 1 ); // leave "library" on top of stack
        
        return 1;
    }
    
    int
    pollfishLibrary::Finalizer( lua_State *L )
    {
        Self *library = (Self *)CoronaLuaToUserdata( L, 1 );
        CoronaLuaDeleteRef( L, library->GetListener() );
        delete library;
        
        return 0;
    }
    
    pollfishLibrary *
    pollfishLibrary::ToLibrary( lua_State *L )
    {
        // library is pushed as part of the closure
        Self *library = (Self *)CoronaLuaToUserdata( L, lua_upvalueindex( 1 ) );
        return library;
    }
    
    int
    pollfishLibrary::init( lua_State *L )
    {
        // Pollfish init params
        
        int pos=0;
        int indPadding =0;
        const char *apiKey = NULL;
        bool debugMode = true;
        bool customMode = true;
        const char *requestUUID = NULL;
        
        // The listener reference
        Corona::Lua::Ref listenerRef = NULL;
        
        // If an options table has been passed
        if ( lua_type( L, -1 ) == LUA_TTABLE )
        {
            // Get listener key
            lua_getfield( L, -1, "listener" );
            
            if ( Lua::IsListener( L, -1, "pollfish" ) )
            {
                // Set the listener reference
                listenerRef = Corona::Lua::NewRef( L, -1 );
              
            }
            lua_pop( L, 1 );
            
            // Get Pollfish indicator position
            lua_getfield( L, -1, "pos" );
            
            if ( lua_type( L, -1 ) == LUA_TNUMBER )
            {
                pos = lua_tonumber( L, -1 );
                
                //NSLog(@"Pollfish position: %d" , pos );
            }
            else
            {
                luaL_error( L, "Error: Pollfish position expected but received: %s", luaL_typename( L, -1 ) );
            }
            
            lua_pop( L, 1 );
            
            // Get Pollfish indicator padding
            lua_getfield( L, -1, "indPadding" );
            
            if ( lua_type( L, -1 ) == LUA_TNUMBER )
            {
                indPadding = lua_tonumber( L, -1 );
                
                //NSLog(@"Pollfish indicator padding: %d" , indPadding );
            }
            else
            {
                luaL_error( L, "Error: Pollfish indicator padding expected but received: %s", luaL_typename( L, -1 ) );
            }
            
            lua_pop( L, 1 );
            
            // Get Pollfish app's api key
            
            lua_getfield( L, -1, "apiKey" );
            
            if ( lua_type( L, -1 ) == LUA_TSTRING )
            {
                apiKey = lua_tostring( L, -1 );
                
                //NSLog(@"Pollfish apiKey: %s" , apiKey );
                
            }
            else
            {
                luaL_error( L, "Error: Pollfish api key expected but received: %s", luaL_typename( L, -1 ) );
            }
            
            lua_pop( L, 1 );
            
            // Get if Pollfish is in debug mode
            lua_getfield( L, -1, "debugMode" );
            
            if ( lua_type( L, -1 ) == LUA_TBOOLEAN )
            {
                debugMode = lua_toboolean(L, -1 );
                
                //NSLog(@"Pollfish debugMode: %@" , debugMode?@"true":@"false" );
            }
            else
            {
                luaL_error( L, "Error: Pollfish debug mode expected but received: %s", luaL_typename( L, -1 ) );
            }
           
            lua_pop( L, 1 );
            
            
            // Get if Pollfish is in custom mode
            lua_getfield( L, -1, "customMode" );
            
            if ( lua_type( L, -1 ) == LUA_TBOOLEAN )
            {
                customMode = lua_toboolean(L, -1 );
                
                //NSLog(@"Pollfish customMode: %@" , customMode?@"true":@"false" );
                
            }
            else
            {
                luaL_error( L, "Error: Pollfish custom mode expected but received: %s", luaL_typename( L, -1 ) );
            }
            
            lua_pop( L, 1 );
            
            // Get requestUUID param to be sent for s2s on survey completion
            
            lua_getfield( L, -1, "requestUUID" );
            
            if ( lua_type( L, -1 ) == LUA_TSTRING )
            {
                requestUUID = lua_tostring( L, -1 );
                
                NSLog(@"Pollfish requestUUID: %s" , requestUUID );
                
            }
            else
            {
                //luaL_error( L, "Error: Pollfish requestUUID field not provided but received: %s", luaL_typename( L, -1 ) );
                
                //NSLog(@"Pollfish requestUUID field not provided");
                
            }
           
            lua_pop( L, 1 );
            
            // Pop the options table
            lua_pop( L, 1 );
        }
        // No options table passed in
        else
        {
            luaL_error( L, "Error: pollfish.init(), params table expected but got %s", luaL_typename( L, -1 ) );
        }
        
        if ( listenerRef != NULL )
        {
            Self *library = ToLibrary( L );
            
            // set Pollfish listeners
            
            PollfishListeners* pollfishListeners = [PollfishListeners alloc];
            
            library->Initialize( listenerRef );
            [pollfishListeners setLuaState:L andLuaRef:listenerRef];
            
            if(requestUUID==NULL)
            
            {
                NSLog(@"Pollfish init with indicator Poisition: %d and indicator padding: %d and api app key: %@ and debug mode: %@ and custom mode: %@",pos,indPadding,[NSString stringWithUTF8String:apiKey],debugMode?@"true":@"false" , customMode?@"true":@"false" );
                
                [Pollfish initAtPosition:pos withPadding:indPadding
                         andDeveloperKey:[NSString stringWithUTF8String:apiKey] andDebuggable:debugMode andCustomMode:customMode];
            }else{
               
                NSLog(@"Pollfish init with indicator Poisition: %d and indicator padding: %d and api app key: %@ and debug mode: %@ and custom mode: %@ and requestUUID: %@",pos,indPadding,[NSString stringWithUTF8String:apiKey],debugMode?@"true":@"false " , customMode?@"true":@"false",[NSString stringWithUTF8String:requestUUID] );
                
                [Pollfish initAtPosition:pos withPadding:indPadding
                         andDeveloperKey:[NSString stringWithUTF8String:apiKey] andDebuggable:debugMode andCustomMode:customMode andRequestUUID:[NSString stringWithUTF8String:requestUUID]];
            }
            
            
        }else{
            
            NSLog(@"listenerRef in null");
        }
        
        return 0;
    }
    
    int
    pollfishLibrary::show( lua_State *L )
    {
        int listenerIndex = 1;
        
        
        if ( CoronaLuaIsListener( L, listenerIndex, kEvent ) )
        {
            Self *library = ToLibrary( L );
            
            CoronaLuaRef listener = CoronaLuaNewRef( L, listenerIndex );
            library->Initialize( listener );
            
            NSLog(@"Pollfish show");
            
            [Pollfish show];
        }
        
        return 0;
    }
    
    int
    pollfishLibrary::hide( lua_State *L )
    {
        int listenerIndex = 1;
        
        if ( CoronaLuaIsListener( L, listenerIndex, kEvent ) )
        {
            Self *library = ToLibrary( L );
            
            CoronaLuaRef listener = CoronaLuaNewRef( L, listenerIndex );
            library->Initialize( listener );
            
            NSLog(@"Pollfish hide");
            
            [Pollfish hide];
        }
        
        return 0;
    }
}

//
// ----------------------------------------------------------------------------

CORONA_EXPORT
int luaopen_plugin_pollfish( lua_State *L )
{
    return Corona::pollfishLibrary::Open( L );
}

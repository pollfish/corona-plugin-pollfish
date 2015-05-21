package plugin.pollfish;

import android.app.Activity;
import android.util.Log;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.naef.jnlua.LuaState;
import com.naef.jnlua.JavaFunction;
import com.naef.jnlua.NamedJavaFunction;

import com.ansca.corona.CoronaActivity;
import com.ansca.corona.CoronaEnvironment;
import com.ansca.corona.CoronaLua;
import com.ansca.corona.CoronaRuntime;
import com.ansca.corona.CoronaRuntimeListener;

import com.pollfish.*;
import com.pollfish.main.*;
import com.pollfish.main.PollFish;
import com.pollfish.constants.*;
import com.pollfish.constants.Position;
import com.pollfish.interfaces.PollfishClosedListener;
import com.pollfish.interfaces.PollfishOpenedListener;
import com.pollfish.interfaces.PollfishSurveyCompletedListener;
import com.pollfish.interfaces.PollfishSurveyReceivedListener;
import com.pollfish.interfaces.PollfishSurveyNotAvailableListener;
import com.pollfish.interfaces.PollfishUserNotEligibleListener;

/**
 * Implements the Lua interface for a Corona plugin.
 * <p>
 * Only one instance of this class will be created by Corona for the lifetime of the application.
 * This instance will be re-used for every new Corona activity that gets created.
 */
public class LuaLoader implements JavaFunction, CoronaRuntimeListener {

    private CoronaActivity fParentActivity;
    
    private static final String EVENT_NAME = "pluginlibraryevent";
    private static final String TAG = "Pollfish";

    private int fListener = CoronaLua.REFNIL;
    private LuaState luaState = null;
    
    /**
     * Creates a new Lua interface to this plugin.
     * <p>
     * Note that a new LuaLoader instance will not be created for every CoronaActivity instance.
     * That is, only one instance of this class will be created for the lifetime of the application process.
     * This gives a plugin the option to do operations in the background while the CoronaActivity is destroyed.
     */
    public LuaLoader() {
        
        // Initialize member variables.
        //fListener = CoronaLua.REFNIL;
        
        // Set up this plugin to listen for Corona runtime events to be received by methods
        // onLoaded(), onStarted(), onSuspended(), onResumed(), and onExiting().
       
        CoronaEnvironment.addRuntimeListener(this);
    }
    
    /**
     * Called when this plugin is being loaded via the Lua require() function.
     * <p>
     * Note that this method will be called everytime a new CoronaActivity has been launched.
     * This means that you'll need to re-initialize this plugin here.
     * <p>
     * Warning! This method is not called on the main UI thread.
     * @param L Reference to the Lua state that the require() function was called from.
     * @return Returns the number of values that the require() function will return.
     *         <p>
     *         Expected to return 1, the library that the require() function is loading.
     */
    @Override
    public int invoke(LuaState L) {
        
        CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
        
        // Validate.
        if (activity == null) {
            throw new IllegalArgumentException("Activity cannot be null.");
        }
        
        // Initialize member variables.
        fParentActivity = activity;
        
        // Register this plugin into Lua with the following functions.
        NamedJavaFunction[] luaFunctions = new NamedJavaFunction[] {
            new InitWrapper(),
            new ShowWrapper(),
            new HideWrapper()
        };
        
        String libName = L.toString( 1 );
        L.register(libName, luaFunctions);
        
        // Returning 1 indicates that the Lua require() function will return the above Lua library.
       
        return 1;
    }
    
    @Override
    public void onLoaded(CoronaRuntime runtime) {
    }
    
    @Override
    public void onStarted(CoronaRuntime runtime) {
    }
    
    @Override
    public void onSuspended(CoronaRuntime runtime) {
    }
    
    @Override
    public void onResumed(CoronaRuntime runtime) {
    }
    
    @Override
    public void onExiting(CoronaRuntime runtime) {
        
        // Remove the Lua listener reference.
        CoronaLua.deleteRef( runtime.getLuaState(), fListener );
        fListener = CoronaLua.REFNIL;
        
    }

    
    /*
     *   Send message to lua side
     */
    
    private void sendMessage( String msg )
    {
        
        Log.d(TAG, "sendMessage: " + msg);
        
        CoronaLua.newEvent( luaState, EVENT_NAME );
        
        luaState.pushString(msg);
        luaState.setField(-2, "phase" );
        
        // Dispatch event to library's listener
        
        try {
            CoronaLua.dispatchEvent( luaState, fListener, 0 );
        } catch (Exception e) {
            
            Log.e(TAG, "dispatchEvent exception: " + e);
        }
    }

    
    /*
     *   Pollfish init method
     */
    
    public int init(LuaState L) {
        
        luaState = L;
        
        try
        {
            // Pollfish init params
            
            int pos=0;
            int indPadding =0;
            String apiKey = null;
            boolean debugMode = true;
            boolean customMode = false;
            String requestUUID = null;
  
            // Chech if a parameters table has been passed
            
            if ( luaState.isTable( -1 ) )
            {
                // Get the listener field
                
                luaState.getField( -1, "listener" );
                
                if ( CoronaLua.isListener( luaState, -1, "pollfish" ) )
                {
                    // Assign the callback listener to a new lua ref
                    
                    fListener = CoronaLua.newRef( luaState, -1 );
                }
                else
                {
                    // Assign the listener to a nil ref
                    
                    fListener = CoronaLua.REFNIL;
                }
                
                luaState.pop( 1 );
                
                // Get Pollfish indicator Position
                
                luaState.getField( -1, "pos" );
                
                if ( luaState.isNumber(-1) )
                {
                    pos = (int)luaState.checkNumber(-1);
                    
                    Log.d(TAG, "Pollfish indicator position: " + pos);
               
                }else
                {
                    Log.e(TAG,"Error: Pollfish position expected but received: " + luaState.typeName( -1 ));
                }
                
                luaState.pop( 1 );
                
                // Get Pollfish indicator padding
                
                luaState.getField( -1, "indPadding" );
                
                if ( luaState.isNumber(-1) )
                {
                    indPadding = (int)luaState.checkNumber(-1);
                    
                    Log.d(TAG,"Pollfish indicator padding: " + indPadding);
                }
                else
                {
                    Log.e(TAG, "Error: Pollfish indicator padding expected but received: " + luaState.typeName(-1));
                    
                }
                
                luaState.pop( 1 );
                
                // Get Pollfish app's api key
                
                luaState.getField( -1, "apiKey" );
                
                if ( luaState.isString(-1) )
                {
                    apiKey = luaState.checkString(-1);
                    
                    Log.d(TAG,"Pollfish app api key: " + apiKey);
                }
                else
                {
                    Log.e(TAG,"Error: Pollfish api key expected but received: " + luaState.typeName( -1 ));
                }
               
                luaState.pop( 1 );
                
                // Get if pollfish is in debug mode
                
                luaState.getField( -1, "debugMode" );
                
                if ( luaState.isBoolean(-1) )
                {
                    debugMode = luaState.checkBoolean(-1, false);
                    
                    Log.d(TAG,"Pollfish debug mode: " + debugMode);
                }
                else
                {
                    Log.e(TAG,"Error: Pollfish debug mode expected but received: " + luaState.typeName( -1 ));
                    
                }
               
                luaState.pop( 1 );
                
                // Get if Pollfish is initialized in custom mode
                
                luaState.getField( -1, "customMode" );
                
                if ( luaState.isBoolean( -1 ) )
                {
                    customMode = luaState.checkBoolean( -1,false );
                    
                    Log.d(TAG,"Pollfish custom mode: " + customMode);
                }
                else
                {
                    Log.e(TAG,"Error: Pollfish custom mode expected but received: " + luaState.typeName( -1 ));
                    
                }
                
                luaState.pop( 1 );
                
                // Get requestUUID param to be sent for s2s on survey completion
                
                luaState.getField( -1, "requestUUID" );
                
                if ( luaState.isString( -1 ) )
                {
                    requestUUID = luaState.checkString( -1 );
                    
                    Log.d(TAG,"Pollfish requestUUID: " + requestUUID);
                }
                else
                {
                    //Log.e(TAG,"Error: Pollfish requestUUID key expected but received: " + luaState.typeName( -1 ));
                }
                
                luaState.pop( 1 );
         
                // Pop the parameters table
               
                luaState.pop( 1 );
            }
            // No parameters table passed in
            else
            {
                Log.e(TAG, "Error: pollfish.init(), parameters table expected but got " + luaState.typeName(-1));
            }
            
            final int indicatorPadding = indPadding;
            final String appApiKey = apiKey;
            final boolean initDebugMode=debugMode;
            final boolean initCustomMode=customMode;
            final String userRequestUUID = requestUUID;
            
            final Position indicatorPosition= Position.values()[pos];
 
            final PollfishSurveyReceivedListener pollfishSurveyReceivedListener = new PollfishSurveyReceivedListener() {
                
                @Override
                public void onPollfishSurveyReceived(boolean shortSurvey, int surveyPrice) {
                    
                    Log.d(TAG, "onPollfishSurveyReceived (" + shortSurvey  + ","+ String.valueOf(surveyPrice) + ")");
                    
                    sendMessage("onPollfishSurveyReceived");
                    
                }
            };
            
            final PollfishSurveyCompletedListener pollfishSurveyCompletedListener = new PollfishSurveyCompletedListener() {
                
                @Override
                public void onPollfishSurveyCompleted(boolean shortSurvey, int surveyPrice) {
                    
                    Log.d(TAG, "onPollfishSurveyCompleted (" + shortSurvey + ","+ String.valueOf(surveyPrice) + ")");
                    
                    sendMessage("onPollfishSurveyCompleted");
                }
            };
            
            final PollfishOpenedListener pollfishOpenedListener = new PollfishOpenedListener() {
                
                public void onPollfishOpened() {
                    
                    Log.d(TAG, "onPollfishOpened");
                    
                    sendMessage("onPollfishOpened");
                    
                }
            };
            
            final PollfishClosedListener pollfishClosedListener = new PollfishClosedListener() {
                
                public void onPollfishClosed() {
                    
                    Log.d(TAG, "onPollfishClosed");
                    
                    sendMessage("onPollfishClosed");
                    
                }
            };
            
            final PollfishSurveyNotAvailableListener pollfishSurveyNotAvailableListener = new PollfishSurveyNotAvailableListener() {
                public void onPollfishSurveyNotAvailable() {
                    
                    Log.d(TAG, "onPollfishSurveyNotAvailable");
                    
                    sendMessage("onPollfishSurveyNotAvailable");
                    
                    
                }
            };
            
            final PollfishUserNotEligibleListener pollfishUserNotEligibleListener = new PollfishUserNotEligibleListener() {
                public void onUserNotEligible() {
                    
                    Log.d(TAG, "onUserNotEligible");
                    
                    sendMessage("onUserNotEligible");
                    
                }
            };
            
            CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
            
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    // Fetch a reference to the Corona activity.
                    // Note: Will be null if the end-user has just backed out of the activity.
                    CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
                    
                    if (activity != null)
                    {
                        //with request param
                        if(userRequestUUID!=null) {
                            
                            if(!initCustomMode) {
                                
                                PollFish.init(fParentActivity, appApiKey, indicatorPosition, indicatorPadding, pollfishSurveyReceivedListener,
                                              pollfishSurveyNotAvailableListener,
                                              pollfishSurveyCompletedListener,
                                              pollfishOpenedListener, pollfishClosedListener,
                                              pollfishUserNotEligibleListener, null, userRequestUUID);
                            }else{
                                
                                PollFish.customInit(fParentActivity, appApiKey, indicatorPosition, indicatorPadding, pollfishSurveyReceivedListener,
                                                    pollfishSurveyNotAvailableListener,
                                                    pollfishSurveyCompletedListener,
                                                    pollfishOpenedListener, pollfishClosedListener,
                                                    pollfishUserNotEligibleListener, null, userRequestUUID);
                            }
                            
                        //without request param
                        }else{
                            
                            if(!initCustomMode) {
                                
                                PollFish.init(fParentActivity, appApiKey, indicatorPosition, indicatorPadding, pollfishSurveyReceivedListener,
                                              pollfishSurveyNotAvailableListener,
                                              pollfishSurveyCompletedListener,
                                              pollfishOpenedListener, pollfishClosedListener,
                                              pollfishUserNotEligibleListener);
                            }else{
                                
                                PollFish.customInit(fParentActivity, appApiKey, indicatorPosition, indicatorPadding, pollfishSurveyReceivedListener,
                                                    pollfishSurveyNotAvailableListener,
                                                    pollfishSurveyCompletedListener,
                                                    pollfishOpenedListener, pollfishClosedListener,
                                                    pollfishUserNotEligibleListener);
                            }
                        }
                    }
                }
            });
            
            
        }catch( Exception ex )
        {
            // An exception will occur if given an invalid argument or no argument. Print the error.
            Log.e(TAG, "An exception will occur if given an invalid argument or no argument. Print the error: " +ex);
        }
        
        return 0;
    }
    
    
    public int show(LuaState L) {
        
        Log.d(TAG, "user called show");
        
        CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
        
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                // Fetch a reference to the Corona activity.
                // Note: Will be null if the end-user has just backed out of the activity.
                CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
                
                if (activity != null)
                {
                    PollFish.show();
                }
            }
        });
        
        return 0;
    }
    
    public int hide(LuaState L) {
        
        Log.d(TAG, "user called hide");
        
        CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
       
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                // Fetch a reference to the Corona activity.
                // Note: Will be null if the end-user has just backed out of the activity.
                CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
                if (activity != null)
                {
                    PollFish.hide();
                }
            }
        });
        
        
        return 0;
    }

    
    private class InitWrapper implements NamedJavaFunction {
        
        @Override
        public String getName() {
            return "init";
        }
        
        @Override
        public int invoke(LuaState L) {
            return init(L);
        }
    }
  
    private class ShowWrapper implements NamedJavaFunction {
        @Override
        public String getName() {
            return "show";
        }
        
        @Override
        public int invoke(LuaState L) {
            return show(L);
        }
    }
   
    private class HideWrapper implements NamedJavaFunction {
        @Override
        public String getName() {
            return "hide";
        }
        
        @Override
        public int invoke(LuaState L) {
            return hide(L);
        }
    }
    
}

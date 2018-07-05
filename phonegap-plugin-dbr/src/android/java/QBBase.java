package qb;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.google.gson.Gson;
import com.quickblox.chat.QBChatService;
import com.quickblox.users.model.QBUser;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;

import qb.util.QBResRequestExecutor;

public class QBBase extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        super.execute(action, args, callbackContext);

        onLogoutCallback = null;

        if ("onLogout".equals(action)) {
            onLogoutCallback = callbackContext;
            return true;
        }

        return false;
    }

    private CallbackContext onLogoutCallback = null;
    private static Context instance = null;
    private static QBResRequestExecutor qbResRequestExecutor;

    protected Gson gson = new Gson();
    protected QBChatService chatService;
    protected QBResRequestExecutor requestExecutor;

    protected static QBUser currentUser = null;
    protected static boolean sdkInitialised = false;
    
    protected static Activity activity;


    /**
     * Initialise global interfaces which are made available to all activities which derive from this class
     * @param cordova
     * @param webView
     */
    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        cordova.setActivityResultCallback (this);

        Log.d("QBBase", "initialize");
        QBBase.activity = cordova.getActivity();
        QBBase.instance = cordova.getContext();

        qbResRequestExecutor = (qbResRequestExecutor == null)
                ? qbResRequestExecutor = new QBResRequestExecutor()
                : qbResRequestExecutor;
    }


    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        super.onActivityResult(requestCode, resultCode, intent);
        logMe("onActivityResult: " + requestCode);
    }


    public static Context getInstance(){
        return instance;
    }
    public static Activity getActivity(){
        return activity;
    }
    public static boolean isSdkInitialised() {
        return sdkInitialised;
    }

    public static QBResRequestExecutor getQBResRequestExecutor(){
        return qbResRequestExecutor;
    }


    protected void logMe(String msg) {
        Log.d("qb", "***" + this.getClass().getName() + "***: " + msg);
    }

}

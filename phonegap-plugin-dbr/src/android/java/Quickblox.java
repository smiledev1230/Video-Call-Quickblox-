package qb;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.google.gson.JsonArray;
import com.quickblox.auth.session.QBSettings;
import com.quickblox.core.QBEntityCallback;
import com.quickblox.core.exception.QBResponseException;
import com.quickblox.users.model.QBUser;
import com.quickblox.videochat.webrtc.QBRTCClient;
import com.quickblox.videochat.webrtc.QBRTCSession;
import com.quickblox.videochat.webrtc.QBRTCTypes;

import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Arrays;

import qb.activities.CallActivity;
import qb.utils.CollectionsUtils;
import qb.utils.Consts;
import qb.utils.PushNotificationSender;
import qb.utils.SharedPrefsHelper;
import qb.utils.WebRtcSessionManager;

import static org.webrtc.ContextUtils.getApplicationContext;


public class Quickblox extends QBBase {

    private static final String TAG = "QBPlugin";

    @Override
    public boolean execute( String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        super.execute(action, args, callbackContext);
        logMe("execute: " + action + ", " + args);
        
        if ("coolMethod".equals(action)) {
            echo(args.getString(0), callbackContext);
            return true;
        }else if ("initQB".equals(action)) {
            initializeSDK(callbackContext);
            return true;
        }else if ("getUsersQB".equals(action)) {
            if (QBBase.isSdkInitialised()){
                loadUsers(callbackContext);
            }else {
                JSONObject object = new JSONObject();
                object.put("message", "SDK not initialised.");
                callbackContext.error(object);
            }
            return true;
        }else if ("videoCallQB".equals(action)) {
            if (QBBase.isSdkInitialised()){
                videoCall(callbackContext, args.getJSONObject(0));
            }else {
                JSONObject object = new JSONObject();
                object.put("message", "SDK not initialised.");
                callbackContext.error(object);
            }
            return true;
        }

        return false;
    }


    private QBUser userForSave;
    
    static final String APP_ID = "69230";
    static final String AUTH_KEY = "3NxXvknqppdbRWs";
    static final String AUTH_SECRET = "Mdtcb4nWhczg8hr";
    static final String ACCOUNT_KEY = "e8P4p_Nxb4C68nctuPdT";

    private void initializeSDK(CallbackContext callbackContext) {
        QBSettings.getInstance().init(QBBase.getInstance(), APP_ID, AUTH_KEY, AUTH_SECRET);
        QBSettings.getInstance().setAccountKey(ACCOUNT_KEY);
        sdkInitialised = true;
    }

    private void loadUsers(CallbackContext callbackContext) {
        String currentRoomName = SharedPrefsHelper.getInstance().get(Consts.PREF_CURREN_ROOM_NAME);
        logMe("loadUsers: " + currentRoomName);

        QBBase.getQBResRequestExecutor().loadUsersByTag(currentRoomName, new QBEntityCallback<ArrayList<QBUser>>() {
            @Override
            public void onSuccess(ArrayList<QBUser> result, Bundle params) {
                try{
                    JSONArray res = new JSONArray(gson.toJson(result));
                    JSONObject succ = new JSONObject();
                    succ.put("users", res);
                    callbackContext.success(succ);
                }catch (JSONException e){
                    e.printStackTrace();
                }
            }

            @Override
            public void onError(QBResponseException responseException) {
                try{
                    JSONObject err = new JSONObject(gson.toJson(responseException));
                    callbackContext.error(err);
                }catch (JSONException e){
                    e.printStackTrace();
                }

            }
        });
    }


    private void videoCall(CallbackContext callbackContext, JSONObject jsonObject) {
        if (jsonObject.has("id")){
            try {
                Integer[] ids = {jsonObject.getInt("id")};
                startCall(ids, true);
            }catch (JSONException e){
                e.printStackTrace();
            }
        }
    }

    private void startCall(Integer[] opponents, boolean isVideoCall) {
        /*
        if (opponentsAdapter.getSelectedItems().size() > Consts.MAX_OPPONENTS_COUNT) {
            Toaster.longToast(String.format("You can select up to %d opponents",
                    Consts.MAX_OPPONENTS_COUNT));
            return;
        }*/

        Log.d(TAG, "startCall() " + opponents);

        ArrayList<Integer> opponentsList = new ArrayList<>(Arrays.asList(opponents));

        QBRTCTypes.QBConferenceType conferenceType = isVideoCall
                ? QBRTCTypes.QBConferenceType.QB_CONFERENCE_TYPE_VIDEO
                : QBRTCTypes.QBConferenceType.QB_CONFERENCE_TYPE_AUDIO;

        QBRTCClient qbrtcClient = QBRTCClient.getInstance(getApplicationContext());

        QBRTCSession newQbRtcSession = qbrtcClient.createNewSessionWithOpponents(opponentsList, conferenceType);

        WebRtcSessionManager.getInstance(QBBase.getInstance()).setCurrentSession(newQbRtcSession);

        PushNotificationSender.sendPushMessage(opponentsList, currentUser.getFullName());

        CallActivity.start(QBBase.getInstance(), false);
        Log.d(TAG, "conferenceType = " + conferenceType);

    }
    
    private void echo(String msg, CallbackContext callbackContext) {
        if (msg == null || msg.length() == 0) {
            callbackContext.error("Empty message!");
        } 
    }


}

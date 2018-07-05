package qb;

import android.app.PendingIntent;
import android.content.Intent;
import android.os.Bundle;
import android.telecom.Call;

import com.google.gson.JsonParseException;
import com.quickblox.core.QBEntityCallback;
import com.quickblox.core.QBEntityCallbackImpl;
import com.quickblox.core.exception.QBResponseException;
import com.quickblox.core.helper.StringifyArrayList;
import com.quickblox.core.helper.Utils;
import com.quickblox.users.model.QBUser;

import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import qb.utils.Consts;
import qb.utils.SharedPrefsHelper;
import qb.utils.UsersUtils;

public class Login extends QBBase {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        super.execute(action, args, callbackContext);
        logMe("execute: " + action + ", " + args);

        if ("loginQB".equals(action)) {
            if (QBBase.isSdkInitialised()){
                login(callbackContext, args.getJSONObject(0));
            }else {
//                JSONObject object = new JSONObject();
//                object.put("message", "SDK not initialised.");
                callbackContext.success(0);
            }
            return true;
        }
        return false;
    }



    private QBUser userForSave;
    private String fullName;
    private String roomName;

    private CallbackContext callback = null;

    private void login(CallbackContext callbackContext, JSONObject jsonObject) {
        logMe("login " + jsonObject);
        this.callback = callbackContext;
        if (currentUser != null) {
            loginWithCurrentUser();
        } else {
            if (jsonObject.has("full_name") && jsonObject.has("room_name")) {
                try {
                    fullName = jsonObject.getString("full_name");
                    roomName = jsonObject.getString("room_name");
                    signUpWithFullName();
                } catch (JsonParseException e) {
                    e.printStackTrace();
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }
    }


    private void loginWithCurrentUser() {
        if (currentUser == null) return;

        logMe("loginWithCurrentUser logged in: " + chatService.isLoggedIn());
        callback.success();
    }

    private void signUpWithFullName() {
        StringifyArrayList<String> userTags = new StringifyArrayList<>();
        userTags.add(roomName);
        
        QBUser user = new QBUser();
        user.setLogin(Utils.generateDeviceId(QBBase.getInstance()));
        user.setFullName(fullName);
        user.setTags(userTags);
        user.setPassword(Consts.DEFAULT_USER_PASSWORD);

        QBBase.getQBResRequestExecutor().signUpNewUser(user, new QBEntityCallback<QBUser>() {
                    @Override
                    public void onSuccess(QBUser result, Bundle params) {
                        loginToChat(result);
                    }

                    @Override
                    public void onError(QBResponseException e) {
                        if (e.getHttpStatusCode() == Consts.ERR_LOGIN_ALREADY_TAKEN_HTTP_STATUS) {
                            signInCreatedUser(user, true);
                        } else {
//                            hideProgressDialog();
//                            Toaster.longToast(R.string.sign_up_error);
                        }
                    }
                }
        );



/*
      // CREATE SESSION WITH USER
      // If you use create session with user data,
      // then the user will be logged in automatically
      QBAuth.createSession(user).performAsync(new QBEntityCallback<QBSession>() {
          @Override
          public void onSuccess(QBSession session, Bundle bundle) {

              user.setId(session.getUserId());

              // INIT CHAT SERVICE
              chatService = QBChatService.getInstance();

              // LOG IN CHAT SERVICE
              chatService.login(user, new QBEntityCallback<QBUser>() {

                  @Override
                  public void onSuccess(QBUser qbUser, Bundle bundle) {
                      currentUser = qbUser;
                      try{
                          JSONObject user = new JSONObject(gson.toJson(qbUser));
                          callbackContext.success(user);
                      }catch (JSONException e){
                          callbackContext.error(e.getMessage());
                      }
                  }

                  @Override
                  public void onError(QBResponseException e) {
                      e.printStackTrace();
                      try {
                          JSONObject err = new JSONObject(gson.toJson(e));
                          callbackContext.error(err);
                      }catch (JSONException e1){
                          e1.printStackTrace();
                          callbackContext.error(e1.getMessage());
                      }
                  }
              });
          }

          @Override
          public void onError(QBResponseException errors) {
              //error
              errors.printStackTrace();
              try {
                  JSONObject err = new JSONObject(gson.toJson(errors));
                  callbackContext.error(err);
              }catch (JSONException e1){
                  e1.printStackTrace();
                  callbackContext.error(e1.getMessage());
              }
          }
      });*/
    }

    private void loginToChat(final QBUser qbUser) {
        qbUser.setPassword(Consts.DEFAULT_USER_PASSWORD);

        userForSave = qbUser;
        // start LoginService
        Intent tempIntent = new Intent(QBBase.getInstance(), CallService.class);
        PendingIntent pendingIntent = QBBase.getActivity().createPendingResult(Consts.EXTRA_LOGIN_RESULT_CODE, tempIntent, 0);
        CallService.start(QBBase.getActivity(), qbUser, pendingIntent);
    }


    private void echo(String msg, CallbackContext callbackContext) {
        if (msg == null || msg.length() == 0) {
            callbackContext.error("Empty message!");
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == Consts.EXTRA_LOGIN_RESULT_CODE) {
//            hideProgressDialog();
            boolean isLoginSuccess = data.getBooleanExtra(Consts.EXTRA_LOGIN_RESULT, false);
            String errorMessage = data.getStringExtra(Consts.EXTRA_LOGIN_ERROR_MESSAGE);

            if (isLoginSuccess) {
                saveUserData(userForSave);

                signInCreatedUser(userForSave, false);
            } else {
//                Toaster.longToast("Login Chat error. Please relogin. Error" + errorMessage);
//                userNameEditText.setText(userForSave.getFullName());
//                chatRoomNameEditText.setText(userForSave.getTags().get(0));
                try {
                    JSONObject err = new JSONObject();
                    err.put("error", errorMessage);
                    callback.error(err);
                }catch (JSONException e1){
                    e1.printStackTrace();
                    callback.error(e1.getMessage());
                }

            }
        }
    }

    private void signInCreatedUser(final QBUser user, final boolean deleteCurrentUser) {
        QBBase.getQBResRequestExecutor().signInUser(user, new QBEntityCallbackImpl<QBUser>() {
            @Override
            public void onSuccess(QBUser result, Bundle params) {
                logMe("signInCreatedUser onSuccess delete? " + deleteCurrentUser);
                if (deleteCurrentUser) {
                    removeAllUserData(result);
                } else {
                    currentUser = result;
                    try{
                        JSONObject user = new JSONObject(gson.toJson(result));
                        callback.success(user);
                    }catch (JSONException e){
                        callback.error(e.getMessage());
                    }
                }
            }

            @Override
            public void onError(QBResponseException responseException) {
                try {
                    JSONObject err = new JSONObject(gson.toJson(responseException));
                    callback.error(err);
                }catch (JSONException e1){
                    e1.printStackTrace();
                    callback.error(e1.getMessage());
                }
            }
        });
    }


    private void removeAllUserData(final QBUser user) {
        QBBase.getQBResRequestExecutor().deleteCurrentUser(user.getId(), new QBEntityCallback<Void>() {
            @Override
            public void onSuccess(Void aVoid, Bundle bundle) {
                UsersUtils.removeUserData(QBBase.getInstance());
                signUpWithFullName();
            }

            @Override
            public void onError(QBResponseException e) {
                try {
                    JSONObject err = new JSONObject(gson.toJson(e));
                    callback.error(err);
                }catch (JSONException e1){
                    e1.printStackTrace();
                    callback.error(e1.getMessage());
                }
            }
        });
    }


    private void saveUserData(QBUser qbUser) {
        SharedPrefsHelper sharedPrefsHelper = SharedPrefsHelper.getInstance();
        sharedPrefsHelper.save(Consts.PREF_CURREN_ROOM_NAME, qbUser.getTags().get(0));
        sharedPrefsHelper.saveQbUser(qbUser);
    }
}

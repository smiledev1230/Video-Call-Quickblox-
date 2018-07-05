package qb.fragments;

import android.app.Activity;
import android.content.Context;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.os.SystemClock;
import android.os.Vibrator;
import android.support.v4.app.Fragment;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;

import com.quickblox.chat.QBChatService;
import com.quickblox.users.model.QBUser;
import com.quickblox.videochat.webrtc.QBRTCSession;
import com.quickblox.videochat.webrtc.QBRTCTypes;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

import qb.db.QbUsersDbManager;
import qb.utils.CollectionsUtils;
import qb.utils.RingtonePlayer;
import qb.utils.UiUtils;
import qb.utils.UsersUtils;
import qb.utils.WebRtcSessionManager;

/**
 * QuickBlox team
 */
public class IncomeCallFragment extends Fragment implements Serializable, View.OnClickListener {

    private static final String TAG = IncomeCallFragment.class.getSimpleName();
    private static final long CLICK_DELAY = TimeUnit.SECONDS.toMillis(2);
    private TextView callTypeTextView;
    private ImageButton rejectButton;
    private ImageButton takeButton;

    private List<Integer> opponentsIds;
    private Vibrator vibrator;
    private QBRTCTypes.QBConferenceType conferenceType;
    private long lastClickTime = 0l;
    private RingtonePlayer ringtonePlayer;
    private IncomeCallFragmentCallbackListener incomeCallFragmentCallbackListener;
    private QBRTCSession currentSession;
    private QbUsersDbManager qbUserDbManager;
    private TextView alsoOnCallText;

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);

        try {
            incomeCallFragmentCallbackListener = (IncomeCallFragmentCallbackListener) activity;
        } catch (ClassCastException e) {
            throw new ClassCastException(activity.toString()
                    + " must implement OnCallEventsController");
        }
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        setRetainInstance(true);

        Log.d(TAG, "onCreate() from IncomeCallFragment");
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        int layout = getResources().getIdentifier("fragment_income_call", "layout", getActivity().getPackageName());
        View view = inflater.inflate(layout, container, false);

        initFields();
        hideToolBar();

        if (currentSession != null) {
            initUI(view);
            setDisplayedTypeCall(conferenceType);
            initButtonsListener();
        }

        ringtonePlayer = new RingtonePlayer(getActivity());
        return view;
    }

    private void initFields() {
        currentSession = WebRtcSessionManager.getInstance(getActivity()).getCurrentSession();
        qbUserDbManager = QbUsersDbManager.getInstance(getActivity().getApplicationContext());

        if (currentSession != null) {
            opponentsIds = currentSession.getOpponents();
            conferenceType = currentSession.getConferenceType();
            Log.d(TAG, conferenceType.toString() + "From onCreateView()");
        }
    }

    public void hideToolBar() {
        Toolbar toolbar = (Toolbar) getActivity().findViewById(getIdIdentifier("toolbar_call"));
        toolbar.setVisibility(View.GONE);
    }

    @Override
    public void onStart() {
        super.onStart();
        startCallNotification();
    }

    private void initButtonsListener() {
        rejectButton.setOnClickListener(this);
        takeButton.setOnClickListener(this);
    }

    private void initUI(View view) {
        callTypeTextView = (TextView) view.findViewById(getIdIdentifier("call_type"));

        ImageView callerAvatarImageView = (ImageView) view.findViewById(getIdIdentifier("image_caller_avatar"));
        callerAvatarImageView.setBackgroundDrawable(getBackgroundForCallerAvatar(currentSession.getCallerID()));

        TextView callerNameTextView = (TextView) view.findViewById(getIdIdentifier("text_caller_name"));

        QBUser callerUser = qbUserDbManager.getUserById(currentSession.getCallerID());
        callerNameTextView.setText(UsersUtils.getUserNameOrId(callerUser, currentSession.getCallerID()));

        TextView otherIncUsersTextView = (TextView) view.findViewById(getIdIdentifier("text_other_inc_users"));
        otherIncUsersTextView.setText(getOtherIncUsersNames());

        alsoOnCallText = (TextView) view.findViewById(getIdIdentifier("text_also_on_call"));
        setVisibilityAlsoOnCallTextView();

        rejectButton = (ImageButton) view.findViewById(getIdIdentifier("image_button_reject_call"));
        takeButton = (ImageButton) view.findViewById(getIdIdentifier("image_button_accept_call"));
    }

    private void setVisibilityAlsoOnCallTextView() {
        if (opponentsIds.size() < 2) {
            alsoOnCallText.setVisibility(View.INVISIBLE);
        }
    }

    private Drawable getBackgroundForCallerAvatar(int callerId) {
        return UiUtils.getColorCircleDrawable(callerId);
    }

    public void startCallNotification() {
        Log.d(TAG, "startCallNotification()");

        ringtonePlayer.play(false);

        vibrator = (Vibrator) getActivity().getSystemService(Context.VIBRATOR_SERVICE);

        long[] vibrationCycle = {0, 1000, 1000};
        if (vibrator.hasVibrator()) {
//            vibrator.vibrate(vibrationCycle, 1);
        }

    }

    private void stopCallNotification() {
        Log.d(TAG, "stopCallNotification()");

        if (ringtonePlayer != null) {
            ringtonePlayer.stop();
        }

        if (vibrator != null) {
//            vibrator.cancel();
        }
    }

    private String getOtherIncUsersNames() {
        ArrayList<QBUser> usersFromDb = qbUserDbManager.getUsersByIds(opponentsIds);
        ArrayList<QBUser> opponents = new ArrayList<>();
        opponents.addAll(UsersUtils.getListAllUsersFromIds(usersFromDb, opponentsIds));

        opponents.remove(QBChatService.getInstance().getUser());
        Log.d(TAG, "opponentsIds = " + opponentsIds);
        return CollectionsUtils.makeStringFromUsersFullNames(opponents);
    }

    private void setDisplayedTypeCall(QBRTCTypes.QBConferenceType conferenceType) {
        boolean isVideoCall = conferenceType == QBRTCTypes.QBConferenceType.QB_CONFERENCE_TYPE_VIDEO;

        int ic_video_white = getResources().getIdentifier("ic_video_white", "drawable", getActivity().getPackageName());
        int ic_call = getResources().getIdentifier("ic_call", "drawable", getActivity().getPackageName());

        int text_incoming_audio_call = getResources().getIdentifier("text_incoming_audio_call", "string", getActivity().getPackageName());
        int text_incoming_video_call = getResources().getIdentifier("text_incoming_video_call", "string", getActivity().getPackageName());

        callTypeTextView.setText(isVideoCall ? text_incoming_video_call : text_incoming_audio_call);
        takeButton.setImageResource(isVideoCall ? ic_video_white : ic_call);
    }

    @Override
    public void onStop() {
        stopCallNotification();
        super.onStop();
        Log.d(TAG, "onStop() from IncomeCallFragment");
    }

    @Override
    public void onClick(View v) {

        if ((SystemClock.uptimeMillis() - lastClickTime) < CLICK_DELAY) {
            return;
        }
        lastClickTime = SystemClock.uptimeMillis();

        int image_button_accept_call = getIdIdentifier("image_button_accept_call");
        int image_button_reject_call = getIdIdentifier("image_button_reject_call");

        if (v.getId() == image_button_reject_call){
            accept();
        }else if (v.getId() == image_button_accept_call){
            reject();
        }

    }

    private void accept() {
        enableButtons(false);
        stopCallNotification();

        incomeCallFragmentCallbackListener.onAcceptCurrentSession();
        Log.d(TAG, "Call is started");
    }

    private void reject() {
        enableButtons(false);
        stopCallNotification();

        incomeCallFragmentCallbackListener.onRejectCurrentSession();
        Log.d(TAG, "Call is rejected");
    }

    private void enableButtons(boolean enable) {
        takeButton.setEnabled(enable);
        rejectButton.setEnabled(enable);
    }


    public int getIdIdentifier(String res){
        return getResources().getIdentifier(res, "id", getActivity().getPackageName());
    }

}

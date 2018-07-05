package qb.utils;

import android.util.SparseArray;

import com.quickblox.videochat.webrtc.QBRTCTypes;

import qb.QBBase;

public class QBRTCSessionUtils {

    private static final SparseArray<Integer> peerStateDescriptions = new SparseArray<>();

    static {
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_PENDING.ordinal(), getStringIdentifier("opponent_pending"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_CONNECTING.ordinal(), getStringIdentifier("text_status_connect"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_CHECKING.ordinal(), getStringIdentifier("text_status_checking"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_CONNECTED.ordinal(), getStringIdentifier("text_status_connected"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_DISCONNECTED.ordinal(), getStringIdentifier("text_status_disconnected"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_CLOSED.ordinal(), getStringIdentifier("opponent_closed"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_DISCONNECT_TIMEOUT.ordinal(), getStringIdentifier("text_status_disconnected"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_NOT_ANSWER.ordinal(), getStringIdentifier("text_status_no_answer"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_NOT_OFFER.ordinal(), getStringIdentifier("text_status_no_answer"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_REJECT.ordinal(), getStringIdentifier("text_status_rejected"));
        peerStateDescriptions.put(
                QBRTCTypes.QBRTCConnectionState.QB_RTC_CONNECTION_HANG_UP.ordinal(), getStringIdentifier("text_status_hang_up"));
    }

    public static Integer getStatusDescriptionResource(QBRTCTypes.QBRTCConnectionState connectionState) {
        return peerStateDescriptions.get(connectionState.ordinal());
    }

    public static int getStringIdentifier(String res){
        return QBBase.getInstance().getResources().getIdentifier(res, "string", QBBase.getInstance().getPackageName());
    }

}
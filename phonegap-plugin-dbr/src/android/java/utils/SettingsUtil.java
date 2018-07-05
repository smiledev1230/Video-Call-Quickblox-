package qb.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.util.Log;

import com.quickblox.videochat.webrtc.QBRTCConfig;
import com.quickblox.videochat.webrtc.QBRTCMediaConfig;

import java.util.List;

/**
 * QuickBlox team
 */
public class SettingsUtil {

    private static final String TAG = SettingsUtil.class.getSimpleName();
    private static String pref_answer_time_interval_key = "answer_time_interval";
    private static String pref_audiocodec_key = "pref_audio_codec";
    private static String pref_audiocodec_def = "ISAC";
    private static String pref_disable_built_in_aec_key = "disable_built_in_aec_preference";
    private static String pref_disable_built_in_aec_default = "false";
    private static String pref_noaudioprocessing_key = "audioprocessing_preference";
    private static String pref_noaudioprocessing_default = "false";
    private static String pref_opensles_key = "opensles_preference";
    private static String pref_opensles_default = "false";
    private static String pref_hwcodec_key = "hwcodec_preference";
    private static String pref_hwcodec_default = "true";
    private static String pref_resolution_key = "resolution_preference";
    private static String pref_startbitratevalue_key = "startbitratevalue_preference";
    private static String pref_videocodec_key = "videocodec_preference";
    private static String pref_frame_rate_key = "frame_rate";
    private static int pref_startbitratevalue_default = 0;
    private static int pref_frame_rate_default = 0;
    private static int pref_answer_time_interval_default_value = 60;
    private static String pref_disconnect_time_interval_key = "disconnect_time_interval";
    private static int pref_disconnect_time_interval_default_value = 10;
    private static String pref_dialing_time_interval_key = "Dialing_time_interval";
    private static int pref_dialing_time_interval_default_value = 5;
    private static String pref_manage_speakerphone_by_proximity_key = "manage_speakerphone_by_proximity_preference";
    private static boolean pref_manage_speakerphone_by_proximity_default = false;

    private static void setSettingsForMultiCall(List<Integer> users) {
        if (users.size() <= 4) {
            setDefaultVideoQuality();
        } else {
            //set to minimum settings
            QBRTCMediaConfig.setVideoWidth(QBRTCMediaConfig.VideoQuality.QBGA_VIDEO.width);
            QBRTCMediaConfig.setVideoHeight(QBRTCMediaConfig.VideoQuality.QBGA_VIDEO.height);
            QBRTCMediaConfig.setVideoHWAcceleration(false);
            QBRTCMediaConfig.setVideoCodec(null);
        }
    }

    public static void setSettingsStrategy(List<Integer> users, SharedPreferences sharedPref, Context context) {
        setCommonSettings(sharedPref, context);
        if (users.size() == 1) {
            setSettingsFromPreferences(sharedPref, context);
        } else {
            setSettingsForMultiCall(users);
        }
    }

    private static void setCommonSettings(SharedPreferences sharedPref, Context context) {
        String audioCodecDescription = getPreferenceString(sharedPref, context, pref_audiocodec_key,
                pref_audiocodec_def);
        QBRTCMediaConfig.AudioCodec audioCodec = QBRTCMediaConfig.AudioCodec.ISAC.getDescription()
                .equals(audioCodecDescription) ?
                QBRTCMediaConfig.AudioCodec.ISAC : QBRTCMediaConfig.AudioCodec.OPUS;
        Log.e(TAG, "audioCodec =: " + audioCodec.getDescription());
        QBRTCMediaConfig.setAudioCodec(audioCodec);
        Log.v(TAG, "audioCodec = " + QBRTCMediaConfig.getAudioCodec());
        // Check Disable built-in AEC flag.
        boolean disableBuiltInAEC = getPreferenceBoolean(sharedPref, context,
                pref_disable_built_in_aec_key,
                pref_disable_built_in_aec_default);

        QBRTCMediaConfig.setUseBuildInAEC(!disableBuiltInAEC);
        Log.v(TAG, "setUseBuildInAEC = " + QBRTCMediaConfig.isUseBuildInAEC());
        // Check Disable Audio Processing flag.
        boolean noAudioProcessing = getPreferenceBoolean(sharedPref, context,
                pref_noaudioprocessing_key,
                pref_noaudioprocessing_default);
        QBRTCMediaConfig.setAudioProcessingEnabled(!noAudioProcessing);
        Log.v(TAG, "isAudioProcessingEnabled = " + QBRTCMediaConfig.isAudioProcessingEnabled());
        // Check OpenSL ES enabled flag.
        boolean useOpenSLES = getPreferenceBoolean(sharedPref, context,
                pref_opensles_key,
                pref_opensles_default);
        QBRTCMediaConfig.setUseOpenSLES(useOpenSLES);
        Log.v(TAG, "isUseOpenSLES = " + QBRTCMediaConfig.isUseOpenSLES());
    }

    private static void setSettingsFromPreferences(SharedPreferences sharedPref, Context context) {

        // Check HW codec flag.
        boolean hwCodec = sharedPref.getBoolean(pref_hwcodec_key,
                Boolean.valueOf(pref_hwcodec_default));

        QBRTCMediaConfig.setVideoHWAcceleration(hwCodec);

        // Get video resolution from settings.
        int resolutionItem = Integer.parseInt(sharedPref.getString(pref_resolution_key,
                "0"));
        Log.e(TAG, "resolutionItem =: " + resolutionItem);
        setVideoQuality(resolutionItem);
        Log.v(TAG, "resolution = " + QBRTCMediaConfig.getVideoHeight() + "x" + QBRTCMediaConfig.getVideoWidth());

        // Get start bitrate.
        int startBitrate = getPreferenceInt(sharedPref, context,
                pref_startbitratevalue_key,
                pref_startbitratevalue_default);
        Log.e(TAG, "videoStartBitrate =: " + startBitrate);
        QBRTCMediaConfig.setVideoStartBitrate(startBitrate);
        Log.v(TAG, "videoStartBitrate = " + QBRTCMediaConfig.getVideoStartBitrate());

        int videoCodecItem = Integer.parseInt(getPreferenceString(sharedPref, context, pref_videocodec_key, "0"));
        for (QBRTCMediaConfig.VideoCodec codec : QBRTCMediaConfig.VideoCodec.values()) {
            if (codec.ordinal() == videoCodecItem) {
                Log.e(TAG, "videoCodecItem =: " + codec.getDescription());
                QBRTCMediaConfig.setVideoCodec(codec);
                Log.v(TAG, "videoCodecItem = " + QBRTCMediaConfig.getVideoCodec());
                break;
            }
        }
        // Get camera fps from settings.
        int cameraFps = getPreferenceInt(sharedPref, context, pref_frame_rate_key, pref_frame_rate_default);
        Log.e(TAG, "cameraFps = " + cameraFps);
        QBRTCMediaConfig.setVideoFps(cameraFps);
        Log.v(TAG, "cameraFps = " + QBRTCMediaConfig.getVideoFps());
    }

    public static void configRTCTimers(Context context) {
        SharedPreferences sharedPref = PreferenceManager.getDefaultSharedPreferences(context);

        long answerTimeInterval = getPreferenceInt(sharedPref, context,
                pref_answer_time_interval_key,
                pref_answer_time_interval_default_value);
        QBRTCConfig.setAnswerTimeInterval(answerTimeInterval);
        Log.e(TAG, "answerTimeInterval = " + answerTimeInterval);

        int disconnectTimeInterval = getPreferenceInt(sharedPref, context,
                pref_disconnect_time_interval_key,
                pref_disconnect_time_interval_default_value);
        QBRTCConfig.setDisconnectTime(disconnectTimeInterval);
        Log.e(TAG, "disconnectTimeInterval = " + disconnectTimeInterval);

        long dialingTimeInterval = getPreferenceInt(sharedPref, context,
                pref_dialing_time_interval_key,
                pref_dialing_time_interval_default_value);
        QBRTCConfig.setDialingTimeInterval(dialingTimeInterval);
        Log.e(TAG, "dialingTimeInterval = " + dialingTimeInterval);
    }

    public static boolean isManageSpeakerPhoneByProximity(Context context){
        SharedPreferences sharedPref = PreferenceManager.getDefaultSharedPreferences(context);
        boolean manageSpeakerPhoneByProximity = sharedPref.getBoolean(
                pref_manage_speakerphone_by_proximity_key,
                pref_manage_speakerphone_by_proximity_default);

        return manageSpeakerPhoneByProximity;
    }

    private static void setVideoQuality(int resolutionItem) {
        if (resolutionItem != -1) {
            setVideoFromLibraryPreferences(resolutionItem);
        } else {
            setDefaultVideoQuality();
        }
    }

    private static void setDefaultVideoQuality() {
        QBRTCMediaConfig.setVideoWidth(QBRTCMediaConfig.VideoQuality.VGA_VIDEO.width);
        QBRTCMediaConfig.setVideoHeight(QBRTCMediaConfig.VideoQuality.VGA_VIDEO.height);
    }

    private static void setVideoFromLibraryPreferences(int resolutionItem) {
        for (QBRTCMediaConfig.VideoQuality quality : QBRTCMediaConfig.VideoQuality.values()) {
            if (quality.ordinal() == resolutionItem) {
                Log.e(TAG, "resolution =: " + quality.height + ":" + quality.width);
                QBRTCMediaConfig.setVideoHeight(quality.height);
                QBRTCMediaConfig.setVideoWidth(quality.width);
            }
        }
    }

    private static String getPreferenceString(SharedPreferences sharedPref, Context context, int strResKey, int strResDefValue) {
        return sharedPref.getString(context.getString(strResKey), context.getString(strResDefValue));
    }

    private static String getPreferenceString(SharedPreferences sharedPref, Context context, String strResKey, String strResDefValue) {
        return sharedPref.getString(strResKey, strResDefValue);
    }

    private static String getPreferenceString(SharedPreferences sharedPref, Context context, int strResKey, String strResDefValue) {
        return sharedPref.getString(context.getString(strResKey), strResDefValue);
    }

    public static int getPreferenceInt(SharedPreferences sharedPref, Context context, int strResKey, int strResDefValue) {
        return sharedPref.getInt(context.getString(strResKey), Integer.valueOf(context.getString(strResDefValue)));
    }

    public static int getPreferenceInt(SharedPreferences sharedPref, Context context, String strResKey, int strResDefValue) {
        return sharedPref.getInt(strResKey, strResDefValue);
    }

    private static boolean getPreferenceBoolean(SharedPreferences sharedPref, Context context, int StrRes, int strResDefValue) {
        return sharedPref.getBoolean(context.getString(StrRes), Boolean.valueOf(context.getString(strResDefValue)));
    }

    private static boolean getPreferenceBoolean(SharedPreferences sharedPref, Context context, String StrRes, String strResDefValue) {
        return sharedPref.getBoolean(StrRes, Boolean.valueOf(strResDefValue));
    }
}

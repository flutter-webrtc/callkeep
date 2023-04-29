package io.wazo.callkeep;
import android.telecom.InCallService;

// @see https://github.com/kbagchiGWC/voice-quickstart-android/blob/9a2aff7fbe0d0a5ae9457b48e9ad408740dfb968/exampleConnectionService/src/main/java/com/twilio/voice/examples/connectionservice/VoiceConnectionService.java
@TargetApi(Build.VERSION_CODES.M)
public class MyInCallService extends InCallService {
    public MyInCallService() {
    }

    public static void setAudioRoute(int route) {
        if (getCallAudioState() != null) {
            getCallAudioState().setRoute(route);
        }
    }
}
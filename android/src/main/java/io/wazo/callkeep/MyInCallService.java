package io.wazo.callkeep;

import android.telecom.InCallService;
import android.telecom.CallAudioState;

public class MyInCallService extends InCallService {
    public void setRoute(int route) {
        CallAudioState currentAudioState = getCallAudioState();
        CallAudioState newAudioState = new CallAudioState(currentAudioState.isMuted(), route,
                    currentAudioState.getSupportedRouteMask());

        onCallAudioStateChanged(newAudioState);
    }
}
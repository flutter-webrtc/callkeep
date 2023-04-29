package io.wazo.callkeep;

import android.telecom.InCallService;

public class MyInCallService extends InCallService {
    public void setRoute(int route) {
        CallAudioState currentAudioState = getCallAudioState();
        CallAudioState newAudioState = new CallAudioState(currentAudioState.isMuted(), route,
                    conn.getCallAudioState().getSupportedRouteMask());

        onCallAudioStateChanged(newAudioState);
    }
}
package io.wazo.callkeep;

import android.telecom.InCallService;
import android.telecom.CallAudioState;
import android.telecom.Call;

import android.util.Log;

public class MyInCallService extends InCallService {
    public void setRoute(int route) {
        CallAudioState currentAudioState = getCallAudioState();
        CallAudioState newAudioState = new CallAudioState(currentAudioState.isMuted(), route,
                    currentAudioState.getSupportedRouteMask());

        onCallAudioStateChanged(newAudioState);
    }

    @Override
    public void onCallAdded(Call call) {
        super.onCallAdded(call);
        
        Log.d("TESTING", "placedCall: placing ");
    }
}
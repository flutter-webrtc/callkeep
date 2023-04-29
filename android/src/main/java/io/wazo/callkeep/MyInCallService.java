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
        
        // Get the Call object for the placed call
        Call placedCall = getCallById(call.getDetails().getCallId());
        
        Log.d("TESTING", "placedCall: placing ");
        // Use the Call object as needed
        if (placedCall != null) {
            // Do something with the placedCall
            Log.d("TESTING", "placedCall: ");

        }
    }
}
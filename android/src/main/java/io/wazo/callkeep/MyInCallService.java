package io.wazo.callkeep;

import android.telecom.InCallService;

public class MyInCallService extends InCallService {
    private void setAudioRoute(int route) {
        if (getCallAudioState() != null) {
            getCallAudioState().setRoute(route);
        }
    }
}
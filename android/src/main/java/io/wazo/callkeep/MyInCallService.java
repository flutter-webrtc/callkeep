package io.wazo.callkeep;

import android.telecom.InCallService;

public class MyInCallService extends InCallService {
    @Override
    public void setAudioRoute(int route){
        super.setAudioRoute(route);
    }
}
/*
 * Copyright (c) 2016-2019 The CallKeep Authors (see the AUTHORS file)
 * SPDX-License-Identifier: ISC, MIT
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

package io.wazo.callkeep;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.telecom.CallAudioState;
import android.telecom.Connection;
import android.telecom.DisconnectCause;
import android.telecom.TelecomManager;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import java.util.HashMap;
import java.util.Map;

import static io.wazo.callkeep.CallKeepConstants.*;

public class VoiceConnection extends Connection {
    private static final String TAG = "RNCK:VoiceConnection";
    private final HashMap<String, String> connectionData;
    private final Context context;

    VoiceConnection(@NonNull Context context, @NonNull HashMap<String, String> connectionData) {
        super();
        this.connectionData = connectionData;
        this.context = context;

        String number = connectionData.get(EXTRA_CALL_NUMBER);
        String name = connectionData.get(EXTRA_CALLER_NAME);
        updateDisplay(name, number);
    }

    public void updateDisplay(String callerName, String handle) {
        if (handle != null) {
            setAddress(Uri.parse(handle), TelecomManager.PRESENTATION_ALLOWED);
        }
        if (callerName != null) {
            setCallerDisplayName(callerName, TelecomManager.PRESENTATION_ALLOWED);
        }
    }

    @Override
    public void onExtrasChanged(Bundle extras) {
        super.onExtrasChanged(extras);
        Map<String, String> attributeMap = (Map<String, String>) extras.getSerializable(EXTRA_CALL_ATTRIB);
        if (attributeMap != null) {
            connectionData.putAll(attributeMap);
        }
    }

    @Override
    public void onCallAudioStateChanged(CallAudioState state) {
        CallAudioState currentState = getCallAudioState();
        super.onCallAudioStateChanged(state);
        if (state.isMuted() == currentState.isMuted()) {
            return;
        }

        sendCallRequestToActivity(state.isMuted() ? ACTION_MUTE_CALL : ACTION_UNMUTE_CALL, connectionData);
    }

    @Override
    public void onAnswer() {
        super.onAnswer();
        Log.d(TAG, "onAnswer called");
        Log.d(TAG, "onAnswer ignored");
    }
    
    @Override
    public void onAnswer(int videoState) {
        super.onAnswer(videoState);
        Log.d(TAG, "onAnswer videoState called: " + videoState);
        startCall();
        Log.d(TAG, "onAnswer videoState executed");
    }

    public void startCall() {
        setConnectionCapabilities(getConnectionCapabilities() | Connection.CAPABILITY_HOLD);
        setAudioModeIsVoip(true);
        sendCallRequestToActivity(ACTION_ANSWER_CALL, connectionData);
        sendCallRequestToActivity(ACTION_AUDIO_SESSION, connectionData);
    }

    @Override
    public void onPlayDtmfTone(char dtmf) {
        try {
            HashMap<String, String> data = new HashMap<>(connectionData);
            data.put("DTMF", Character.toString(dtmf));
            sendCallRequestToActivity(ACTION_DTMF_TONE, data);
        } catch (Throwable exception) {
            Log.e(TAG, "Handle map error", exception);
        }
    }

    @Override
    public void onDisconnect() {
        super.onDisconnect();
        close(DisconnectCause.LOCAL);
        sendCallRequestToActivity(ACTION_END_CALL, connectionData);
        Log.d(TAG, "onDisconnect executed");
    }

    public void reportDisconnect(int reason) {
        super.onDisconnect();
        int causeCode;
        switch (reason) {
            case 1:
                causeCode = DisconnectCause.ERROR;
                break;
            case 2:
            case 5:
                causeCode = DisconnectCause.REMOTE;
                break;
            case 3:
                causeCode = DisconnectCause.BUSY;
                break;
            case 4:
                causeCode = DisconnectCause.ANSWERED_ELSEWHERE;
                break;
            case 6:
                causeCode = DisconnectCause.MISSED;
                break;
            default:
                causeCode = DisconnectCause.OTHER;
                break;
        }
        close(causeCode);
    }

    @Override
    public void onAbort() {
        super.onAbort();
        close(DisconnectCause.REJECTED);
        sendCallRequestToActivity(ACTION_END_CALL, connectionData);
        Log.d(TAG, "onAbort executed");
    }

    @Override
    public void onHold() {
        super.onHold();
        this.setOnHold();
        sendCallRequestToActivity(ACTION_HOLD_CALL, connectionData);
    }

    @Override
    public void onUnhold() {
        super.onUnhold();
        sendCallRequestToActivity(ACTION_UNHOLD_CALL, connectionData);
        setActive();
    }

    @Override
    public void onReject() {
        super.onReject();
        close(DisconnectCause.REJECTED);
        sendCallRequestToActivity(ACTION_REJECT_CALL, connectionData);
        Log.d(TAG, "onReject executed");
    }

    private void close(int causeCode) {
        setDisconnected(new DisconnectCause(causeCode));
        VoiceConnectionService.deinitConnection(connectionData.get(EXTRA_CALL_UUID));
        destroy();
    }

    /*
     * Send call request to the RNCallKeepModule
     */
    private void sendCallRequestToActivity(String action, @Nullable HashMap<String, String> attributeMap) {
        final Handler handler = new Handler();
        handler.post(() -> {
            Intent intent = new Intent(action);
            if (attributeMap != null) {
                Bundle extras = new Bundle();
                extras.putSerializable(EXTRA_CALL_ATTRIB, attributeMap);
                intent.putExtras(extras);
            }
            LocalBroadcastManager.getInstance(context).sendBroadcast(intent);
        });
    }


}

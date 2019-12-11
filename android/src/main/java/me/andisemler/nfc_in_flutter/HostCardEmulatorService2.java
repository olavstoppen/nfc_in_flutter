package me.andisemler.nfc_in_flutter;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Intent;
import android.nfc.cardemulation.HostApduService;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

public class HostCardEmulatorService2 extends HostApduService {

    static final String TAG = "Host Card Emulator";
    static final String STATUS_SUCCESS = "9000";
    static final String STATUS_FAILED = "6F00";
    static final String CLA_NOT_SUPPORTED = "6E00";
    static final String INS_NOT_SUPPORTED = "6D00";
    static final String AID = "A0000002471001";
    static final String SELECT_INS = "A4";
    static final String DEFAULT_CLA = "00";
    static final int MIN_APDU_LENGTH = 12;
    static final int NOTIFY_ID = 1337;
    static final int FOREGROUND_ID = 1338;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startForeground(FOREGROUND_ID,
                buildForegroundNotification());
        return super.onStartCommand(intent, flags, startId);
    }

    @Override
    public byte[] processCommandApdu(byte[] commandApdu, Bundle extras) {

        return commandApdu;
    }

    @Override
    public void onDeactivated(int reason) {
        Log.d(TAG, "Deactivated: " + reason);
    }
    private Notification buildForegroundNotification()
    {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Create the NotificationChannel
            String name = "Easee 1";
            String descriptionText = "Easee 2";
            int importance = NotificationManager.IMPORTANCE_DEFAULT;
            NotificationChannel mChannel = new NotificationChannel(getString(R.string.card_title), name, importance);
            mChannel.setDescription(descriptionText);

            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            notificationManager.createNotificationChannel(mChannel);
        }
        NotificationCompat.Builder b = new NotificationCompat.Builder(this,getString(R.string.card_title));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            b.setCategory(Notification.CATEGORY_SERVICE);
        }
        b.setOngoing(true)
                .setContentTitle("Easee")
                .setContentText("Running");
        return b.build();
    }
}

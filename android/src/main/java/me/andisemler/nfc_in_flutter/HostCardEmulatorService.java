package me.andisemler.nfc_in_flutter;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.nfc.NdefRecord;
import android.nfc.cardemulation.HostApduService;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

public class HostCardEmulatorService extends HostApduService {

    static final int FOREGROUND_ID = 1338;

    static String TAG = "Host Card Emulator";
    static String STATUS_SUCCESS = "9000";
    static String STATUS_FAILED = "6F00";
    static String CLA_NOT_SUPPORTED = "6D00";
    static String INS_NOT_SUPPORTED = "6D00";
    static String AID = "A0000002471001";
    static String SELECT_INS = "A4";
    static String DEFAULT_CLA ="00" ;
    static int MIN_APDU_LENGTH = 12;



    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return Service.START_STICKY_COMPATIBILITY;
    }

    @Override
    public byte[] processCommandApdu(byte[] commandApdu, Bundle extras) {

        if (commandApdu == null) {
            return Utils.hexToBytes(STATUS_FAILED);
        }

        String hexCommandApdu = Utils.bytesToHex(commandApdu);
        if (hexCommandApdu.length() < MIN_APDU_LENGTH) {
            return Utils.hexToBytes(STATUS_FAILED);
        }

        if (!hexCommandApdu.substring(0, 2).equals(DEFAULT_CLA)) {
            return Utils.hexToBytes(CLA_NOT_SUPPORTED);
        }

        if (!hexCommandApdu.substring(2, 4).equals(SELECT_INS)) {
            return Utils.hexToBytes(INS_NOT_SUPPORTED);
        }

        if (hexCommandApdu.substring(10, 24).equals(AID))  {
            return Utils.hexToBytes(STATUS_SUCCESS);
        } else {
            return Utils.hexToBytes(STATUS_FAILED);
        }
    }

    @Override
    public void onDeactivated(int reason) {
        Log.i(TAG, "onDeactivated() Fired! Reason: " + reason);
    }
    private Notification buildForegroundNotification()
    {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Create the NotificationChannel
            String name = "Easee notification channel";
            String descriptionText = "Display Easee-key notification";
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
                .setContentText("Easee-Key is active");
        return b.build();
    }
}

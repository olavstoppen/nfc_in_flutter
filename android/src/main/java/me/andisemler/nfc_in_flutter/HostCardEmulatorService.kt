package me.andisemler.nfc_in_flutter

import android.R
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.nfc.cardemulation.HostApduService
import android.os.Build
import android.os.Bundle
import android.support.v4.app.NotificationCompat
import android.util.Log


open class HostCardEmulatorService: HostApduService()
{
	companion object {
		val TAG = "Host Card Emulator"
		val STATUS_SUCCESS = "9000"
		val STATUS_FAILED = "6F00"
		val CLA_NOT_SUPPORTED = "6E00"
		val INS_NOT_SUPPORTED = "6D00"
		val AID = "A0000002471001"
		val SELECT_INS = "A4"
		val DEFAULT_CLA = "00"
		val MIN_APDU_LENGTH = 12
		val NOTIFY_ID = 1337
		val FOREGROUND_ID = 1338
	}


	override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int
	{
		startForeground(FOREGROUND_ID,
				buildForegroundNotification())
		return super.onStartCommand(intent, flags, startId)
	}

	override fun onDeactivated(reason: Int) {
		Log.d(TAG, "Deactivated: $reason")
	}

	override fun processCommandApdu(commandApdu: ByteArray?,extras: Bundle?): ByteArray {

		if (commandApdu == null) {
			return Utils.hexStringToByteArray(STATUS_FAILED)
		}

		val hexCommandApdu = Utils.toHex(commandApdu)
		if (hexCommandApdu.length < MIN_APDU_LENGTH) {
			return Utils.hexStringToByteArray(STATUS_FAILED)
		}

		if (hexCommandApdu.substring(0, 2) != DEFAULT_CLA) {
			return Utils.hexStringToByteArray(CLA_NOT_SUPPORTED)
		}

		if (hexCommandApdu.substring(2, 4) != SELECT_INS) {
			return Utils.hexStringToByteArray(INS_NOT_SUPPORTED)
		}

		if (hexCommandApdu.substring(10, 24) == AID)  {
			return Utils.hexStringToByteArray(STATUS_SUCCESS)
		} else {
			return Utils.hexStringToByteArray(STATUS_FAILED)
		}
	}

	private fun buildForegroundNotification(): Notification?
	{
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			// Create the NotificationChannel
			val name = "Easee 1"
			val descriptionText = "Easee 2"
			val importance = NotificationManager.IMPORTANCE_DEFAULT
			val mChannel = NotificationChannel("Easee ID", name, importance)
			mChannel.description = descriptionText
			// Register the channel with the system; you can't change the importance
			// or other notification behaviors after this
			val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
			notificationManager.createNotificationChannel(mChannel)
		}
		val b = NotificationCompat.Builder(this)
		b.setOngoing(true)
				.setContentTitle("Easee")
				.setContentText("Running")
				.setSmallIcon(R.drawable.stat_sys_download)
		return b.build()
	}
}
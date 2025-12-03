package com.mihomo.mihomo_valdi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.atomic.AtomicBoolean

class MihomoVpnService : VpnService() {
    companion object {
        const val ACTION_START = "com.mihomo.mihomo_valdi.START"
        const val ACTION_STOP = "com.mihomo.mihomo_valdi.STOP"
        private const val CHANNEL_ID = "mihomo_vpn_channel"
        private const val NOTIFICATION_ID = 1
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private val isRunning = AtomicBoolean(false)

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val host = intent.getStringExtra("host") ?: "127.0.0.1"
                val port = intent.getIntExtra("port", 7890)
                startVpn(host, port)
            }
            ACTION_STOP -> stopVpn()
        }
        return START_STICKY
    }

    private fun startVpn(host: String, port: Int) {
        if (isRunning.get()) return

        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())

        val builder = Builder()
            .setSession("Mihomo VPN")
            .addAddress("10.0.0.2", 24)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("8.8.8.8")
            .setMtu(1500)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }

        vpnInterface = builder.establish()
        isRunning.set(true)

        Thread {
            runTunnel(host, port)
        }.start()
    }

    private fun runTunnel(host: String, port: Int) {
        val vpnFd = vpnInterface?.fileDescriptor ?: return
        val input = FileInputStream(vpnFd)
        val output = FileOutputStream(vpnFd)
        val buffer = ByteArray(32767)

        try {
            while (isRunning.get()) {
                val length = input.read(buffer)
                if (length > 0) {
                    // 简化实现：将数据转发到 SOCKS5 代理
                    // 实际生产环境需要完整的 TUN2SOCKS 实现
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            input.close()
            output.close()
        }
    }

    private fun stopVpn() {
        isRunning.set(false)
        vpnInterface?.close()
        vpnInterface = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mihomo VPN",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Mihomo VPN")
                .setContentText("VPN is running")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Mihomo VPN")
                .setContentText("VPN is running")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .build()
        }
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}

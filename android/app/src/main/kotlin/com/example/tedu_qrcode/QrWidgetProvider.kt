package com.example.tedu_qrcode

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Color
import android.widget.RemoteViews
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import es.antonborri.home_widget.HomeWidgetPlugin

class QrWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = HomeWidgetPlugin.getData(context)
        val qrData = prefs.getString("qr_data", null)

        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        if (qrData != null) {
            val bitmap = generateQrCode(qrData)
            views.setImageViewBitmap(R.id.widget_qr_image, bitmap)
        } else {
            // Null or empty implies we clear it
            views.setImageViewBitmap(R.id.widget_qr_image, null)
        }

       appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun generateQrCode(text: String): Bitmap? {
        return try {
            val size = 512 
            val bitMatrix = QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, size, size)
            val width = bitMatrix.width
            val height = bitMatrix.height
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
            for (x in 0 until width) {
                for (y in 0 until height) {
                    bitmap.setPixel(x, y, if (bitMatrix.get(x, y)) Color.BLACK else Color.WHITE)
                }
            }
            bitmap
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

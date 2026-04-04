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
            val bitmap = generateErrorBitmap("404")
            views.setImageViewBitmap(R.id.widget_qr_image, bitmap)
        }

       appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun generateErrorBitmap(text: String): Bitmap {
        val size = 512
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bitmap)
        canvas.drawColor(Color.WHITE)
        val paint = android.graphics.Paint().apply {
            color = Color.BLACK
            textSize = 120f
            textAlign = android.graphics.Paint.Align.CENTER
            isAntiAlias = true
        }
        val paintSub = android.graphics.Paint().apply {
            color = Color.GRAY
            textSize = 40f
            textAlign = android.graphics.Paint.Align.CENTER
            isAntiAlias = true
        }
        
        val xPos = (canvas.width / 2).toFloat()
        val yPos = (canvas.height / 2 - (paint.descent() + paint.ascent()) / 2)
        
        canvas.drawText(text, xPos, yPos - 30f, paint)
        canvas.drawText("No key found", xPos, yPos + 60f, paintSub)
        return bitmap
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

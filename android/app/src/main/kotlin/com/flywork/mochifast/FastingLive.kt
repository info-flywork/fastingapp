package com.flywork.mochifast

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.SystemClock
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import kotlin.math.max
import kotlin.math.min

/**
 * Canlı geri sayımlı oruç widget'ları (küçük, kart, özet).
 *
 * Flutter (`FastingWidgetSync`) sayaç sürerken görseli süre metni ve ilerleme
 * yayı olmadan çizer, konumları `fasting_live_spec`'e yazar. Burada yay
 * görselin üstüne çizilir, süre `Chronometer` (geri sayım) ile saniye saniye
 * akar. Yay ~10 dk'da bir, bitişte de sayaç durdurulmak üzere yenilenir
 * (önceden görsel yalnızca uygulama çalışırken güncellendiği için donuyordu).
 */
internal object FastingLive {
    private const val REFRESH_MS = 10 * 60 * 1000L

    fun views(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
        kind: String,
        imageKey: String,
        maxWidth: Int,
        requestCode: Int,
        provider: Class<*>,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.fasting_live_widget)
        views.setOnClickPendingIntent(
            R.id.fasting_live_root,
            widgetLaunchIntent(context, "fastingapp://fasting?homeWidget", requestCode),
        )
        val bitmap = widgetData.getString(imageKey, null)?.let { decodeWidgetBitmap(it, maxWidth) }
        val live = readLive(widgetData, kind)
        if (bitmap == null || live == null) {
            if (bitmap != null) views.setImageViewBitmap(R.id.fasting_live_image, bitmap)
            views.setViewVisibility(R.id.fasting_live_timer_box, View.GONE)
            return views
        }

        val now = System.currentTimeMillis()
        val progress = live.progress(now)
        views.setImageViewBitmap(R.id.fasting_live_image, withRing(bitmap, live.spec, progress))
        views.setViewVisibility(R.id.fasting_live_timer_box, View.VISIBLE)
        placeTimer(context, appWidgetManager, widgetId, views, live, now)
        if (now < live.end) scheduleRefresh(context, provider, requestCode, min(now + REFRESH_MS, live.end))
        return views
    }

    private class Spec(json: JSONObject) {
        val w = json.optDouble("w", 310.0)
        val h = json.optDouble("h", 310.0)
        val tx = json.optDouble("tx")
        val ty = json.optDouble("ty")
        val leading = json.optString("ta") == "l"
        val ts = json.optDouble("ts", 40.0)
        /** Sola dayalı metnin en geniş hâli (maskota taşmasın); yoksa sınır yok. */
        val tw: Double? = if (json.has("tw")) json.optDouble("tw") else null
        val tc = parseColor(json.optString("tc"))
        val hasRing = json.has("rr")
        val rx = json.optDouble("rx")
        val ry = json.optDouble("ry")
        val rr = json.optDouble("rr")
        val rs = json.optDouble("rs")
        val rc = parseColor(json.optString("rc"))
    }

    private class Live(val start: Long, val end: Long, val spec: Spec, val suffix: String?) {
        fun progress(now: Long): Float {
            val total = end - start
            if (total <= 0) return 0f
            return ((now - start).toFloat() / total).coerceIn(0f, 1f)
        }
    }

    private fun readLive(data: SharedPreferences, kind: String): Live? {
        if (readLong(data, "fasting_live") != 1L) return null
        val start = readLong(data, "fasting_start_ms")
        val end = readLong(data, "fasting_end_ms")
        if (start <= 0 || end <= start) return null
        val spec = try {
            JSONObject(data.getString("fasting_live_spec", null) ?: return null)
                .optJSONObject(kind) ?: return null
        } catch (_: Exception) {
            return null
        }
        val suffix = if (kind == "medium") data.getString("fasting_left_label", null) else null
        return Live(start, end, Spec(spec), suffix)
    }

    /** home_widget küçük sayıları Int, büyükleri Long yazar. */
    private fun readLong(data: SharedPreferences, key: String): Long =
        try {
            data.getLong(key, 0L)
        } catch (_: ClassCastException) {
            try {
                data.getInt(key, 0).toLong()
            } catch (_: ClassCastException) {
                0L
            }
        }

    private fun parseColor(hex: String): Int =
        try {
            Color.parseColor(if (hex.startsWith("#")) hex else "#$hex")
        } catch (_: Exception) {
            Color.DKGRAY
        }

    private fun withRing(source: Bitmap, spec: Spec, progress: Float): Bitmap {
        if (!spec.hasRing || progress <= 0f) return source
        val bitmap = source.copy(Bitmap.Config.ARGB_8888, true) ?: return source
        val k = (bitmap.width / spec.w).toFloat()
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = (spec.rs * k).toFloat()
            strokeCap = Paint.Cap.ROUND
            color = spec.rc
        }
        val cx = (spec.rx * k).toFloat()
        val cy = (spec.ry * k).toFloat()
        val r = (spec.rr * k).toFloat()
        Canvas(bitmap).drawArc(RectF(cx - r, cy - r, cx + r, cy + r), -90f, 360f * progress, false, paint)
        return bitmap
    }

    /** Görsel `fitCenter`: ölçek ve boşluk widget'ın dp boyutundan. */
    private fun placeTimer(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        views: RemoteViews,
        live: Live,
        now: Long,
    ) {
        val spec = live.spec
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val density = context.resources.displayMetrics.density
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 160
        val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 160
        val scale = min(widthDp / spec.w, heightDp / spec.h)
        val ox = (widthDp - spec.w * scale) / 2
        val oy = (heightDp - spec.h * scale) / 2

        // Halkada saniyeli sayaç iç çapa sığsın ("0:00:00" ≈ 3.9 em).
        var sizeDp = spec.ts * scale
        if (spec.hasRing) sizeDp = min(sizeDp, (spec.rr - spec.rs) * 2 * scale / 3.9)
        // Sola dayalı satır ("7:33:31 kaldı") [Spec.tw] içine sığsın (≈ 0.55 em/harf).
        spec.tw?.let { tw ->
            val ems = 3.9 + ((live.suffix?.length ?: 0) + 1) * 0.55
            sizeDp = min(sizeDp, tw * scale / ems)
        }
        views.setTextViewTextSize(R.id.fasting_live_timer, TypedValue.COMPLEX_UNIT_DIP, sizeDp.toFloat())
        views.setTextColor(R.id.fasting_live_timer, spec.tc)

        val suffix = live.suffix
        if (!suffix.isNullOrEmpty()) {
            views.setViewVisibility(R.id.fasting_live_suffix, View.VISIBLE)
            views.setTextViewText(R.id.fasting_live_suffix, " $suffix")
            views.setTextViewTextSize(R.id.fasting_live_suffix, TypedValue.COMPLEX_UNIT_DIP, sizeDp.toFloat())
            views.setTextColor(R.id.fasting_live_suffix, spec.tc)
        } else {
            views.setViewVisibility(R.id.fasting_live_suffix, View.GONE)
        }

        val running = now < live.end
        val base = SystemClock.elapsedRealtime() + max(0L, live.end - now)
        views.setChronometer(R.id.fasting_live_timer, base, null, running)
        views.setChronometerCountDown(R.id.fasting_live_timer, true)

        val px = { dp: Double -> (dp * density).toInt() }
        val top = px(spec.ty * scale + oy - sizeDp * 0.6)
        if (spec.leading) {
            views.setInt(R.id.fasting_live_timer_box, "setGravity", Gravity.TOP or Gravity.START)
            views.setViewPadding(R.id.fasting_live_timer_box, px(spec.tx * scale + ox), top, 0, 0)
        } else {
            views.setInt(R.id.fasting_live_timer_box, "setGravity", Gravity.TOP or Gravity.CENTER_HORIZONTAL)
            // Yatay merkez cx olsun: kutunun iki yanındaki boşluk farkı.
            val cx = spec.tx * scale + ox
            val shift = px(2 * cx - widthDp)
            views.setViewPadding(
                R.id.fasting_live_timer_box,
                max(0, shift),
                top,
                max(0, -shift),
                0,
            )
        }
    }

    /**
     * Yayı tazelemek ve bitişte sayacı durdurmak için yenileme. Kesin alarm
     * izni istenmez: `setWindow` (1 dk pencere); cihaz uykudaysa ekran
     * açılınca gelir.
     */
    private fun scheduleRefresh(context: Context, provider: Class<*>, requestCode: Int, at: Long) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, provider))
        if (ids.isEmpty()) return
        val intent = Intent(context, provider).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            1000 + requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarms.setWindow(AlarmManager.RTC, at, 60_000L, pending)
    }
}

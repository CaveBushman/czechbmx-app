package com.example.czechbmx_app

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import androidx.car.app.CarAppService
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.car.app.model.Action
import androidx.car.app.model.CarColor
import androidx.car.app.model.CarIcon
import androidx.car.app.model.CarLocation
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.Metadata
import androidx.car.app.model.Place
import androidx.car.app.model.PlaceListMapTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.validation.HostValidator
import androidx.core.graphics.drawable.IconCompat
import java.time.LocalDate
import java.time.temporal.ChronoUnit

// ── Service & Session ─────────────────────────────────────────────────────────

class CzechBmxCarAppService : CarAppService() {
    override fun createHostValidator(): HostValidator = HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
    override fun onCreateSession(): Session = CzechBmxSession()
}

private class CzechBmxSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen = MainMenuCarScreen(carContext)
}

// ── Helpers ───────────────────────────────────────────────────────────────────

private object CarPrefs {
    const val FILE = "HomeWidgetPreferences"

    fun prefs(ctx: androidx.car.app.CarContext): SharedPreferences =
        ctx.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun str(prefs: SharedPreferences, key: String, fallback: String = "") =
        prefs.getString(key, fallback) ?: fallback

    fun int(prefs: SharedPreferences, key: String, fallback: Int = 0) =
        prefs.getInt(key, fallback)

    fun double(prefs: SharedPreferences, key: String): Double? {
        val prefKey = "home_widget.double.$key"
        return if (prefs.contains(prefKey))
            java.lang.Double.longBitsToDouble(prefs.getLong(prefKey, 0L))
        else null
    }
}

private fun daysLabel(isoDate: String): String {
    if (isoDate.length < 10) return ""
    return try {
        val days = ChronoUnit.DAYS.between(LocalDate.now(), LocalDate.parse(isoDate.substring(0, 10)))
        when {
            days < 0  -> ""
            days == 0L -> "Dnes"
            days == 1L -> "Zítra"
            else       -> "za $days dní"
        }
    } catch (_: Exception) { "" }
}

private fun formatDate(isoDate: String): String {
    if (isoDate.length < 10) return isoDate
    val p = isoDate.substring(0, 10).split("-")
    return if (p.size < 3) isoDate else "${p[2]}. ${p[1]}. ${p[0]}"
}

private fun eventSubtitle(city: String, dateStr: String): String = buildString {
    if (city.isNotEmpty()) append(city)
    if (dateStr.isNotEmpty()) {
        if (isNotEmpty()) append("  •  ")
        append(formatDate(dateStr))
    }
    val dl = daysLabel(dateStr)
    if (dl.isNotEmpty()) {
        if (isNotEmpty()) append("  •  ")
        append(dl)
    }
}

private fun launchNav(ctx: androidx.car.app.CarContext, lat: Double, lon: Double) {
    try {
        ctx.startCarApp(
            Intent(Intent.ACTION_VIEW, android.net.Uri.parse("google.navigation:q=$lat,$lon"))
                .apply { setPackage("com.google.android.apps.maps") }
        )
    } catch (_: Exception) {}
}

// ── Main menu ─────────────────────────────────────────────────────────────────

private class MainMenuCarScreen(ctx: androidx.car.app.CarContext) : Screen(ctx) {

    override fun onGetTemplate(): Template {
        val list = ItemList.Builder()
            .addItem(
                Row.Builder()
                    .setTitle("Příští závod")
                    .addText("Nadcházející závod s navigací")
                    .setBrowsable(true)
                    .setOnClickListener { screenManager.push(NextRaceCarScreen(carContext)) }
                    .build()
            )
            .addItem(
                Row.Builder()
                    .setTitle("Kalendář závodů")
                    .addText("Nadcházející závody")
                    .setBrowsable(true)
                    .setOnClickListener { screenManager.push(CalendarCarScreen(carContext)) }
                    .build()
            )
            .addItem(
                Row.Builder()
                    .setTitle("Novinky")
                    .addText("Nejnovější zprávy z Czech BMX")
                    .setBrowsable(true)
                    .setOnClickListener { screenManager.push(NewsCarScreen(carContext)) }
                    .build()
            )
            .build()

        return ListTemplate.Builder()
            .setTitle("Czech BMX")
            .setHeaderAction(Action.APP_ICON)
            .setSingleList(list)
            .build()
    }
}

// ── Next race (map + countdown) ───────────────────────────────────────────────

private class NextRaceCarScreen(ctx: androidx.car.app.CarContext) : Screen(ctx) {

    override fun onGetTemplate(): Template {
        val prefs = CarPrefs.prefs(carContext)
        val name    = CarPrefs.str(prefs, "next_race_name")
        val dateStr = CarPrefs.str(prefs, "next_race_date")
        val city    = CarPrefs.str(prefs, "next_race_city")
        val lat     = CarPrefs.double(prefs, "next_race_lat")
        val lon     = CarPrefs.double(prefs, "next_race_lon")

        if (name.isEmpty()) {
            return ListTemplate.Builder()
                .setTitle("Příští závod")
                .setHeaderAction(Action.BACK)
                .setSingleList(
                    ItemList.Builder()
                        .addItem(
                            Row.Builder()
                                .setTitle("Žádné nadcházející závody")
                                .addText("Otevřete aplikaci pro více informací")
                                .build()
                        )
                        .build()
                )
                .build()
        }

        val rowBuilder = Row.Builder()
            .setTitle(name)
        val subtitle = eventSubtitle(city, dateStr)
        if (subtitle.isNotEmpty()) rowBuilder.addText(subtitle)

        if (lat != null && lon != null) {
            rowBuilder
                .setMetadata(Metadata.Builder().setPlace(Place.Builder(CarLocation.create(lat, lon)).build()).build())
                .setBrowsable(true)
                .setOnClickListener { launchNav(carContext, lat, lon) }
        }

        return PlaceListMapTemplate.Builder()
            .setTitle("Příští závod")
            .setHeaderAction(Action.BACK)
            .setItemList(ItemList.Builder().addItem(rowBuilder.build()).build())
            .build()
    }
}

// ── Calendar (up to 6 upcoming races) ────────────────────────────────────────

private class CalendarCarScreen(ctx: androidx.car.app.CarContext) : Screen(ctx) {

    override fun onGetTemplate(): Template {
        val prefs = CarPrefs.prefs(carContext)
        val count = CarPrefs.int(prefs, "car_events_count")

        if (count == 0) {
            return ListTemplate.Builder()
                .setTitle("Kalendář závodů")
                .setHeaderAction(Action.BACK)
                .setSingleList(
                    ItemList.Builder()
                        .addItem(
                            Row.Builder()
                                .setTitle("Žádné nadcházející závody")
                                .addText("Otevřete aplikaci pro více informací")
                                .build()
                        )
                        .build()
                )
                .build()
        }

        val listBuilder = ItemList.Builder()
        var hasCoords = false

        for (i in 0 until count) {
            val name    = CarPrefs.str(prefs, "car_event_${i}_name")
            val dateStr = CarPrefs.str(prefs, "car_event_${i}_date")
            val city    = CarPrefs.str(prefs, "car_event_${i}_city")
            val lat     = CarPrefs.double(prefs, "car_event_${i}_lat")
            val lon     = CarPrefs.double(prefs, "car_event_${i}_lon")

            val rowBuilder = Row.Builder().setTitle(name)
            val subtitle = eventSubtitle(city, dateStr)
            if (subtitle.isNotEmpty()) rowBuilder.addText(subtitle)

            if (lat != null && lon != null) {
                hasCoords = true
                rowBuilder
                    .setMetadata(Metadata.Builder().setPlace(Place.Builder(CarLocation.create(lat, lon)).build()).build())
                    .setBrowsable(true)
                    .setOnClickListener { launchNav(carContext, lat, lon) }
            }
            listBuilder.addItem(rowBuilder.build())
        }

        return if (hasCoords) {
            PlaceListMapTemplate.Builder()
                .setTitle("Kalendář závodů")
                .setHeaderAction(Action.BACK)
                .setItemList(listBuilder.build())
                .build()
        } else {
            ListTemplate.Builder()
                .setTitle("Kalendář závodů")
                .setHeaderAction(Action.BACK)
                .setSingleList(listBuilder.build())
                .build()
        }
    }
}

// ── News headlines ────────────────────────────────────────────────────────────

private class NewsCarScreen(ctx: androidx.car.app.CarContext) : Screen(ctx) {

    override fun onGetTemplate(): Template {
        val prefs = CarPrefs.prefs(carContext)
        val count = CarPrefs.int(prefs, "car_news_count")

        val listBuilder = ItemList.Builder()

        if (count == 0) {
            listBuilder.addItem(
                Row.Builder()
                    .setTitle("Žádné zprávy")
                    .addText("Otevřete aplikaci pro více informací")
                    .build()
            )
        } else {
            for (i in 0 until count) {
                val title   = CarPrefs.str(prefs, "car_news_${i}_title")
                val dateStr = CarPrefs.str(prefs, "car_news_${i}_date")
                val rowBuilder = Row.Builder().setTitle(title)
                if (dateStr.isNotEmpty()) rowBuilder.addText(formatDate(dateStr))
                listBuilder.addItem(rowBuilder.build())
            }
        }

        return ListTemplate.Builder()
            .setTitle("Novinky")
            .setHeaderAction(Action.BACK)
            .setSingleList(listBuilder.build())
            .build()
    }
}

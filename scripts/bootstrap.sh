
manifest xmlns:android="http://schemas.android.com/apk/res/android">
    uses-permission android:name="android.permission.INTERNET" />
    uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    application
        android:allowBackup="true"
        android:label="Iliya Network"
        android:supportsRtl="true"
        android:theme="@android:style/Theme.Material.NoActionBar">
        activity android:name=".MainActivity" android:exported="true">
            intent-filter>
                action android:name="android.intent.action.MAIN" />
                category android:name="android.intent.category.LAUNCHER" />
            /intent-filter>
        /activity>
    /application>
/manifest>
EOF

cat > app/src/main/java/com/iliyanetwork/app/MainActivity.kt >'EOF'
package com.iliyanetwork.app

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Bundle
import android.os.SystemClock
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.roundToInt

private val Ink = Color(0xFF080D18)
private val Panel = Color(0xFF141E31)
private val Mint = Color(0xFF65E0BD)
private val Muted = Color(0xFF9EABC0)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        setContent { NetworkScreen(manager) }
    }
}

private data class NetState(val type: String, val online: Boolean, val metered: Boolean)

private fun currentNetwork(manager: ConnectivityManager): NetState {
    val net = manager.activeNetwork ?: return NetState("بدون اتصال", false, false)
    val caps = manager.getNetworkCapabilities(net)
        ?: return NetState("نامشخص", false, manager.isActiveNetworkMetered)
    val kind = when {
        caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "Wi‑Fi"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "اینترنت همراه"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
        caps.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH) -> "Bluetooth"
        else -> "اتصال دیگر"
    }
    return NetState(
        kind,
        caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED),
        manager.isActiveNetworkMetered
    )
}

private suspend fun httpsSamples(): ListLong?> = withContext(Dispatchers.IO) {
    (1..5).map {
        var conn: HttpURLConnection? = null
        try {
            val start = SystemClock.elapsedRealtime()
            conn = (URL("https://www.cloudflare.com/cdn-cgi/trace").openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 4000
                readTimeout = 4000
                useCaches = false
            }
            if (conn.responseCode in 200..299) {
                conn.inputStream.use { it.read() }
                SystemClock.elapsedRealtime() - start
            } else null
        } catch (_: Exception) {
            null
        } finally {
            conn?.disconnect()
        }
    }
}

@Composable
private fun NetworkScreen(manager: ConnectivityManager) {
    var state by remember { mutableStateOf(currentNetwork(manager)) }
    var samples by remember { mutableStateOf(ListLong?>(emptyList()) }
    var busy by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val ok = samples.filterNotNull()
    val avg = ok.takeIf { it.isNotEmpty() }?.average()?.roundToInt()
    val statusText = if (state.online) "اینترنت متصل و تأییدشده" else "اینترنت تأیید نشده یا قطع است"

    MaterialTheme(colorScheme = darkColorScheme(
        background = Ink, surface = Panel, primary = Mint,
        onBackground = Color.White, onSurface = Color.White
    )) {
        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
            Column(
                Modifier.fillMaxSize().background(Ink).verticalScroll(rememberScrollState()).padding(22.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text("ILIYA NETWORK", color = Mint, fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 2.sp)
                Text("مرکز وضعیت شبکه", color = Color.White, fontSize = 27.sp, fontWeight = FontWeight.Bold)
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.cardColors(containerColor = Panel)
                ) {
                    Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text("وضعیت اتصال", color = Muted, fontSize = 13.sp)
                        Text(statusText, color = if (state.online) Mint else Color(0xFFFFC36B), fontSize = 19.sp, fontWeight = FontWeight.Bold)
                        Text("نوع شبکه: ${state.type}", color = Color.White, fontSize = 15.sp)
                        Text(if (state.metered) "شبکه مصرفی" else "شبکه غیرمصرفی یا نامشخص", color = Muted, fontSize = 12.sp)
                    }
                }
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.cardColors(containerColor = Panel)
                ) {
                    Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
 Text("بررسی پاسخ‌گویی", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold)
 Text("میانگین: ${avg?.let { "$it ms" } ?: "—"}", color = Mint, fontSize = 22.sp, fontWeight = FontWeight.Bold)
 Text("کمترین: ${ok.minOrNull()?.let { "$it ms" } ?: "—"}", color = Muted)
 Text("بیشترین: ${ok.maxOrNull()?.let { "$it ms" } ?: "—"}", color = Muted)
 Text(if (samples.isEmpty()) "هنوز آزمایشی اجرا نشده." else "موفق: ${ok.size} از 5  |  ناموفق: ${5 - ok.size}", color = Muted, fontSize = 12.sp)
                        Button(
                            onClick = {
                                scope.launch {
 busy = true
                                    state = currentNetwork(manager)
                                    samples = httpsSamples()
                                    state = currentNetwork(manager)
 busy = false
                                }
                            },
                            enabled = !busy,
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp)
                        ) {
 Text(if (busy) "در حال بررسی..." else "شروع بررسی اتصال")
                        }
 Text("این مقدار زمان پاسخ HTTPS است؛ پینگ ICMP یا تست سرعت دانلود/آپلود نیست.", color = Muted, fontSize = 11.sp)
                    }
                }
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(22.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF101827))
                ) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
 Text("در مسیر توسعه", color = Color.White, fontWeight = FontWeight.Bold)
 Text("پیام‌رسانی محلی با Wi‑Fi و Bluetooth و بخش اجتماعی در نسخه‌های بعدی اضافه می‌شوند؛ هنوز فعال نیستند.", color = Muted, fontSize = 12.sp)
                    }
                }
 Text("نسخه 0.2.1 • Android", color = Muted, fontSize = 11.sp)
            }
        }
    }
}
EOF

cat > README.md >'EOF'
# Iliya Network — Android
Version 0.2.1. The current milestone contains a network status monitor and five HTTPS response-time checks.
The response time is not ICMP ping or a download/upload speed test. Social and nearby offline communication are planned, not yet implemented.
GitHub Actions builds a debug APK and uploads it as the `iliya-network-debug-apk` artifact.
EOF

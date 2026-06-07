package com.example.latente

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "latente/file_import"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickTextFile" -> pickTextFile(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickTextFile(result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error(
                "picker_busy",
                "Un selettore file e gia aperto.",
                null
            )
            return
        }

        pendingPickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/json", "text/plain", "text/*")
            )
        }

        try {
            startActivityForResult(intent, pickTextRequestCode)
        } catch (error: Exception) {
            pendingPickResult = null
            result.error(
                "picker_unavailable",
                "Selettore file non disponibile.",
                error.localizedMessage
            )
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != pickTextRequestCode) {
            return
        }

        val result = pendingPickResult ?: return
        pendingPickResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        try {
            result.success(readTextFromUri(data.data!!))
        } catch (error: Exception) {
            result.error(
                "read_failed",
                "Impossibile leggere il file selezionato.",
                error.localizedMessage
            )
        }
    }

    private fun readTextFromUri(uri: Uri): String {
        val stream = contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("File non leggibile.")

        return stream.bufferedReader(Charsets.UTF_8).use { reader ->
            reader.readText()
        }
    }

    companion object {
        private const val pickTextRequestCode = 4101
    }
}

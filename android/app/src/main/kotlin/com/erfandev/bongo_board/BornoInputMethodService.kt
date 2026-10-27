package com.erfandev.bongo_board

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.MotionEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputMethodManager
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.Color
import kotlin.math.max

class BornoInputMethodService : InputMethodService() {
    private enum class Mode { PHONETIC, BANGLA, ENGLISH }
    private enum class Kind { CHARACTER, SUGGESTION, SHIFT, DELETE, SPACE, ENTER, MODE, SYMBOLS, LETTERS, MIC, SETTINGS }

    private data class Key(
        val label: String,
        val output: String = label,
        val hint: String = "",
        val alternatives: List<String> = emptyList(),
        val kind: Kind = Kind.CHARACTER,
        val weight: Float = 1f,
    )

    private var mode = Mode.PHONETIC
    private var shifted = false
    private var symbols = false
    private var composingRoman = ""
    private var voiceStatus = ""
    private var passwordInput = false
    private var recognizer: SpeechRecognizer? = null
    private var keyboard: KeyboardView? = null

    override fun onCreateInputView(): View {
        keyboard = KeyboardView()
        return keyboard!!
    }

    override fun onEvaluateFullscreenMode(): Boolean = false

    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        if (!restarting) {
            composingRoman = ""
            shifted = false
            symbols = false
        }
        voiceStatus = ""
        val inputType = attribute?.inputType ?: 0
        val variation = inputType and EditorInfo.TYPE_MASK_VARIATION
        passwordInput = when (inputType and EditorInfo.TYPE_MASK_CLASS) {
            EditorInfo.TYPE_CLASS_TEXT -> variation in setOf(
                EditorInfo.TYPE_TEXT_VARIATION_PASSWORD,
                EditorInfo.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD,
                EditorInfo.TYPE_TEXT_VARIATION_WEB_PASSWORD,
            )
            EditorInfo.TYPE_CLASS_NUMBER -> variation == EditorInfo.TYPE_NUMBER_VARIATION_PASSWORD
            else -> false
        }
        keyboard?.invalidate()
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        keyboard?.invalidate()
    }

    override fun onFinishInput() {
        finishComposing()
        stopVoice()
        super.onFinishInput()
    }

    private fun inputConnection(): InputConnection? = currentInputConnection

    private fun type(value: String) {
        val connection = inputConnection() ?: return
        if (value.isEmpty()) return
        if (!passwordInput && mode == Mode.PHONETIC && value.length == 1 && value[0].isLetter() && value[0].code < 128) {
            composingRoman += if (shifted) value.uppercase() else value.lowercase()
            connection.setComposingText(Phonetic.convert(composingRoman), 1)
        } else {
            finishComposing()
            connection.commitText(value, 1)
        }
        shifted = false
        keyboard?.invalidate()
    }

    private fun finishComposing() {
        val connection = inputConnection() ?: return
        if (composingRoman.isNotEmpty()) {
            connection.commitText(Phonetic.convert(composingRoman), 1)
            composingRoman = ""
        } else {
            connection.finishComposingText()
        }
    }

    private fun backspace() {
        val connection = inputConnection() ?: return
        if (composingRoman.isNotEmpty()) {
            composingRoman = composingRoman.dropLast(1)
            if (composingRoman.isEmpty()) connection.setComposingText("", 0)
            else connection.setComposingText(Phonetic.convert(composingRoman), 1)
        } else {
            val before = connection.getTextBeforeCursor(2, 0)
            if (!before.isNullOrEmpty()) {
                val count = Character.charCount(Character.codePointBefore(before, before.length))
                connection.deleteSurroundingText(count, 0)
            }
        }
        keyboard?.invalidate()
    }

    private fun space() {
        finishComposing()
        inputConnection()?.commitText(" ", 1)
        shifted = false
        keyboard?.invalidate()
    }

    private fun enter() {
        val connection = inputConnection() ?: return
        finishComposing()
        val action = currentInputEditorInfo?.imeOptions?.and(EditorInfo.IME_MASK_ACTION)
            ?: EditorInfo.IME_ACTION_NONE
        if (action != EditorInfo.IME_ACTION_NONE && action != EditorInfo.IME_ACTION_UNSPECIFIED) {
            connection.performEditorAction(action)
        } else {
            connection.commitText("\n", 1)
        }
    }

    private fun insertSuggestion(value: String) {
        val connection = inputConnection() ?: return
        if (composingRoman.isNotEmpty()) {
            connection.setComposingText(value, 1)
            connection.finishComposingText()
            composingRoman = ""
            connection.commitText(" ", 1)
        } else {
            val before = connection.getTextBeforeCursor(64, 0)?.toString().orEmpty()
            val current = Regex("[\\p{L}\\p{M}']+$").find(before)?.value.orEmpty()
            if (current.isNotEmpty()) connection.deleteSurroundingText(current.length, 0)
            connection.commitText("$value ", 1)
        }
        keyboard?.invalidate()
    }

    private fun toggleMode() {
        finishComposing()
        mode = when (mode) {
            Mode.PHONETIC -> Mode.BANGLA
            Mode.BANGLA -> Mode.ENGLISH
            Mode.ENGLISH -> Mode.PHONETIC
        }
        shifted = false
        symbols = false
        keyboard?.invalidate()
    }

    private fun startVoice() {
        if (passwordInput) {
            voiceStatus = "পাসওয়ার্ড ফিল্ডে ভয়েস বন্ধ"
            keyboard?.invalidate()
            return
        }
        if (Build.VERSION.SDK_INT >= 23 && checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            voiceStatus = "ভয়েসের জন্য Borno অ্যাপে মাইক অনুমতি দিন"
            keyboard?.invalidate()
            return
        }
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            voiceStatus = "এই ডিভাইসে ভয়েস টাইপিং নেই"
            keyboard?.invalidate()
            return
        }
        stopVoice()
        voiceStatus = "শুনছি… কথা বলুন"
        val speech = SpeechRecognizer.createSpeechRecognizer(this)
        recognizer = speech
        speech.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: android.os.Bundle?) { voiceStatus = "শুনছি… কথা বলুন"; keyboard?.invalidate() }
            override fun onBeginningOfSpeech() { voiceStatus = "শুনছি…"; keyboard?.invalidate() }
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() { voiceStatus = "লিখছি…"; keyboard?.invalidate() }
            override fun onError(error: Int) {
                voiceStatus = if (error == SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
                    "ভয়েসের জন্য Borno অ্যাপে মাইক অনুমতি দিন"
                } else {
                    "শোনা যায়নি—আবার মাইক চাপুন"
                }
                stopVoice()
                keyboard?.invalidate()
            }
            override fun onResults(results: android.os.Bundle?) {
                val spoken = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                if (!spoken.isNullOrBlank()) {
                    finishComposing()
                    inputConnection()?.commitText(spoken.trim(), 1)
                    inputConnection()?.commitText(" ", 1)
                }
                voiceStatus = ""
                stopVoice()
                keyboard?.invalidate()
            }
            override fun onPartialResults(partialResults: android.os.Bundle?) {
                val partial = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                if (!partial.isNullOrBlank()) {
                    voiceStatus = partial
                    keyboard?.invalidate()
                }
            }
            override fun onEvent(eventType: Int, params: android.os.Bundle?) {}
        })
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "bn-BD")
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "bn-BD")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
        }
        speech.startListening(intent)
        keyboard?.invalidate()
    }

    private fun stopVoice() {
        recognizer?.let {
            it.cancel()
            it.destroy()
        }
        recognizer = null
    }

    private inner class KeyboardView : View(this@BornoInputMethodService) {
        private val density = resources.displayMetrics.density
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val handler = Handler(Looper.getMainLooper())
        private val keyRects = mutableListOf<Pair<Key, RectF>>()
        private var pressed: Key? = null
        private var pressedRect: RectF? = null
        private var longPress = false
        private var popupIndex = 0
        private var popupRect = RectF()
        private val longPressTask = Runnable {
            val key = pressed ?: return@Runnable
            if (key.alternatives.isNotEmpty()) {
                longPress = true
                popupIndex = 0
                invalidate()
            }
        }
        private val repeatTask = object : Runnable {
            override fun run() {
                if (pressed?.kind == Kind.DELETE) {
                    backspace()
                    handler.postDelayed(this, 70)
                }
            }
        }

        init {
            isFocusable = false
            contentDescription = "Borno Bangla keyboard"
        }

        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            val desired = (280 * density).toInt()
            val height = resolveSize(desired, heightMeasureSpec)
            setMeasuredDimension(MeasureSpec.getSize(widthMeasureSpec), height)
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            canvas.drawColor(Color.rgb(25, 30, 28))
            keyRects.clear()
            val pad = 4f * density
            val gap = 4f * density
            val toolbarH = 34f * density
            val suggestionH = 33f * density
            drawToolbar(canvas, pad, toolbarH, gap)
            drawSuggestions(canvas, pad, toolbarH + gap, suggestionH, gap)

            val bottomTop = height - 49f * density
            val rowsTop = toolbarH + suggestionH + 3f * gap
            val available = bottomTop - rowsTop - 2f * gap
            val rowH = max(28f * density, available / 3f)
            val rows = rows()
            rows.forEachIndexed { index, row ->
                drawRow(canvas, row, rowsTop + index * (rowH + gap), rowH, gap, pad, if (index == 1) 0.045f else 0f)
            }
            drawBottom(canvas, bottomTop, 45f * density, gap, pad)
            drawPopup(canvas)
        }

        private fun drawToolbar(canvas: Canvas, pad: Float, h: Float, gap: Float) {
            val modeLabel = when (mode) {
                Mode.PHONETIC -> "ফোনেটিক"
                Mode.BANGLA -> "বাংলা"
                Mode.ENGLISH -> "English"
            }
            val modeKey = Key(modeLabel, kind = Kind.MODE, weight = 2f)
            val micKey = Key("🎙", kind = Kind.MIC)
            val settingsKey = Key("⚙", kind = Kind.SETTINGS)
            val modeRect = RectF(pad, 2f * density, width * .38f, h - 2f * density)
            val micRect = RectF(width * .43f, 2f * density, width * .56f, h - 2f * density)
            val settingsRect = RectF(width - pad - 36f * density, 2f * density, width - pad, h - 2f * density)
            drawButton(canvas, modeKey, modeRect, true)
            drawButton(canvas, micKey, micRect, true)
            drawButton(canvas, settingsKey, settingsRect, true)
            keyRects.add(modeKey to modeRect)
            keyRects.add(micKey to micRect)
            keyRects.add(settingsKey to settingsRect)
        }

        private fun drawSuggestions(canvas: Canvas, pad: Float, top: Float, h: Float, gap: Float) {
            val left = pad
            val right = width - pad
            if (voiceStatus.isNotEmpty()) {
                paint.color = Color.rgb(189, 225, 160)
                paint.textSize = 13f * density
                paint.typeface = Typeface.DEFAULT
                paint.textAlign = Paint.Align.CENTER
                canvas.drawText(voiceStatus.take(40), width / 2f, top + h * .68f, paint)
                return
            }
            val values = suggestions()
            if (values.isEmpty()) return
            val cell = (right - left - gap * (values.size - 1)) / values.size
            values.forEachIndexed { i, value ->
                val rect = RectF(left + i * (cell + gap), top, left + i * (cell + gap) + cell, top + h)
                val key = Key(value, output = value, kind = Kind.SUGGESTION)
                drawButton(canvas, key, rect, false)
                keyRects.add(key to rect)
            }
        }

        private fun rows(): List<List<Key>> {
            if (symbols) {
                return listOf(
                    listOf("1","2","3","4","5","6","7","8","9","0").map { Key(it) },
                    listOf("@","#","$","%","&","-","+","(",")").map { Key(it, alternatives = listOf(it, "№", "‰")) },
                    listOf(Key("=\\<", kind = Kind.LETTERS, weight = 1.5f)) +
                        listOf("!", "\"", "'", ":", ";", "/", "?").map { Key(it) } +
                        Key("⌫", kind = Kind.DELETE, weight = 1.5f),
                )
            }
            if (mode == Mode.BANGLA) {
                val first = listOf("দ","ূ","ী","র","ট","এ","ু","ি","ও","প","ে","ো")
                val second = listOf("া","স","ড","ত","গ","হ","জ","ক","ল")
                val third = listOf("য়","শ","চ","আ","ব","ন","ম","ৃ","্")
                val firstAlt = listOf("ধ","ঊ","ঈ","ড়","ঠ","ঐ","উ","ই","ঔ","ফ","ৈ","ৌ")
                val secondAlt = listOf("অ","ষ","ঢ","থ","ঘ","ঃ","ঝ","খ","ং")
                val thirdAlt = listOf("য","ঢ়","ছ","ঋ","ভ","ণ","ঙ","ৃ","ঁ")
                return listOf(
                    first.mapIndexed { i, value ->
                        val primary = if (shifted) firstAlt[i] else value
                        Key(primary, hint = if (shifted) value else firstAlt[i], alternatives = listOf(primary, if (shifted) value else firstAlt[i]))
                    },
                    second.mapIndexed { i, value ->
                        val primary = if (shifted) secondAlt[i] else value
                        Key(primary, hint = if (shifted) value else secondAlt[i], alternatives = listOf(primary, if (shifted) value else secondAlt[i]))
                    },
                    listOf(Key("⇧", kind = Kind.SHIFT, weight = 1.4f)) +
                        third.mapIndexed { i, value ->
                            val primary = if (shifted) thirdAlt[i] else value
                            Key(primary, hint = if (shifted) value else thirdAlt[i], alternatives = listOf(primary, if (shifted) value else thirdAlt[i]))
                        } +
                        Key("⌫", kind = Kind.DELETE, weight = 1.4f),
                )
            }
            val phoneticHints = listOf(
                listOf("ক", "ৱ", "এ", "র", "ত", "য়", "উ", "ই", "অ", "প"),
                listOf("আ", "স", "দ", "ফ", "গ", "হ", "জ", "ক", "ল"),
                listOf("য", "ক্স", "চ", "ভ", "ব", "ন", "ম"),
            )
            val first = "qwertyuiop".mapIndexed { i, c ->
                val label = if (shifted) c.uppercase() else c.toString()
                val hint = if (mode == Mode.PHONETIC) phoneticHints[0][i] else ""
                val alternatives = if (mode == Mode.PHONETIC) listOf(label, hint) else emptyList()
                Key(label, output = label, hint = hint, alternatives = alternatives)
            }
            val second = "asdfghjkl".mapIndexed { i, c ->
                val label = if (shifted) c.uppercase() else c.toString()
                val hint = if (mode == Mode.PHONETIC) phoneticHints[1][i] else ""
                val alternatives = if (mode == Mode.PHONETIC) listOf(label, hint) else emptyList()
                Key(label, output = label, hint = hint, alternatives = alternatives)
            }
            val third = "zxcvbnm".mapIndexed { i, c ->
                val label = if (shifted) c.uppercase() else c.toString()
                val hint = if (mode == Mode.PHONETIC) phoneticHints[2][i] else ""
                val alternatives = if (mode == Mode.PHONETIC) listOf(label, hint) else emptyList()
                Key(label, output = label, hint = hint, alternatives = alternatives)
            }
            return listOf(
                first,
                second,
                listOf(Key("⇧", kind = Kind.SHIFT, weight = 1.4f)) + third + Key("⌫", kind = Kind.DELETE, weight = 1.4f),
            )
        }

        private fun drawBottom(canvas: Canvas, top: Float, h: Float, gap: Float, pad: Float) {
            val keys = listOf(
                Key(if (symbols) "ABC" else "?123", kind = if (symbols) Kind.LETTERS else Kind.SYMBOLS, weight = 1.6f),
                Key("🌐", kind = Kind.MODE, weight = 1.3f),
                Key("স্পেস", kind = Kind.SPACE, weight = 5.3f),
                Key("।", output = "।", alternatives = listOf("।", "."), weight = 1.3f),
                Key("↵", kind = Kind.ENTER, weight = 1.6f),
            )
            drawRow(canvas, keys, top, h, gap, pad, 0f)
        }

        private fun drawRow(canvas: Canvas, keys: List<Key>, top: Float, h: Float, gap: Float, pad: Float, inset: Float) {
            val left = width * inset + pad
            val right = width * (1f - inset) - pad
            val totalGaps = gap * (keys.size - 1)
            val totalWeight = keys.sumOf { it.weight.toDouble() }.toFloat()
            val unit = (right - left - totalGaps) / totalWeight
            var x = left
            keys.forEach { key ->
                val keyWidth = unit * key.weight
                val rect = RectF(x, top, x + keyWidth, top + h)
                drawButton(canvas, key, rect, false)
                keyRects.add(key to rect)
                x += keyWidth + gap
            }
        }

        private fun drawButton(canvas: Canvas, key: Key, rect: RectF, toolbar: Boolean) {
            val isPressed = pressed == key
            if (isPressed) {
                canvas.save()
                canvas.scale(1.025f, 1.025f, rect.centerX(), rect.centerY())
            }
            val isAction = key.kind != Kind.CHARACTER &&
                key.kind != Kind.SUGGESTION &&
                key.kind != Kind.SPACE
            val color = when {
                isPressed -> Color.rgb(91, 103, 95)
                key.kind == Kind.ENTER || key.kind == Kind.MODE -> Color.rgb(82, 124, 76)
                isAction -> Color.rgb(53, 61, 57)
                else -> Color.rgb(68, 77, 72)
            }
            paint.color = color
            canvas.drawRoundRect(rect, 6f * density, 6f * density, paint)
            paint.color = Color.rgb(244, 246, 244)
            paint.textAlign = Paint.Align.CENTER
            paint.typeface = Typeface.create(if (key.label.length == 1 && key.label[0].isLetter()) "sans-serif" else "sans-serif", Typeface.NORMAL)
            val size = when {
                toolbar -> 12f
                key.label.length > 3 -> 12f
                key.label.length > 1 -> 17f
                else -> 21f
            } * density
            paint.textSize = size
            val labelY = if (key.hint.isNotEmpty()) rect.centerY() + 4f * density else rect.centerY() + size * .34f
            canvas.drawText(key.label, rect.centerX(), labelY, paint)
            if (key.hint.isNotEmpty()) {
                paint.textAlign = Paint.Align.RIGHT
                paint.color = Color.rgb(194, 206, 198)
                paint.textSize = 8f * density
                canvas.drawText(key.hint, rect.right - 4f * density, rect.bottom - 3f * density, paint)
            }
            if (isPressed) canvas.restore()
        }

        private fun drawPopup(canvas: Canvas) {
            if (!longPress) return
            val key = pressed ?: return
            val anchor = pressedRect ?: return
            val choices = key.alternatives.ifEmpty { listOf(key.output) }
            val itemW = 42f * density
            val popupW = itemW * choices.size
            val popupH = 54f * density
            val left = (anchor.centerX() - popupW / 2).coerceIn(4f * density, width - popupW - 4f * density)
            val top = max(4f * density, anchor.top - popupH - 5f * density)
            popupRect = RectF(left, top, left + popupW, top + popupH)
            paint.color = Color.rgb(34, 41, 37)
            canvas.drawRoundRect(popupRect, 9f * density, 9f * density, paint)
            choices.forEachIndexed { index, choice ->
                val item = RectF(left + itemW * index, top, left + itemW * (index + 1), top + popupH)
                if (index == popupIndex) {
                    paint.color = Color.rgb(82, 124, 76)
                    canvas.drawRoundRect(item, 7f * density, 7f * density, paint)
                }
                paint.color = Color.WHITE
                paint.textAlign = Paint.Align.CENTER
                paint.textSize = 18f * density
                canvas.drawText(choice, item.centerX(), item.centerY() + 6f * density, paint)
            }
        }

        private fun suggestions(): List<String> {
            if (passwordInput) return emptyList()
            val before = inputConnection()?.getTextBeforeCursor(80, 0)?.toString().orEmpty()
            val roman = composingRoman.lowercase()
            val word = Regex("[\\p{L}\\p{M}']+$").find(before)?.value.orEmpty()
            val source = if (mode == Mode.ENGLISH) englishWords else banglaWords
            val prefix = if (mode == Mode.PHONETIC) roman else word.lowercase()
            if (prefix.isEmpty()) return if (mode == Mode.ENGLISH) listOf("I", "you", "the") else listOf("আমি", "তুমি", "বাংলা")
            val matches = if (mode == Mode.PHONETIC) {
                phoneticWords.entries.filter { it.key.startsWith(prefix) }.map { it.value }
            } else {
                source.filter { it.lowercase().startsWith(prefix) }
            }
            val converted = if (mode == Mode.PHONETIC) Phonetic.convert(roman) else word
            return (matches + converted).distinct().filter { it.isNotBlank() }.take(3)
        }

        override fun onTouchEvent(event: MotionEvent): Boolean {
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    val hit = keyRects.lastOrNull { it.second.contains(event.x, event.y) } ?: return true
                    pressed = hit.first
                    pressedRect = hit.second
                    longPress = false
                    if (hit.first.alternatives.isNotEmpty()) handler.postDelayed(longPressTask, 360)
                    if (hit.first.kind == Kind.DELETE) handler.postDelayed(repeatTask, 420)
                    invalidate()
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    if (longPress) {
                        val key = pressed ?: return true
                        val itemWidth = 42f * density
                        popupIndex = ((event.x - popupRect.left) / itemWidth).toInt().coerceIn(key.alternatives.indices)
                        invalidate()
                    }
                    return true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    handler.removeCallbacks(longPressTask)
                    handler.removeCallbacks(repeatTask)
                    val key = pressed
                    if (event.actionMasked == MotionEvent.ACTION_UP && key != null) {
                        if (longPress) {
                            val choices = key.alternatives.ifEmpty { listOf(key.output) }
                            type(choices[popupIndex.coerceIn(choices.indices)])
                        } else if (key.kind != Kind.DELETE || (event.eventTime - event.downTime) < 420) {
                            activate(key)
                        }
                    }
                    pressed = null
                    pressedRect = null
                    longPress = false
                    invalidate()
                    return true
                }
            }
            return true
        }

        private fun activate(key: Key) {
            when (key.kind) {
                Kind.CHARACTER -> type(key.output)
                Kind.SUGGESTION -> insertSuggestion(key.output)
                Kind.SHIFT -> shifted = !shifted
                Kind.DELETE -> backspace()
                Kind.SPACE -> space()
                Kind.ENTER -> enter()
                Kind.MODE -> toggleMode()
                Kind.SYMBOLS -> symbols = true
                Kind.LETTERS -> symbols = false
                Kind.MIC -> startVoice()
                Kind.SETTINGS -> (this@BornoInputMethodService.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager)
                    .showInputMethodPicker()
            }
            invalidate()
        }
    }

    private object Phonetic {
        val words = mapOf(
            "ami" to "আমি", "tumi" to "তুমি", "apni" to "আপনি", "amra" to "আমরা",
            "oneek" to "অনেক", "onek" to "অনেক",
            "amar" to "আমার", "tomar" to "তোমার", "ki" to "কি", "kemon" to "কেমন",
            "kothay" to "কোথায়", "bhalo" to "ভালো", "valo" to "ভালো",
            "khub" to "খুব", "bangla" to "বাংলা",
            "bangladesh" to "বাংলাদেশ", "bhai" to "ভাই", "bon" to "বোন",
            "bondhu" to "বন্ধু", "dhonnobad" to "ধন্যবাদ", "ha" to "হ্যাঁ",
            "na" to "না", "hobe" to "হবে", "kore" to "করে", "koro" to "করো",
            "korbo" to "করব", "korben" to "করবেন", "korchen" to "করছেন",
            "ache" to "আছে", "achhi" to "আছি", "achen" to "আছেন",
            "sundor" to "সুন্দর", "shundor" to "সুন্দর", "basha" to "বাসা",
            "bari" to "বাড়ি", "ma" to "মা", "baba" to "বাবা",
            "assalamualaikum" to "আসসালামু আলাইকুম", "inshaallah" to "ইনশাআল্লাহ",
            "alhamdulillah" to "আলহামদুলিল্লাহ", "shuvo" to "শুভ", "sokal" to "সকাল",
            "aj" to "আজ", "kal" to "কাল", "kotha" to "কথা", "likho" to "লিখো",
            "likhun" to "লিখুন", "kaj" to "কাজ", "pani" to "পানি", "khabar" to "খাবার",
            "school" to "স্কুল", "office" to "অফিস", "bhalobashi" to "ভালোবাসি",
            "bhalobasha" to "ভালোবাসা", "prithibi" to "পৃথিবী", "shotti" to "সত্যি",
            "kivabe" to "কিভাবে", "kibhabe" to "কীভাবে", "dhaka" to "ঢাকা",
            "choto" to "ছোট", "boro" to "বড়", "mon" to "মন", "thanks" to "ধন্যবাদ",
            "apnara" to "আপনারা", "amake" to "আমাকে", "tomake" to "তোমাকে",
            "apnake" to "আপনাকে", "tader" to "তাদের", "ekhane" to "এখানে",
            "sekhane" to "সেখানে", "okhane" to "ওখানে", "ekhon" to "এখন",
            "tokhon" to "তখন", "kobe" to "কবে", "koto" to "কত",
            "karon" to "কারণ", "jodi" to "যদি", "tahole" to "তাহলে",
            "kintu" to "কিন্তু", "abar" to "আবার", "pore" to "পরে",
            "age" to "আগে", "shob" to "সব", "sobai" to "সবাই",
            "hoyeche" to "হয়েছে", "bolen" to "বলেন", "bolun" to "বলুন",
            "bolo" to "বলো", "bolchi" to "বলছি", "dekhi" to "দেখি",
            "dekho" to "দেখো", "dekhen" to "দেখেন", "jabo" to "যাব",
            "asbo" to "আসব", "jacchi" to "যাচ্ছি", "gechi" to "গেছি",
            "parbo" to "পারব", "pari" to "পারি", "dorkar" to "দরকার",
            "lagbe" to "লাগবে", "somoy" to "সময়", "ajke" to "আজকে",
            "kalke" to "কালকে", "khabo" to "খাব", "khushi" to "খুশি",
            "moja" to "মজা", "darun" to "দারুণ", "thik" to "ঠিক",
            "bujhi" to "বুঝি", "bujhte" to "বুঝতে", "bujhlam" to "বুঝলাম",
            "nam" to "নাম", "desh" to "দেশ", "priyo" to "প্রিয়",
            "poribar" to "পরিবার", "chhele" to "ছেলে", "meye" to "মেয়ে",
            "shuru" to "শুরু", "shesh" to "শেষ", "protidin" to "প্রতিদিন",
        )
        private data class Token(val text: String, val consonant: Boolean = false, val sign: String = "")
        private val tokens = mutableMapOf<String, Token>().apply {
            val consonants = mapOf(
                "kkh" to "ক্ষ", "ksh" to "ক্ষ", "str" to "স্ত্র", "ndh" to "ন্ধ",
                "shr" to "শ্র", "gy" to "জ্ঞ", "nd" to "ন্দ", "nt" to "ন্ত",
                "kk" to "ক্ক", "tt" to "ত্ত", "ll" to "ল্ল", "nn" to "ন্ন",
                "chh" to "ছ", "kh" to "খ", "gh" to "ঘ", "ch" to "চ",
                "jh" to "ঝ", "th" to "থ", "dh" to "ধ", "ph" to "ফ",
                "bh" to "ভ", "sh" to "শ", "ng" to "ং",
                "k" to "ক", "g" to "গ", "c" to "চ", "j" to "জ",
                "T" to "ট", "t" to "ত", "D" to "ড", "d" to "দ",
                "N" to "ণ", "n" to "ন", "p" to "প", "f" to "ফ",
                "b" to "ব", "v" to "ভ", "m" to "ম", "z" to "য",
                "r" to "র", "l" to "ল", "s" to "স", "h" to "হ",
                "q" to "ক", "w" to "ৱ", "x" to "ক্স", "y" to "য়",
            )
            consonants.forEach { (key, value) -> put(key.lowercase(), Token(value, consonant = true)) }
            val vowels = mapOf(
                "aa" to ("আ" to "া"), "ii" to ("ঈ" to "ী"), "uu" to ("ঊ" to "ূ"),
                "oi" to ("ঐ" to "ৈ"), "ou" to ("ঔ" to "ৌ"), "a" to ("আ" to "া"),
                "i" to ("ই" to "ি"), "u" to ("উ" to "ু"), "e" to ("এ" to "ে"),
                "o" to ("ও" to "ো"),
            )
            vowels.forEach { (key, value) -> put(key, Token(value.first, sign = value.second)) }
            put("ng", Token("ং"))
        }
        fun convert(input: String): String {
            if (input.isEmpty()) return ""
            words[input.lowercase()]?.let { return it }
            val result = StringBuilder()
            var i = 0
            val ordered = tokens.keys.sortedByDescending { it.length }
            var previousWasConsonant = false
            while (i < input.length) {
                val token = ordered.firstOrNull { input.startsWith(it, i, ignoreCase = true) }
                if (token == null) {
                    result.append(input[i])
                    previousWasConsonant = false
                    i++
                } else {
                    val value = tokens.getValue(token)
                    val atEnd = i + token.length >= input.length
                    when {
                        value.consonant -> {
                            result.append(value.text)
                            previousWasConsonant = true
                        }
                        value.sign.isNotEmpty() -> {
                            if (previousWasConsonant) result.append(value.sign)
                            else result.append(value.text)
                            previousWasConsonant = false
                        }
                        token == "o" -> {
                            if (previousWasConsonant && atEnd) result.append("ো")
                            else if (!previousWasConsonant) result.append("ও")
                            previousWasConsonant = false
                        }
                        else -> {
                            result.append(value.text)
                            previousWasConsonant = false
                        }
                    }
                    i += token.length
                }
            }
            return result.toString()
        }
    }

    companion object {
        private val phoneticWords = Phonetic.words
        private val banglaWords = listOf(
            "আমি","আমার","আমরা","আপনি","আপনার","আছে","আছি","আছেন","আজ","আসসালামু আলাইকুম",
            "ইনশাআল্লাহ","একটি","কথা","করতে","করেন","করছি","করছেন","কেমন","কিভাবে","কীভাবে",
            "খুব","খাবার","গান","চাই","ছোট","জানি","তুমি","তোমার","দেখুন","ধন্যবাদ","নতুন",
            "না","অনেক","পারি","পানি","বাংলা","বাংলাদেশ","ভাই","ভালো","ভালোবাসা","ভালোবাসি",
            "মা","মানুষ","যাব","যাচ্ছি","যেমন","রয়েছে","লিখুন","শুভ সকাল","সুন্দর","হ্যাঁ",
            "আমাকে","তোমাকে","আপনাকে","এখানে","সেখানে","এখন","কবে","কত","কারণ","যদি",
            "তাহলে","কিন্তু","আবার","পরে","আগে","সব","সবাই","হয়েছে","বলেন","বলুন",
            "দেখি","দেখো","দেখেন","আসব","পারব","দরকার","সময়","আজকে","কালকে","খুশি",
            "মজা","দারুণ","ঠিক","বুঝি","বুঝতে","বুঝলাম","নাম","দেশ","প্রিয়","পরিবার",
            "ছেলে","মেয়ে","শুরু","শেষ","প্রতিদিন","ফোন","মেসেজ","কীবোর্ড","বন্ধু","শুভ রাত্রি"
        )
        private val englishWords = listOf(
            "I","you","the","and","is","it","we","this","that","hello","thanks","please","love","good","great","Bangla"
        )
    }
}

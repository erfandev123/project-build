package com.erfandev.bongo_board

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.animation.DecelerateInterpolator
import android.view.animation.OvershootInterpolator
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.ExtractedTextRequest
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputMethodManager
import java.text.BreakIterator
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class BornoInputMethodService : InputMethodService() {
    private enum class Mode { PHONETIC, BANGLA, ENGLISH }
    private enum class Kind {
        CHARACTER, SUGGESTION, SHIFT, DELETE, SPACE, ENTER, MODE, SYMBOLS, LETTERS, MIC, SETTINGS
    }
    private enum class PopupMode { NONE, CHOICES, PREVIEW }

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
        keyboard?.invalidateSuggestions()
        keyboard?.invalidate()
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        keyboard?.invalidateSuggestions()
        keyboard?.invalidate()
    }

    override fun onUpdateSelection(
        oldSelStart: Int,
        oldSelEnd: Int,
        newSelStart: Int,
        newSelEnd: Int,
        candidatesStart: Int,
        candidatesEnd: Int,
    ) {
        super.onUpdateSelection(
            oldSelStart,
            oldSelEnd,
            newSelStart,
            newSelEnd,
            candidatesStart,
            candidatesEnd,
        )
        keyboard?.invalidateSuggestions()
    }

    override fun onFinishInput() {
        finishComposing()
        stopVoice()
        keyboard?.invalidateSuggestions()
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
        keyboard?.invalidateSuggestions()
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
        keyboard?.invalidateSuggestions()
    }

    private fun backspace() {
        val connection = inputConnection() ?: return
        if (composingRoman.isNotEmpty()) {
            composingRoman = composingRoman.dropLast(1)
            if (composingRoman.isEmpty()) connection.setComposingText("", 0)
            else connection.setComposingText(Phonetic.convert(composingRoman), 1)
        } else {
            val before = connection.getTextBeforeCursor(16, 0)?.toString().orEmpty()
            if (before.isNotEmpty()) {
                val boundary = BreakIterator.getCharacterInstance()
                boundary.setText(before)
                boundary.last()
                val start = boundary.previous()
                val count = (before.length - start).coerceAtLeast(1)
                connection.deleteSurroundingText(count, 0)
            }
        }
        keyboard?.invalidateSuggestions()
        keyboard?.invalidate()
    }

    private fun space() {
        finishComposing()
        inputConnection()?.commitText(" ", 1)
        shifted = false
        keyboard?.invalidateSuggestions()
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
        keyboard?.invalidateSuggestions()
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
        keyboard?.invalidateSuggestions()
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
        keyboard?.invalidateSuggestions()
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
            override fun onReadyForSpeech(params: android.os.Bundle?) {
                voiceStatus = "শুনছি… কথা বলুন"
                keyboard?.invalidate()
            }

            override fun onBeginningOfSpeech() {
                voiceStatus = "শুনছি…"
                keyboard?.invalidate()
            }

            override fun onRmsChanged(rmsdB: Float) {}

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                voiceStatus = "লিখছি…"
                keyboard?.invalidate()
            }

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
                    keyboard?.invalidateSuggestions()
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
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG)
        private val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val handler = Handler(Looper.getMainLooper())
        private val keyRects = mutableListOf<Pair<Key, RectF>>()
        private val scratchRect = RectF()
        private val innerRect = RectF()
        private val shadowRect = RectF()

        private val keyTypeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        private val hintTypeface = Typeface.create("sans-serif", Typeface.NORMAL)

        private val backgroundTop = Color.rgb(18, 27, 22)
        private val backgroundBottom = Color.rgb(7, 12, 9)
        private val textColor = Color.rgb(247, 244, 234)
        private val actionTextColor = Color.rgb(232, 231, 222)
        private val mutedTextColor = Color.rgb(174, 198, 182)
        private val hintColor = Color.rgb(154, 179, 161)
        private val accentColor = Color.rgb(206, 250, 109)
        private val onAccentColor = Color.rgb(11, 21, 14)

        private var pressed: Key? = null
        private var pressedRect: RectF? = null
        private var longPress = false
        private var popupMode = PopupMode.NONE
        private var popupIndex = 0
        private var popupRect = RectF()
        private var popupProgress = 0f
        private var pressAmount = 0f
        private var pressToken = 0
        private var pressAnimator: android.animation.ValueAnimator? = null
        private var popupAnimator: android.animation.ValueAnimator? = null

        private var downX = 0f
        private var downY = 0f
        private var downTime = 0L
        private var deleteRepeated = false
        private var pressCancelled = false

        private var deleteSwipeActive = false
        private var deleteExtracted = false
        private var deleteCursor = -1
        private var deleteTextBefore = ""
        private var deleteBoundaries = emptyList<Int>()
        private var deleteSelectedCount = 0
        private var deleteLastStep = -1

        private var suggestionDirty = true
        private var suggestionCache: List<String> = emptyList()
        private var rowsCache: List<List<Key>>? = null
        private var rowsCacheKey = ""

        private val longPressTask = Runnable {
            val key = pressed ?: return@Runnable
            if (deleteSwipeActive) return@Runnable
            when {
                key.alternatives.isNotEmpty() -> {
                    popupMode = PopupMode.CHOICES
                    popupIndex = 0
                    longPress = true
                    showPopup()
                }
                key.kind == Kind.CHARACTER -> {
                    popupMode = PopupMode.PREVIEW
                    popupIndex = 0
                    longPress = true
                    showPopup()
                }
            }
        }

        private val repeatTask = object : Runnable {
            override fun run() {
                if (pressed?.kind == Kind.DELETE && !deleteSwipeActive) {
                    deleteRepeated = true
                    backspace()
                    handler.postDelayed(this, 64)
                }
            }
        }

        init {
            isFocusable = false
            isClickable = true
            setLayerType(LAYER_TYPE_HARDWARE, null)
            contentDescription = "Borno Bangla keyboard"
        }

        fun invalidateSuggestions() {
            suggestionDirty = true
            if (pressed == null) invalidate()
        }

        override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
            super.onSizeChanged(w, h, oldw, oldh)
            backgroundPaint.shader = LinearGradient(
                0f,
                0f,
                0f,
                h.toFloat().coerceAtLeast(1f),
                backgroundTop,
                backgroundBottom,
                Shader.TileMode.CLAMP,
            )
        }

        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            val desired = (286 * density).toInt()
            val height = resolveSize(desired, heightMeasureSpec)
            setMeasuredDimension(MeasureSpec.getSize(widthMeasureSpec), height)
        }

        override fun onDetachedFromWindow() {
            pressAnimator?.cancel()
            popupAnimator?.cancel()
            handler.removeCallbacksAndMessages(null)
            super.onDetachedFromWindow()
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            keyRects.clear()
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), backgroundPaint)

            val pad = 5f * density
            val gap = 5f * density
            val toolbarTop = 4f * density
            val toolbarH = 34f * density
            val suggestionTop = toolbarTop + toolbarH + 4f * density
            val suggestionH = 32f * density
            val rowsTop = suggestionTop + suggestionH + 5f * density
            val bottomH = 45f * density
            val bottomTop = height - 5f * density - bottomH

            drawToolbar(canvas, pad, toolbarTop, toolbarH)
            drawSuggestions(canvas, pad, suggestionTop, suggestionH, gap)
            drawSoftDivider(canvas, rowsTop - 3f * density, pad)

            val available = bottomTop - rowsTop - 2f * gap
            val rowH = (available / 3f).coerceIn(40f * density, 54f * density)
            val rows = rows()
            rows.forEachIndexed { index, row ->
                val inset = if (index == 1) 0.035f else 0f
                drawRow(
                    canvas,
                    row,
                    rowsTop + index * (rowH + gap),
                    rowH,
                    gap,
                    pad,
                    inset,
                )
            }
            drawBottom(canvas, bottomTop, bottomH, gap, pad)
            drawDeleteBadge(canvas)
            drawPopup(canvas)
        }

        private fun drawSoftDivider(canvas: Canvas, y: Float, pad: Float) {
            paint.style = Paint.Style.FILL
            paint.shader = null
            paint.color = Color.argb(16, 255, 255, 255)
            canvas.drawRoundRect(
                RectF(pad, y, width - pad, y + 0.7f * density),
                1f * density,
                1f * density,
                paint,
            )
        }

        private fun drawToolbar(canvas: Canvas, pad: Float, top: Float, h: Float) {
            val modeLabel = when (mode) {
                Mode.PHONETIC -> "ফোনেটিক"
                Mode.BANGLA -> "বাংলা"
                Mode.ENGLISH -> "English"
            }
            val modeKey = Key(modeLabel, kind = Kind.MODE)
            val micKey = Key("🎙", kind = Kind.MIC)
            val settingsKey = Key("⚙", kind = Kind.SETTINGS)
            val modeRect = RectF(pad, top, width * 0.37f, top + h)
            val micRect = RectF(width * 0.43f, top, width * 0.56f, top + h)
            val settingsRect = RectF(width - pad - 40f * density, top, width - pad, top + h)
            drawKey(canvas, modeKey, modeRect, small = true)
            drawKey(canvas, micKey, micRect, small = true)
            drawKey(canvas, settingsKey, settingsRect, small = true)
            keyRects.add(modeKey to modeRect)
            keyRects.add(micKey to micRect)
            keyRects.add(settingsKey to settingsRect)
        }

        private fun drawSuggestions(canvas: Canvas, pad: Float, top: Float, h: Float, gap: Float) {
            if (voiceStatus.isNotEmpty()) {
                paint.style = Paint.Style.FILL
                paint.shader = null
                paint.color = Color.rgb(190, 226, 162)
                paint.typeface = keyTypeface
                paint.textSize = 12.5f * density
                paint.textAlign = Paint.Align.CENTER
                drawTextCentered(canvas, voiceStatus.take(46), width / 2f, top + h / 2f)
                return
            }
            if (suggestionDirty) {
                suggestionCache = computeSuggestions()
                suggestionDirty = false
            }
            val values = suggestionCache
            if (values.isEmpty()) return
            val left = pad
            val right = width - pad
            val cell = (right - left - gap * (values.size - 1)) / values.size
            values.forEachIndexed { index, value ->
                val rect = RectF(
                    left + index * (cell + gap),
                    top,
                    left + index * (cell + gap) + cell,
                    top + h,
                )
                val key = Key(value, output = value, kind = Kind.SUGGESTION)
                drawKey(canvas, key, rect, small = true)
                keyRects.add(key to rect)
            }
        }

        private fun rows(): List<List<Key>> {
            val cacheKey = "${mode.ordinal}-$shifted-$symbols"
            if (rowsCache != null && rowsCacheKey == cacheKey) return rowsCache!!
            val built: List<List<Key>> = when {
                symbols -> listOf(
                    listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0").map { Key(it) },
                    listOf("@", "#", "$", "%", "&", "-", "+", "(", ")").map {
                        Key(it, alternatives = listOf(it, "№", "‰"))
                    },
                    listOf(Key("=\\<", kind = Kind.LETTERS, weight = 1.5f)) +
                        listOf("!", "\"", "'", ":", ";", "/", "?").map { Key(it) } +
                        Key("⌫", kind = Kind.DELETE, weight = 1.5f),
                )
                mode == Mode.BANGLA -> {
                    val first = listOf("দ", "ূ", "ী", "র", "ট", "এ", "ু", "ি", "ও", "প", "ে", "ো")
                    val second = listOf("া", "স", "ড", "ত", "গ", "হ", "জ", "ক", "ল")
                    val third = listOf("য়", "শ", "চ", "আ", "ব", "ন", "ম", "ৃ", "্")
                    val firstAlt = listOf("ধ", "ঊ", "ঈ", "ড়", "ঠ", "ঐ", "উ", "ই", "ঔ", "ফ", "ৈ", "ৌ")
                    val secondAlt = listOf("অ", "ষ", "ঢ", "থ", "ঘ", "ঃ", "ঝ", "খ", "ং")
                    val thirdAlt = listOf("য", "ঢ়", "ছ", "ঋ", "ভ", "ণ", "ঙ", "ৃ", "ঁ")
                    listOf(
                        first.mapIndexed { index, value ->
                            val primary = if (shifted) firstAlt[index] else value
                            Key(
                                primary,
                                hint = if (shifted) value else firstAlt[index],
                                alternatives = listOf(primary, if (shifted) value else firstAlt[index]),
                            )
                        },
                        second.mapIndexed { index, value ->
                            val primary = if (shifted) secondAlt[index] else value
                            Key(
                                primary,
                                hint = if (shifted) value else secondAlt[index],
                                alternatives = listOf(primary, if (shifted) value else secondAlt[index]),
                            )
                        },
                        listOf(Key("⇧", kind = Kind.SHIFT, weight = 1.4f)) +
                            third.mapIndexed { index, value ->
                                val primary = if (shifted) thirdAlt[index] else value
                                Key(
                                    primary,
                                    hint = if (shifted) value else thirdAlt[index],
                                    alternatives = listOf(primary, if (shifted) value else thirdAlt[index]),
                                )
                            } +
                            Key("⌫", kind = Kind.DELETE, weight = 1.4f),
                    )
                }
                else -> {
                    val phoneticHints = listOf(
                        listOf("ক", "ৱ", "এ", "র", "ত", "য়", "উ", "ই", "অ", "প"),
                        listOf("আ", "স", "দ", "ফ", "গ", "হ", "জ", "ক", "ল"),
                        listOf("য", "ক্স", "চ", "ভ", "ব", "ন", "ম"),
                    )
                    val first = "qwertyuiop".mapIndexed { index, character ->
                        val label = if (shifted) character.uppercase() else character.toString()
                        val hint = if (mode == Mode.PHONETIC) phoneticHints[0][index] else ""
                        Key(
                            label,
                            output = label,
                            hint = hint,
                            alternatives = if (mode == Mode.PHONETIC) listOf(label, hint) else emptyList(),
                        )
                    }
                    val second = "asdfghjkl".mapIndexed { index, character ->
                        val label = if (shifted) character.uppercase() else character.toString()
                        val hint = if (mode == Mode.PHONETIC) phoneticHints[1][index] else ""
                        Key(
                            label,
                            output = label,
                            hint = hint,
                            alternatives = if (mode == Mode.PHONETIC) listOf(label, hint) else emptyList(),
                        )
                    }
                    val third = "zxcvbnm".mapIndexed { index, character ->
                        val label = if (shifted) character.uppercase() else character.toString()
                        val hint = if (mode == Mode.PHONETIC) phoneticHints[2][index] else ""
                        Key(
                            label,
                            output = label,
                            hint = hint,
                            alternatives = if (mode == Mode.PHONETIC) listOf(label, hint) else emptyList(),
                        )
                    }
                    listOf(
                        first,
                        second,
                        listOf(Key("⇧", kind = Kind.SHIFT, weight = 1.4f)) +
                            third +
                            Key("⌫", kind = Kind.DELETE, weight = 1.4f),
                    )
                }
            }
            rowsCache = built
            rowsCacheKey = cacheKey
            return built
        }

        private fun drawBottom(canvas: Canvas, top: Float, h: Float, gap: Float, pad: Float) {
            val keys = listOf(
                Key(
                    if (symbols) "ABC" else "?123",
                    kind = if (symbols) Kind.LETTERS else Kind.SYMBOLS,
                    weight = 1.8f,
                ),
                Key("🌐", kind = Kind.MODE, weight = 1.3f),
                Key("স্পেস", kind = Kind.SPACE, weight = 5.2f),
                Key("।", output = "।", alternatives = listOf("।", "."), weight = 1.3f),
                Key("↵", kind = Kind.ENTER, weight = 1.8f),
            )
            drawRow(canvas, keys, top, h, gap, pad, 0f)
        }

        private fun drawRow(
            canvas: Canvas,
            keys: List<Key>,
            top: Float,
            h: Float,
            gap: Float,
            pad: Float,
            inset: Float,
        ) {
            val left = width * inset + pad
            val right = width * (1f - inset) - pad
            val totalGaps = gap * (keys.size - 1)
            val totalWeight = keys.sumOf { it.weight.toDouble() }.toFloat()
            val unit = (right - left - totalGaps) / totalWeight
            var x = left
            keys.forEach { key ->
                val keyWidth = unit * key.weight
                val rect = RectF(x, top, x + keyWidth, top + h)
                drawKey(canvas, key, rect, small = false)
                keyRects.add(key to rect)
                x += keyWidth + gap
            }
        }

        private fun drawKey(canvas: Canvas, key: Key, rect: RectF, small: Boolean) {
            val press = if (pressed == key) pressAmount else 0f
            if (press > 0.001f) {
                canvas.save()
                val scale = 1f + 0.055f * press
                canvas.scale(scale, scale, rect.centerX(), rect.centerY())
            }

            val action = key.kind != Kind.CHARACTER &&
                key.kind != Kind.SUGGESTION &&
                key.kind != Kind.SPACE
            val accentKey = key.kind == Kind.ENTER
            val selected = key.kind == Kind.SHIFT && shifted
            val swiping = key.kind == Kind.DELETE && deleteSwipeActive

            val outerBase: Int
            val innerBase: Int
            val innerPressed: Int
            val foreground: Int
            when {
                accentKey -> {
                    outerBase = Color.rgb(137, 174, 70)
                    innerBase = accentColor
                    innerPressed = Color.rgb(222, 255, 155)
                    foreground = onAccentColor
                }
                action -> {
                    outerBase = Color.rgb(16, 25, 20)
                    innerBase = Color.rgb(27, 39, 32)
                    innerPressed = Color.rgb(43, 60, 49)
                    foreground = actionTextColor
                }
                small -> {
                    outerBase = Color.rgb(17, 26, 21)
                    innerBase = Color.rgb(28, 42, 34)
                    innerPressed = Color.rgb(43, 60, 49)
                    foreground = Color.rgb(217, 229, 222)
                }
                else -> {
                    outerBase = Color.rgb(25, 36, 29)
                    innerBase = Color.rgb(41, 56, 47)
                    innerPressed = Color.rgb(59, 81, 66)
                    foreground = textColor
                }
            }

            val outerPressed = mix(outerBase, Color.rgb(62, 82, 68), 0.9f)
            val outerFill = mix(outerBase, outerPressed, press)
            var innerFill = mix(innerBase, innerPressed, press)
            if (swiping) innerFill = mix(innerFill, accentColor, 0.10f)
            if (selected) innerFill = mix(innerFill, accentColor, 0.14f)

            val radius = if (small) 8.5f * density else 10.5f * density
            val innerInset = if (small) 2.2f * density else 3.2f * density
            val innerRadius = max(4f * density, radius - 2.6f * density)

            paint.shader = null
            paint.style = Paint.Style.FILL
            if (press < 0.55f) {
                shadowRect.set(rect.left, rect.top + 1.4f * density, rect.right, rect.bottom + 1.4f * density)
                paint.color = Color.argb(if (small) 26 else 48, 0, 0, 0)
                canvas.drawRoundRect(shadowRect, radius, radius, paint)
            }

            paint.color = outerFill
            canvas.drawRoundRect(rect, radius, radius, paint)

            innerRect.set(
                rect.left + innerInset,
                rect.top + innerInset,
                rect.right - innerInset,
                rect.bottom - innerInset,
            )
            paint.color = innerFill
            canvas.drawRoundRect(innerRect, innerRadius, innerRadius, paint)

            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 0.9f * density
            paint.color = when {
                swiping || selected -> Color.argb(190, 206, 250, 109)
                accentKey -> Color.argb(70, 11, 21, 14)
                else -> Color.argb(if (small) 12 else 20, 255, 255, 255)
            }
            canvas.drawRoundRect(innerRect, innerRadius, innerRadius, paint)

            if (press > 0.01f) {
                paint.strokeWidth = 1.3f * density
                paint.color = if (accentKey) {
                    Color.argb((70 * press).toInt(), 255, 255, 255)
                } else {
                    Color.argb((44 * press).toInt(), 206, 250, 109)
                }
                canvas.drawRoundRect(rect, radius, radius, paint)
            }

            paint.style = Paint.Style.FILL
            paint.typeface = keyTypeface
            paint.textAlign = Paint.Align.CENTER
            paint.color = when {
                swiping -> mix(foreground, accentColor, 0.7f)
                selected -> accentColor
                else -> foreground
            }
            val isLatin = key.label.length == 1 && key.label[0].code < 128
            val labelSize = when {
                small -> if (key.label.length > 2) 11f else 12.5f
                key.label.length > 4 -> 11.5f
                key.label.length > 2 -> 14.5f
                key.label.length > 1 -> 16.5f
                else -> if (isLatin) 20f else 21f
            }
            paint.textSize = labelSize * density
            val availableWidth = innerRect.width() - 10f * density
            val measured = paint.measureText(key.label)
            if (measured > availableWidth && availableWidth > 1f) {
                paint.textSize = (labelSize * (availableWidth / measured)).coerceAtLeast(7.5f) * density
            }
            val labelCenterY = innerRect.centerY() + if (key.hint.isNotEmpty()) 3f * density else 0f
            drawTextCentered(canvas, key.label, innerRect.centerX(), labelCenterY)

            if (key.hint.isNotEmpty()) {
                paint.typeface = hintTypeface
                paint.textAlign = Paint.Align.RIGHT
                paint.textSize = 8.5f * density
                paint.color = if (accentKey) {
                    Color.argb(175, 11, 21, 14)
                } else if (selected) {
                    accentColor
                } else {
                    hintColor
                }
                canvas.drawText(
                    key.hint,
                    innerRect.right - 5f * density,
                    innerRect.top + 4.5f * density - paint.fontMetrics.ascent,
                    paint,
                )
            }

            if (press > 0.001f) canvas.restore()
        }

        private fun drawTextCentered(canvas: Canvas, text: String, centerX: Float, centerY: Float) {
            val metrics = paint.fontMetrics
            canvas.drawText(text, centerX, centerY - (metrics.ascent + metrics.descent) / 2f, paint)
        }

        private fun drawPopup(canvas: Canvas) {
            if (popupMode == PopupMode.NONE) return
            val key = pressed ?: return
            val anchor = pressedRect ?: return
            if (popupProgress <= 0f) return

            val choices = key.alternatives.ifEmpty { listOf(key.output) }
            val isChoices = popupMode == PopupMode.CHOICES
            val tileW = 46f * density
            val popupH = 58f * density
            val popupW = if (isChoices) {
                choices.size * tileW + 8f * density
            } else {
                max(58f * density, min(78f * density, anchor.width() * 1.25f))
            }
            val maxLeft = max(4f * density, width - popupW - 4f * density)
            val left = (anchor.centerX() - popupW / 2f).coerceIn(4f * density, maxLeft)
            val preferredTop = anchor.top - popupH - 9f * density
            val top = if (preferredTop >= 4f * density) {
                preferredTop
            } else {
                min(height - popupH - 4f * density, anchor.bottom + 9f * density)
            }
            popupRect.set(left, top, left + popupW, top + popupH)

            canvas.save()
            val scale = 0.92f + 0.08f * popupProgress
            canvas.scale(scale, scale, anchor.centerX(), top + popupH)

            shadowRect.set(
                popupRect.left + 1f * density,
                popupRect.top + 4f * density,
                popupRect.right + 1f * density,
                popupRect.bottom + 4f * density,
            )
            paint.style = Paint.Style.FILL
            paint.shader = null
            paint.color = Color.argb(90, 0, 0, 0)
            canvas.drawRoundRect(shadowRect, 14f * density, 14f * density, paint)

            paint.color = Color.rgb(25, 36, 29)
            canvas.drawRoundRect(popupRect, 13f * density, 13f * density, paint)
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 1f * density
            paint.color = Color.argb(115, 206, 250, 109)
            canvas.drawRoundRect(popupRect, 13f * density, 13f * density, paint)

            if (isChoices) {
                val contentLeft = popupRect.left + 4f * density
                val contentTop = popupRect.top + 4f * density
                val contentBottom = popupRect.bottom - 4f * density
                choices.forEachIndexed { index, choice ->
                    val item = RectF(
                        contentLeft + index * tileW,
                        contentTop,
                        contentLeft + (index + 1) * tileW,
                        contentBottom,
                    )
                    if (index == popupIndex) {
                        paint.style = Paint.Style.FILL
                        paint.color = accentColor
                        canvas.drawRoundRect(
                            item.left + 1.5f * density,
                            item.top,
                            item.right - 1.5f * density,
                            item.bottom,
                            9f * density,
                            9f * density,
                            paint,
                        )
                    }
                    paint.style = Paint.Style.FILL
                    paint.typeface = keyTypeface
                    paint.textAlign = Paint.Align.CENTER
                    paint.textSize = 19f * density
                    paint.color = if (index == popupIndex) onAccentColor else textColor
                    drawTextCentered(canvas, choice, item.centerX(), item.centerY())
                }
            } else {
                val inner = RectF(
                    popupRect.left + 4f * density,
                    popupRect.top + 4f * density,
                    popupRect.right - 4f * density,
                    popupRect.bottom - 4f * density,
                )
                paint.style = Paint.Style.FILL
                paint.color = mix(Color.rgb(44, 60, 50), accentColor, 0.10f)
                canvas.drawRoundRect(inner, 10f * density, 10f * density, paint)
                paint.style = Paint.Style.STROKE
                paint.strokeWidth = 1f * density
                paint.color = Color.argb(80, 255, 255, 255)
                canvas.drawRoundRect(inner, 10f * density, 10f * density, paint)
                paint.style = Paint.Style.FILL
                paint.typeface = keyTypeface
                paint.textAlign = Paint.Align.CENTER
                paint.textSize = 27f * density
                paint.color = textColor
                drawTextCentered(canvas, key.label, inner.centerX(), inner.centerY())
                if (key.hint.isNotEmpty()) {
                    paint.typeface = hintTypeface
                    paint.textAlign = Paint.Align.RIGHT
                    paint.textSize = 9f * density
                    paint.color = hintColor
                    canvas.drawText(
                        key.hint,
                        inner.right - 6f * density,
                        inner.top + 5f * density - paint.fontMetrics.ascent,
                        paint,
                    )
                }
            }
            canvas.restore()
        }

        private fun drawDeleteBadge(canvas: Canvas) {
            if (!deleteSwipeActive || deleteSelectedCount <= 0) return
            val rect = keyRects.lastOrNull { it.first.kind == Kind.DELETE }?.second ?: return
            val text = "$deleteSelectedCount অক্ষর"
            paint.style = Paint.Style.FILL
            paint.shader = null
            paint.typeface = keyTypeface
            paint.textSize = 10.5f * density
            paint.textAlign = Paint.Align.CENTER
            val textWidth = paint.measureText(text)
            val badgeW = textWidth + 24f * density
            val badgeH = 26f * density
            val left = (rect.centerX() - badgeW / 2f).coerceIn(4f * density, width - badgeW - 4f * density)
            val top = max(4f * density, rect.top - badgeH - 7f * density)
            val badge = RectF(left, top, left + badgeW, top + badgeH)
            shadowRect.set(badge.left, badge.top + 2f * density, badge.right, badge.bottom + 2f * density)
            paint.color = Color.argb(70, 0, 0, 0)
            canvas.drawRoundRect(shadowRect, 10f * density, 10f * density, paint)
            paint.color = Color.rgb(31, 45, 36)
            canvas.drawRoundRect(badge, 10f * density, 10f * density, paint)
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 1f * density
            paint.color = Color.argb(140, 206, 250, 109)
            canvas.drawRoundRect(badge, 10f * density, 10f * density, paint)
            paint.style = Paint.Style.FILL
            paint.color = accentColor
            drawTextCentered(canvas, text, badge.centerX(), badge.centerY())
        }

        private fun showPopup() {
            popupAnimator?.cancel()
            popupProgress = 0f
            popupAnimator = android.animation.ValueAnimator.ofFloat(0f, 1f).apply {
                duration = 95L
                interpolator = DecelerateInterpolator()
                addUpdateListener {
                    popupProgress = it.animatedValue as Float
                    invalidate()
                }
                start()
            }
        }

        private fun hidePopup() {
            popupAnimator?.cancel()
            popupAnimator = null
            popupProgress = 0f
            popupMode = PopupMode.NONE
            longPress = false
        }

        private fun animatePress() {
            pressAnimator?.cancel()
            val token = ++pressToken
            pressAmount = 0f
            pressAnimator = android.animation.ValueAnimator.ofFloat(0f, 1f).apply {
                duration = 70L
                interpolator = DecelerateInterpolator()
                addUpdateListener {
                    if (token == pressToken) {
                        pressAmount = it.animatedValue as Float
                        invalidate()
                    }
                }
                start()
            }
        }

        private fun releasePress() {
            pressAnimator?.cancel()
            val token = ++pressToken
            val start = pressAmount
            pressAnimator = android.animation.ValueAnimator.ofFloat(start, 0f).apply {
                duration = 150L
                interpolator = OvershootInterpolator(1.35f)
                addUpdateListener {
                    if (token == pressToken) {
                        pressAmount = it.animatedValue as Float
                        invalidate()
                    }
                }
                addListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) {
                        if (token == pressToken && pressAmount <= 0.001f) {
                            pressed = null
                            pressedRect = null
                            invalidate()
                        }
                    }
                })
                start()
            }
        }

        private fun pressHaptic() {
            performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
        }

        override fun onTouchEvent(event: MotionEvent): Boolean {
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    val hit = keyRects.lastOrNull { it.second.contains(event.x, event.y) } ?: return true
                    pressed = hit.first
                    pressedRect = hit.second
                    downX = event.x
                    downY = event.y
                    downTime = event.eventTime
                    longPress = false
                    popupMode = PopupMode.NONE
                    popupProgress = 0f
                    deleteRepeated = false
                    pressCancelled = false
                    deleteSwipeActive = false
                    deleteSelectedCount = 0
                    deleteLastStep = -1
                    animatePress()
                    if (hit.first.alternatives.isNotEmpty() || hit.first.kind == Kind.CHARACTER) {
                        handler.postDelayed(longPressTask, 300L)
                    }
                    if (hit.first.kind == Kind.DELETE) {
                        handler.postDelayed(repeatTask, 430L)
                    }
                    if (hit.first.kind != Kind.SUGGESTION && hit.first.kind != Kind.MIC &&
                        hit.first.kind != Kind.SETTINGS
                    ) {
                        pressHaptic()
                    }
                    invalidate()
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    val key = pressed ?: return true
                    if (key.kind == Kind.DELETE) {
                        val movedLeft = downX - event.x
                        if (!deleteSwipeActive && movedLeft > 14f * density) {
                            startDeleteSwipe()
                        }
                        if (deleteSwipeActive) {
                            updateDeleteSwipe(event.x)
                            return true
                        }
                    }
                    if (longPress && popupMode == PopupMode.CHOICES && !popupRect.isEmpty) {
                        val tileW = 46f * density
                        val index = ((event.x - popupRect.left - 4f * density) / tileW).toInt()
                        val bounded = index.coerceIn(0, key.alternatives.size - 1)
                        if (bounded != popupIndex) {
                            popupIndex = bounded
                            invalidate()
                        }
                    }
                    if (!longPress && !pressCancelled && abs(event.y - downY) > 2.4f * (pressedRect?.height() ?: 0f)) {
                        pressCancelled = true
                        handler.removeCallbacks(longPressTask)
                        handler.removeCallbacks(repeatTask)
                        hidePopup()
                        releasePress()
                        invalidate()
                    }
                    return true
                }
                MotionEvent.ACTION_UP -> {
                    handler.removeCallbacks(longPressTask)
                    handler.removeCallbacks(repeatTask)
                    val key = pressed
                    if (key != null && !pressCancelled) {
                        if (deleteSwipeActive) {
                            finishDeleteSwipe()
                        } else if (longPress) {
                            if (popupMode == PopupMode.CHOICES) {
                                val choices = key.alternatives.ifEmpty { listOf(key.output) }
                                type(choices[popupIndex.coerceIn(choices.indices)])
                            } else if (popupMode == PopupMode.PREVIEW) {
                                activate(key)
                            }
                        } else if (key.kind != Kind.DELETE || (event.eventTime - downTime) < 430L || !deleteRepeated) {
                            activate(key)
                        }
                    }
                    hidePopup()
                    releasePress()
                    invalidate()
                    return true
                }
                MotionEvent.ACTION_CANCEL -> {
                    handler.removeCallbacks(longPressTask)
                    handler.removeCallbacks(repeatTask)
                    if (deleteSwipeActive) cancelDeleteSwipe()
                    hidePopup()
                    releasePress()
                    invalidate()
                    return true
                }
            }
            return true
        }

        private fun startDeleteSwipe() {
            val connection = inputConnection() ?: return
            handler.removeCallbacks(repeatTask)
            handler.removeCallbacks(longPressTask)
            hidePopup()
            deleteSwipeActive = true
            deleteSelectedCount = 0
            deleteLastStep = -1
            deleteTextBefore = ""
            deleteBoundaries = emptyList()
            deleteCursor = -1
            deleteExtracted = false

            val request = ExtractedTextRequest().apply {
                hintMaxChars = 1000
            }
            val extracted = runCatching { connection.getExtractedText(request, 0) }.getOrNull()
            val fullText = extracted?.text?.toString()
            if (extracted != null && fullText != null) {
                val base = extracted.startOffset
                val absoluteCursor = extracted.selectionEnd
                val localCursor = if (absoluteCursor < 0) {
                    fullText.length
                } else {
                    (absoluteCursor - base).coerceIn(0, fullText.length)
                }
                val start = max(0, localCursor - 420)
                deleteTextBefore = fullText.substring(start, localCursor)
                deleteCursor = base + localCursor
                deleteExtracted = true
            } else {
                deleteTextBefore = connection.getTextBeforeCursor(420, 0)?.toString().orEmpty()
            }

            val starts = mutableListOf<Int>()
            for (match in Regex("\\S+").findAll(deleteTextBefore)) {
                starts.add(match.range.first)
            }
            if (starts.isEmpty() && deleteTextBefore.isNotEmpty()) starts.add(0)
            deleteBoundaries = starts
            invalidate()
        }

        private fun updateDeleteSwipe(x: Float) {
            val step = ((downX - x) / (19f * density)).toInt().coerceAtLeast(0)
            if (step == deleteLastStep) return
            deleteLastStep = step

            if (step == 0 || deleteBoundaries.isEmpty()) {
                if (deleteExtracted && deleteCursor >= 0) {
                    inputConnection()?.setSelection(deleteCursor, deleteCursor)
                }
                deleteSelectedCount = 0
                invalidate()
                return
            }

            val index = (deleteBoundaries.size - step).coerceAtLeast(0)
            val start = deleteBoundaries[index]
            val count = (deleteTextBefore.length - start).coerceAtLeast(0)
            deleteSelectedCount = count
            if (deleteExtracted && deleteCursor >= 0 && count > 0) {
                inputConnection()?.setSelection(deleteCursor - count, deleteCursor)
            }
            if (count > 0) pressHaptic()
            invalidate()
        }

        private fun finishDeleteSwipe() {
            val connection = inputConnection()
            val count = deleteSelectedCount
            if (deleteExtracted && deleteCursor >= 0) {
                if (count > 0) {
                    connection?.commitText("", 1)
                } else {
                    connection?.setSelection(deleteCursor, deleteCursor)
                }
            } else if (count > 0) {
                connection?.deleteSurroundingText(count, 0)
            }
            if (count == 0) {
                backspace()
            } else {
                keyboard?.invalidateSuggestions()
            }
            deleteSwipeActive = false
            deleteSelectedCount = 0
            deleteLastStep = -1
            deleteTextBefore = ""
            deleteBoundaries = emptyList()
            deleteCursor = -1
            invalidate()
        }

        private fun cancelDeleteSwipe() {
            if (deleteExtracted && deleteCursor >= 0) {
                inputConnection()?.setSelection(deleteCursor, deleteCursor)
            }
            deleteSwipeActive = false
            deleteSelectedCount = 0
            deleteLastStep = -1
            deleteTextBefore = ""
            deleteBoundaries = emptyList()
            deleteCursor = -1
            invalidate()
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

        private fun computeSuggestions(): List<String> {
            if (passwordInput) return emptyList()
            val before = inputConnection()?.getTextBeforeCursor(80, 0)?.toString().orEmpty()
            val roman = composingRoman.lowercase()
            val word = Regex("[\\p{L}\\p{M}']+$").find(before)?.value.orEmpty()
            val source = if (mode == Mode.ENGLISH) englishWords else banglaWords
            val prefix = if (mode == Mode.PHONETIC) roman else word.lowercase()
            if (prefix.isEmpty()) {
                return if (mode == Mode.ENGLISH) listOf("I", "you", "the") else listOf("আমি", "তুমি", "বাংলা")
            }
            val matches = if (mode == Mode.PHONETIC) {
                phoneticWords.entries.filter { it.key.startsWith(prefix) }.map { it.value }
            } else {
                source.filter { it.lowercase().startsWith(prefix) }
            }
            val converted = if (mode == Mode.PHONETIC) Phonetic.convert(roman) else word
            return (matches + converted).distinct().filter { it.isNotBlank() }.take(3)
        }

        private fun mix(from: Int, to: Int, amount: Float): Int {
            val t = amount.coerceIn(0f, 1f)
            return Color.argb(
                (Color.alpha(from) + (Color.alpha(to) - Color.alpha(from)) * t).toInt(),
                (Color.red(from) + (Color.red(to) - Color.red(from)) * t).toInt(),
                (Color.green(from) + (Color.green(to) - Color.green(from)) * t).toInt(),
                (Color.blue(from) + (Color.blue(to) - Color.blue(from)) * t).toInt(),
            )
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
            var index = 0
            val ordered = tokens.keys.sortedByDescending { it.length }
            var previousWasConsonant = false
            while (index < input.length) {
                val token = ordered.firstOrNull { input.startsWith(it, index, ignoreCase = true) }
                if (token == null) {
                    result.append(input[index])
                    previousWasConsonant = false
                    index++
                } else {
                    val value = tokens.getValue(token)
                    val atEnd = index + token.length >= input.length
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
                    index += token.length
                }
            }
            return result.toString()
        }
    }

    companion object {
        private val phoneticWords = Phonetic.words
        private val banglaWords = listOf(
            "আমি", "আমার", "আমরা", "আপনি", "আপনার", "আছে", "আছি", "আছেন", "আজ", "আসসালামু আলাইকুম",
            "ইনশাআল্লাহ", "একটি", "কথা", "করতে", "করেন", "করছি", "করছেন", "কেমন", "কিভাবে", "কীভাবে",
            "খুব", "খাবার", "গান", "চাই", "ছোট", "জানি", "তুমি", "তোমার", "দেখুন", "ধন্যবাদ", "নতুন",
            "না", "অনেক", "পারি", "পানি", "বাংলা", "বাংলাদেশ", "ভাই", "ভালো", "ভালোবাসা", "ভালোবাসি",
            "মা", "মানুষ", "যাব", "যাচ্ছি", "যেমন", "রয়েছে", "লিখুন", "শুভ সকাল", "সুন্দর", "হ্যাঁ",
            "আমাকে", "তোমাকে", "আপনাকে", "এখানে", "সেখানে", "এখন", "কবে", "কত", "কারণ", "যদি",
            "তাহলে", "কিন্তু", "আবার", "পরে", "আগে", "সব", "সবাই", "হয়েছে", "বলেন", "বলুন",
            "দেখি", "দেখো", "দেখেন", "আসব", "পারব", "দরকার", "সময়", "আজকে", "কালকে", "খুশি",
            "মজা", "দারুণ", "ঠিক", "বুঝি", "বুঝতে", "বুঝলাম", "নাম", "দেশ", "প্রিয়", "পরিবার",
            "ছেলে", "মেয়ে", "শুরু", "শেষ", "প্রতিদিন", "ফোন", "মেসেজ", "কীবোর্ড", "বন্ধু", "শুভ রাত্রি",
        )
        private val englishWords = listOf(
            "I", "you", "the", "and", "is", "it", "we", "this", "that", "hello", "thanks", "please", "love", "good", "great", "Bangla",
        )
    }
}

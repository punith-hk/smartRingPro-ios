package com.smartringpro.mannaheal.ui.fragments

import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.smartringpro.mannaheal.R

class CardiovascularStatusFragment : Fragment() {

    private val TAG = "CardiovascularStatusFragment"

    private var vitalType: String = "ALL"
    private var heartRate = 0
    private var heartRateStatus = "--"
    private var previousHeartRate = 0
    private var bloodPressureSystolic = 0
    private var bloodPressureDiastolic = 0
    private var bloodPressureStatus = "--"
    private var previousBloodPressureSystolic = 0
    private var previousBloodPressureDiastolic = 0
    private var hrv = 0
    private var hrvStatus = "--"
    private var previousHrv = 0
    private var ecgValue = 0
    private var ecgStatus = "--"
    private var previousEcgScore = 0
    private var spo2 = 0
    private var spo2Status = "--"
    private var previousSpo2 = 0
    private var lastSyncBatchTimeMillis: Long = 0L

    // Categories
    enum class VitalCategory { OPTIMAL, CAUTION, CRITICAL }

    data class VitalData(
        val label: String,
        val value: String,
        val unit: String,         // shown below value (e.g. "BPM", "%")
        val subLabel: String = "", // extra info below unit (e.g. ECG status text)
        val previousValue: Int = 0,
        val currentValueInt: Int = 0,
        val hasTwoArrows: Boolean = false,
        val previousValueLeft: Int = 0,
        val previousValueRight: Int = 0,
        val currentValueLeft: Int = 0,
        val currentValueRight: Int = 0,
        val category: VitalCategory
    )

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_cardiovascular_status, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        view.setBackgroundColor(Color.parseColor("#D9EDFF"))

        arguments?.let { vitalType = it.getString("vitalType", "ALL") }

        updateCardiovascularSubtitle()
        setupCardiovascularCardClick()
        loadCardiovascularData()
        view.post { setupScrollHints() }
    }

    private fun loadCardiovascularData() {
        arguments?.let {
            heartRate = it.getInt("heartRate", 0)
            heartRateStatus = it.getString("heartRateStatus", "--") ?: "--"
            previousHeartRate = it.getInt("previousHeartRate", 0)
            bloodPressureSystolic = it.getInt("bloodPressureSystolic", 0)
            bloodPressureDiastolic = it.getInt("bloodPressureDiastolic", 0)
            bloodPressureStatus = it.getString("bloodPressureStatus", "--") ?: "--"
            previousBloodPressureSystolic = it.getInt("previousBloodPressureSystolic", 0)
            previousBloodPressureDiastolic = it.getInt("previousBloodPressureDiastolic", 0)
            hrv = it.getInt("hrv", 0)
            hrvStatus = it.getString("hrvStatus", "--") ?: "--"
            previousHrv = it.getInt("previousHrv", 0)
            ecgValue = it.getInt("ecgValue", 0)
            ecgStatus = it.getString("ecgStatus", "--") ?: "--"
            previousEcgScore = it.getInt("previousEcgScore", 0)
            spo2 = it.getInt("spo2", 0)
            spo2Status = it.getString("spo2Status", "--") ?: "--"
            previousSpo2 = it.getInt("previousSpo2", 0)
            lastSyncBatchTimeMillis = it.getLong("lastSyncBatchTimeMillis", 0L)
        }

        updateLastSynced()
        buildAndRenderVitals()
    }

    /** Classify a status string into Optimal / Caution / Critical */
    private fun classify(status: String): VitalCategory {
        val s = status.lowercase()
        return when {
            s.contains("optimal") || s.contains("normal") || s.contains("good") ||
            s.contains("excellent") || s.contains("healthy") || s.contains("target met") -> VitalCategory.OPTIMAL

            s.contains("elevated") || s.contains("fair") || s.contains("moderate") ||
            s.contains("almost") || s.contains("halfway") || s.contains("light") ||
            s.contains("keep going") || s.contains("just started") || s.contains("active") -> VitalCategory.CAUTION

            else -> VitalCategory.CRITICAL
        }
    }

    private fun buildAndRenderVitals() {
        // Build VitalData for each of the 5 vitals
        val hrVital = VitalData(
            label = "HR", value = if (heartRate > 0) heartRate.toString() else "--",
            unit = "BPM", previousValue = previousHeartRate, currentValueInt = heartRate,
            category = classify(heartRateStatus)
        )
        val bpVital = VitalData(
            label = "BP",
            value = if (bloodPressureSystolic > 0) "$bloodPressureSystolic/$bloodPressureDiastolic" else "--/--",
            unit = "mmHg", hasTwoArrows = true,
            previousValueLeft = previousBloodPressureSystolic, currentValueLeft = bloodPressureSystolic,
            previousValueRight = previousBloodPressureDiastolic, currentValueRight = bloodPressureDiastolic,
            category = classify(bloodPressureStatus)
        )
        val hrvVital = VitalData(
            label = "HRV", value = if (hrv > 0) hrv.toString() else "--",
            unit = "ms", previousValue = previousHrv, currentValueInt = hrv,
            category = classify(hrvStatus)
        )
        val ecgVital = VitalData(
            label = "ECG", value = if (ecgValue > 0) ecgValue.toString() else "--",
            unit = "tores", subLabel = ecgStatus,
            previousValue = previousEcgScore, currentValueInt = ecgValue,
            category = classify(ecgStatus)
        )
        val spo2Vital = VitalData(
            label = "SpO2", value = if (spo2 > 0) spo2.toString() else "--",
            unit = "%", previousValue = previousSpo2, currentValueInt = spo2,
            category = classify(spo2Status)
        )

        val allVitals = listOf(hrVital, bpVital, hrvVital, ecgVital, spo2Vital)
        val optimal = allVitals.filter { it.category == VitalCategory.OPTIMAL }
        val caution = allVitals.filter { it.category == VitalCategory.CAUTION }
        val critical = allVitals.filter { it.category == VitalCategory.CRITICAL }

        val optimalContainer = view?.findViewById<LinearLayout>(R.id.optimal_vitals_container)
        val cautionContainer = view?.findViewById<LinearLayout>(R.id.caution_vitals_container)
        val criticalContainer = view?.findViewById<LinearLayout>(R.id.critical_vitals_container)

        optimalContainer?.removeAllViews()
        cautionContainer?.removeAllViews()
        criticalContainer?.removeAllViews()

        if (optimal.isEmpty()) {
            optimalContainer?.addView(buildEmptyMessage("⚠ No vitals in\noptimal range", "#999999"))
        } else {
            optimal.forEachIndexed { i, v ->
                optimalContainer?.addView(buildVitalView(v))
                if (i < optimal.size - 1) optimalContainer?.addView(buildDivider())
            }
        }

        if (caution.isEmpty()) {
            cautionContainer?.addView(buildEmptyMessage("✓ No caution\nalerts", "#4CAF50"))
        } else {
            caution.forEachIndexed { i, v ->
                cautionContainer?.addView(buildVitalView(v))
                if (i < caution.size - 1) cautionContainer?.addView(buildDivider())
            }
        }

        if (critical.isEmpty()) {
            criticalContainer?.addView(buildEmptyMessage("✓ No critical\nalerts", "#4CAF50"))
        } else {
            critical.forEachIndexed { i, v ->
                criticalContainer?.addView(buildVitalView(v))
                if (i < critical.size - 1) criticalContainer?.addView(buildDivider())
            }
        }
    }

    private fun buildEmptyMessage(msg: String, colorHex: String): TextView {
        return TextView(requireContext()).apply {
            text = msg
            setTextColor(Color.parseColor(colorHex))
            textSize = 11f
            setTypeface(typeface, Typeface.BOLD)
            gravity = Gravity.CENTER
            textAlignment = TextView.TEXT_ALIGNMENT_CENTER
            setPadding(8.dp, 12.dp, 8.dp, 12.dp)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
    }

    private fun buildDivider(): View {
        return View(requireContext()).apply {
            setBackgroundColor(Color.parseColor("#E0E0E0"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 1.dp
            ).apply { setMargins(8.dp, 0, 8.dp, 12.dp) }
        }
    }

    private fun buildVitalView(vital: VitalData): LinearLayout {
        val container = LinearLayout(requireContext()).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = 8.dp }
        }

        // Label
        container.addView(TextView(requireContext()).apply {
            text = vital.label
            setTextColor(Color.BLACK)
            textSize = 12f
            setTypeface(typeface, Typeface.BOLD)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 4.dp }
        })

        // Value row with arrow(s)
        val valueRow = LinearLayout(requireContext()).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL or Gravity.CENTER_HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 2.dp }
        }

        if (vital.hasTwoArrows) {
            // Left arrow (systolic)
            valueRow.addView(buildArrow(vital.currentValueLeft, vital.previousValueLeft))
            // BP value text
            valueRow.addView(TextView(requireContext()).apply {
                text = vital.value
                setTextColor(Color.BLACK)
                textSize = 18f
                setTypeface(typeface, Typeface.BOLD)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { marginStart = 2.dp; marginEnd = 2.dp }
            })
            // Right arrow (diastolic)
            valueRow.addView(buildArrow(vital.currentValueRight, vital.previousValueRight))
        } else {
            // Invisible left placeholder to balance the right arrow → keeps value centered
            valueRow.addView(ImageView(requireContext()).apply {
                layoutParams = LinearLayout.LayoutParams(12.dp, 12.dp).apply { marginEnd = 4.dp }
                visibility = View.INVISIBLE
            })
            // Value text
            valueRow.addView(TextView(requireContext()).apply {
                text = vital.value
                setTextColor(Color.BLACK)
                textSize = 20f
                setTypeface(typeface, Typeface.BOLD)
            })
            // Single trend arrow
            valueRow.addView(buildArrow(vital.currentValueInt, vital.previousValue).apply {
                (layoutParams as LinearLayout.LayoutParams).marginStart = 4.dp
            })
        }

        container.addView(valueRow)

        // Unit text
        container.addView(TextView(requireContext()).apply {
            text = vital.unit
            setTextColor(Color.parseColor("#999999"))
            textSize = 10f
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = if (vital.subLabel.isNotEmpty()) 2.dp else 8.dp
            }
        })

        // Sub-label (e.g. ECG status text like "Normal ECG")
        if (vital.subLabel.isNotEmpty() && vital.subLabel != "--") {
            container.addView(TextView(requireContext()).apply {
                text = vital.subLabel
                setTextColor(Color.parseColor("#666666"))
                textSize = 9f
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { bottomMargin = 8.dp; marginStart = 4.dp; marginEnd = 4.dp }
            })
        }

        return container
    }

    private fun buildArrow(current: Int, previous: Int): ImageView {
        val isUp = previous == 0 || current >= previous
        val color = if (isUp) Color.parseColor("#4CAF50") else Color.parseColor("#F44336")
        val icon = if (isUp) R.drawable.baseline_arrow_upward_24 else R.drawable.baseline_arrow_downward_24
        return ImageView(requireContext()).apply {
            setImageResource(icon)
            setColorFilter(color)
            layoutParams = LinearLayout.LayoutParams(12.dp, 12.dp)
        }
    }

    private val Int.dp: Int get() = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, this.toFloat(), resources.displayMetrics
    ).toInt()

    // ---- unchanged helpers below ----

    private fun setupCardiovascularCardClick() {
        view?.findViewById<View>(R.id.cardiovascular_summary_card)?.setOnClickListener {
            navigateBasedOnVitalType()
        }
    }

    private fun navigateBasedOnVitalType() {
        val activity = requireActivity() as? com.smartringpro.mannaheal.ui.activities.HomeActivity
        when (vitalType) {
            "HEART_RATE" -> activity?.openHealthDataFragment("heart_rate", "Heart Rate")
            "HRV"        -> activity?.openHealthDataFragment("hrv", "Heart Rate Variability")
            "ECG"        -> activity?.openFragment(EcgFragment(), "ECG", true)
            "BLOOD_PRESSURE" -> activity?.openHealthDataFragment("blood_pressure", "Blood Pressure")
            "BLOOD_OXYGEN"   -> activity?.openHealthDataFragment("blood_oxygen", "Blood Oxygen")
            else -> android.widget.Toast.makeText(requireContext(), "Please select a specific vital from dashboard", android.widget.Toast.LENGTH_SHORT).show()
        }
    }

    private fun setupScrollHints() {
        val v = view ?: return
        listOf(
            Triple(R.id.optimal_scroll_view, R.id.optimal_scroll_hint, "optimal"),
            Triple(R.id.caution_scroll_view, R.id.caution_scroll_hint, "caution"),
            Triple(R.id.critical_scroll_view, R.id.critical_scroll_hint, "critical")
        ).forEach { (scrollId, hintId, _) ->
            val scrollView = v.findViewById<android.widget.ScrollView>(scrollId) ?: return@forEach
            val hint = v.findViewById<View>(hintId) ?: return@forEach
            val child = scrollView.getChildAt(0)
            if (child != null && child.height > scrollView.height) hint.visibility = View.VISIBLE
            scrollView.setOnScrollChangeListener { _, _, scrollY, _, _ ->
                val maxScroll = scrollView.getChildAt(0).height - scrollView.height
                hint.visibility = if (scrollY >= maxScroll - 4) View.GONE else View.VISIBLE
            }
        }
    }

    private fun updateCardiovascularSubtitle() {
        view?.findViewById<TextView>(R.id.cardiovascular_subtitle)?.text = when (vitalType) {
            "HEART_RATE"     -> "Heart Rate Details"
            "HRV"            -> "HRV Details"
            "ECG"            -> "ECG Details"
            "BLOOD_PRESSURE" -> "Blood Pressure Details"
            "BLOOD_OXYGEN"   -> "Blood Oxygen (SpO2) Details"
            else             -> "HR, HRV, ECG, BP, SpO2"
        }
    }

    private fun updateLastSynced() {
        val tvLastSynced = view?.findViewById<TextView>(R.id.tvLastSynced) ?: return
        val ivStatus = view?.findViewById<ImageView>(R.id.ivSyncStatus) ?: return
        if (lastSyncBatchTimeMillis <= 0L) {
            tvLastSynced.text = "Last synced: No data yet"
            ivStatus.imageTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#AAAAAA"))
            return
        }
        val diffMillis  = System.currentTimeMillis() - lastSyncBatchTimeMillis
        val diffMinutes = diffMillis / 60_000
        val diffHours   = diffMillis / 3_600_000
        val diffDays    = diffMillis / 86_400_000
        val relativeText = when {
            diffMinutes < 1  -> "just now"
            diffMinutes < 60 -> "$diffMinutes min ago"
            diffHours < 24   -> "$diffHours hr${if (diffHours > 1) "s" else ""} ago"
            else             -> "$diffDays day${if (diffDays > 1) "s" else ""} ago"
        }
        tvLastSynced.text = "Last data synced: $relativeText"
        val dotColor = when {
            diffHours < 2  -> "#4CAF50"
            diffHours < 12 -> "#FFA726"
            else           -> "#F44336"
        }
        ivStatus.imageTintList = android.content.res.ColorStateList.valueOf(Color.parseColor(dotColor))
    }

    companion object {
        fun newInstance(
            vitalType: String = "ALL",
            heartRate: Int = 0,
            heartRateStatus: String = "--",
            previousHeartRate: Int = 0,
            hrv: Int = 0,
            hrvStatus: String = "--",
            previousHrv: Int = 0,
            bloodPressureSystolic: Int = 0,
            bloodPressureDiastolic: Int = 0,
            bloodPressureStatus: String = "--",
            previousBloodPressureSystolic: Int = 0,
            previousBloodPressureDiastolic: Int = 0,
            spo2: Int = 0,
            spo2Status: String = "--",
            previousSpo2: Int = 0,
            ecgValue: Int = 0,
            ecgStatus: String = "--",
            previousEcgScore: Int = 0,
            lastSyncBatchTimeMillis: Long = 0L
        ): CardiovascularStatusFragment {
            val fragment = CardiovascularStatusFragment()
            fragment.arguments = Bundle().apply {
                putString("vitalType", vitalType)
                putLong("lastSyncBatchTimeMillis", lastSyncBatchTimeMillis)
                putInt("heartRate", heartRate);       putString("heartRateStatus", heartRateStatus)
                putInt("previousHeartRate", previousHeartRate)
                putInt("hrv", hrv);                   putString("hrvStatus", hrvStatus)
                putInt("previousHrv", previousHrv)
                putInt("bloodPressureSystolic", bloodPressureSystolic)
                putInt("bloodPressureDiastolic", bloodPressureDiastolic)
                putString("bloodPressureStatus", bloodPressureStatus)
                putInt("previousBloodPressureSystolic", previousBloodPressureSystolic)
                putInt("previousBloodPressureDiastolic", previousBloodPressureDiastolic)
                putInt("spo2", spo2);                 putString("spo2Status", spo2Status)
                putInt("previousSpo2", previousSpo2)
                putInt("ecgValue", ecgValue);         putString("ecgStatus", ecgStatus)
                putInt("previousEcgScore", previousEcgScore)
            }
            return fragment
        }
    }
}

